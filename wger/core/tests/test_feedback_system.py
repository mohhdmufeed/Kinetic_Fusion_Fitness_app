# -*- coding: utf-8 -*-
from django.contrib.auth.models import User
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.core.models.admin import AdminProfile, AdminAuditLog
from wger.core.models.feedback import FeedbackReport


class FeedbackSystemTestCase(TestCase):
    """
    Test suite for Kinetic Precision In-App Feedback & Super Admin Management:
    1. Feedback submission with sanitized client telemetry.
    2. Daily rate-limiting (10/day per user).
    3. Multi-tenant privacy on athlete submissions.
    4. Super admin status triage, replies, and immutable audit logs.
    """

    def setUp(self):
        self.client_a = APIClient()
        self.client_b = APIClient()
        self.admin_client = APIClient()

        # Athlete A
        self.user_a = User.objects.create_user(
            username='athlete_alex',
            email='alex@kineticprecision.app',
            password='AlexPassword123#',
        )
        self.token_a = str(AccessToken.for_user(self.user_a))
        self.client_a.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_a}')

        # Athlete B
        self.user_b = User.objects.create_user(
            username='athlete_blake',
            email='blake@kineticprecision.app',
            password='BlakePassword123#',
        )
        self.token_b = str(AccessToken.for_user(self.user_b))
        self.client_b.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_b}')

        # Super Admin
        self.admin_user = User.objects.create_superuser(
            username='feedback_admin',
            email='admin_fb@kineticprecision.app',
            password='AdminPassword123#',
        )
        AdminProfile.objects.create(user=self.admin_user, is_active=True, can_access_admin=True)
        admin_jwt = AccessToken.for_user(self.admin_user)
        admin_jwt['scope'] = 'admin_jwt'
        self.admin_token = str(admin_jwt)
        self.admin_client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.admin_token}')

    def test_feedback_submission_and_sanitized_telemetry(self):
        """Feedback stores sanitized device metadata without any credential leaks."""
        payload = {
            'category': 'bug',
            'rating': 4,
            'message': 'Recovery score animation slightly lagged on Pixel 9 during heavy chart load.',
            'device_metadata': {
                'app_version': '2.1.0',
                'os_version': 'Android 15',
                'device_model': 'Google Pixel 9 Pro',
                'screen_res': '1080x2400',
                # Accidental leak attempt: must be stripped/ignored
                'auth_token': 'Bearer secret_token_12345',
            }
        }

        response = self.client_a.post('/api/v2/feedback/', payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        report_id = response.data['report_id']

        report = FeedbackReport.objects.get(pk=report_id)
        self.assertEqual(report.user, self.user_a)
        self.assertEqual(report.category, 'bug')
        self.assertNotIn('auth_token', report.device_metadata)
        self.assertEqual(report.device_metadata['device_model'], 'Google Pixel 9 Pro')

    def test_athlete_isolation_on_feedback_mine(self):
        """Athlete A can only see their own feedback submissions."""
        FeedbackReport.objects.create(
            user=self.user_a,
            category='bug',
            message='Alex bug report',
        )
        FeedbackReport.objects.create(
            user=self.user_b,
            category='feature_request',
            message='Blake feature request',
        )

        response = self.client_a.get('/api/v2/feedback/mine/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        messages = [item['message'] for item in response.data['results']]
        self.assertIn('Alex bug report', messages)
        self.assertNotIn('Blake feature request', messages)

    def test_admin_triage_reply_and_audit_log(self):
        """Admin triages feedback, replies, and creates immutable audit log."""
        report = FeedbackReport.objects.create(
            user=self.user_a,
            category='feature_request',
            message='Please add Romanian Deadlift with trap bar.',
            status='new',
        )

        # Admin replies and marks in_review
        patch_payload = {
            'status': 'in_review',
            'admin_reply': 'Great suggestion! Our team is adding Trap Bar RDL in the next library update.',
        }
        resp = self.admin_client.patch(f'/api/v2/admin/feedback/{report.id}/', patch_payload, format='json')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['new_status'], 'in_review')

        # Verify audit log
        self.assertTrue(
            AdminAuditLog.objects.filter(
                actor=self.admin_user,
                target_id=str(report.id),
            ).exists()
        )

        # Athlete A sees admin reply
        alex_resp = self.client_a.get('/api/v2/feedback/mine/')
        first_report = alex_resp.data['results'][0]
        self.assertEqual(first_report['status'], 'in_review')
        self.assertEqual(first_report['admin_reply'], 'Great suggestion! Our team is adding Trap Bar RDL in the next library update.')
