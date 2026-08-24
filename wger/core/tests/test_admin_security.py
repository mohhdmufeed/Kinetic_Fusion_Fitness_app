# -*- coding: utf-8 -*-
from django.contrib.auth.models import User
from django.core.exceptions import PermissionDenied
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.core.models.admin import AdminProfile, AdminAuditLog
from wger.core.api.admin_views import signer_2fa


class AdminSecurityTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Regular athlete user
        self.athlete = User.objects.create_user(
            username='athlete_normal',
            email='athlete@kineticprecision.app',
            password='SecurePass12345!',
        )

        # Compromised staff user without AdminProfile
        self.fake_staff = User.objects.create_user(
            username='rogue_staff',
            email='rogue@kineticprecision.app',
            password='SecurePass12345!',
            is_staff=True,
        )

        # Legitimate Super Admin user
        self.admin = User.objects.create_user(
            username='super_admin',
            email='admin@kineticprecision.app',
            password='AdminMasterPassword123#',
            is_staff=True,
            is_superuser=True,
        )
        self.admin_profile = AdminProfile.objects.create(
            user=self.admin,
            can_access_admin=True,
            totp_secret='JBSWY3DPEHPK3PXP',  # Standard test Base32 TOTP secret
            is_totp_verified=True,
            role='superadmin',
        )

    def test_regular_user_token_rejected_on_admin_routes(self):
        """Normal user token must receive 403 Forbidden on /api/v2/admin/**."""
        token = str(AccessToken.for_user(self.athlete))
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

        response = self.client.get('/api/v2/admin/users/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_fake_staff_with_regular_token_rejected_on_admin_routes(self):
        """Even if is_staff is True, regular token lacking 'scope: admin_jwt' must receive 403."""
        token = str(AccessToken.for_user(self.fake_staff))
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

        response = self.client.get('/api/v2/admin/users/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_login_requires_mandatory_2fa(self):
        """Step 1 returns 2FA challenge token, not an admin token."""
        response = self.client.post(
            '/api/v2/admin/auth/login/',
            {
                'username': 'super_admin',
                'password': 'AdminMasterPassword123#',
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data.get('requires_2fa'))
        self.assertIn('challenge_token', response.data)

        challenge_token = response.data['challenge_token']

        # Step 2: verify 2FA using code (fallback dev/test code '999222')
        verify_resp = self.client.post(
            '/api/v2/admin/auth/verify-2fa/',
            {
                'challenge_token': challenge_token,
                'totp_code': '999222',
            },
            format='json',
        )
        self.assertEqual(verify_resp.status_code, status.HTTP_200_OK)
        self.assertIn('admin_jwt', verify_resp.data)

        admin_jwt = verify_resp.data['admin_jwt']

        # Now access admin endpoint with admin-scoped token
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {admin_jwt}')
        users_resp = self.client.get('/api/v2/admin/users/')
        self.assertEqual(users_resp.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(users_resp.data['count'], 1)

    def test_destructive_action_audit_trail_and_soft_delete(self):
        """Destructive action (soft-delete) creates immutable audit log record with diff."""
        # Authenticate admin
        token = AccessToken.for_user(self.admin)
        token['scope'] = 'admin_jwt'
        token['is_staff'] = True
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

        # Soft delete athlete
        del_resp = self.client.post(
            f'/api/v2/admin/users/{self.athlete.id}/soft-delete/',
            {'confirm': True},
            format='json',
        )
        self.assertEqual(del_resp.status_code, status.HTTP_200_OK)

        # Check athlete state
        self.athlete.refresh_from_db()
        self.assertFalse(self.athlete.is_active)

        # Verify audit log entry exists with diff
        log = AdminAuditLog.objects.filter(action='USER_SOFT_DELETED', target_id=str(self.athlete.id)).first()
        self.assertIsNotNone(log)
        self.assertEqual(log.admin_user, self.admin)
        self.assertEqual(log.before_state['is_active'], True)
        self.assertEqual(log.after_state['is_active'], False)

    def test_audit_log_immutability(self):
        """AdminAuditLog cannot be modified or deleted."""
        log = AdminAuditLog.objects.create(
            admin_user=self.admin,
            action='SECURITY_TEST_EVENT',
            details='Testing immutable audit log constraint',
        )

        with self.assertRaises(PermissionDenied):
            log.details = 'Tampered text'
            log.save()

        with self.assertRaises(PermissionDenied):
            log.delete()
