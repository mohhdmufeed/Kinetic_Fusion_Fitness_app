# -*- coding: utf-8 -*-
from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.manager.models import Routine, WorkoutSession
from wger.weight.models import WeightEntry
from wger.core.models import UserProfile
from wger.core.models.admin import AdminProfile, AdminAuditLog


class AccessControlMatrixTestCase(TestCase):
    """
    Automated penetration-test-style Access Control Matrix suite asserting:
    1. Multi-tenant IDOR protection: User A cannot read, modify, or delete User B's records.
    2. Endpoint data sanitization: Client endpoints never return admin-only fields or other users' PII.
    3. Complete admin route isolation: Regular client JWTs are strictly rejected across all /api/v2/admin/** endpoints.
    """

    def setUp(self):
        self.client_a = APIClient()
        self.client_b = APIClient()

        # User A (Athlete A)
        self.user_a = User.objects.create_user(
            username='athlete_alpha',
            email='alpha@kineticprecision.app',
            password='AlphaSecurePassword123#',
        )
        self.token_a = str(AccessToken.for_user(self.user_a))
        self.client_a.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_a}')

        # User B (Athlete B)
        self.user_b = User.objects.create_user(
            username='athlete_bravo',
            email='bravo@kineticprecision.app',
            password='BravoSecurePassword123#',
        )
        self.token_b = str(AccessToken.for_user(self.user_b))
        self.client_b.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_b}')

        # Create private records owned strictly by User A
        self.routine_a = Routine.objects.create(
            user=self.user_a,
            name='Alpha Secret Hypertrophy Routine',
            description='Top secret progression',
            is_public=False,
            is_template=False,
        )

        self.session_a = WorkoutSession.objects.create(
            user=self.user_a,
            routine=self.routine_a,
            notes='Alpha private workout notes',
        )

        self.weight_a = WeightEntry.objects.create(
            user=self.user_a,
            weight=82.5,
        )

    def test_idor_user_b_cannot_get_user_a_routine(self):
        """User B cannot GET User A's private routine via direct ID lookup."""
        response = self.client_b.get(f'/api/v2/routine/{self.routine_a.id}/')
        self.assertIn(
            response.status_code,
            [status.HTTP_404_NOT_FOUND, status.HTTP_403_FORBIDDEN],
            "IDOR vulnerability: User B was able to read User A's routine!",
        )

    def test_idor_user_b_cannot_put_user_a_routine(self):
        """User B cannot PUT/PATCH User A's routine."""
        response = self.client_b.patch(
            f'/api/v2/routine/{self.routine_a.id}/',
            {'name': 'Hacked Routine Name by User B'},
            format='json',
        )
        self.assertIn(
            response.status_code,
            [status.HTTP_404_NOT_FOUND, status.HTTP_403_FORBIDDEN],
            "IDOR vulnerability: User B was able to modify User A's routine!",
        )
        self.routine_a.refresh_from_db()
        self.assertEqual(self.routine_a.name, 'Alpha Secret Hypertrophy Routine')

    def test_idor_user_b_cannot_delete_user_a_routine(self):
        """User B cannot DELETE User A's routine."""
        response = self.client_b.delete(f'/api/v2/routine/{self.routine_a.id}/')
        self.assertIn(
            response.status_code,
            [status.HTTP_404_NOT_FOUND, status.HTTP_403_FORBIDDEN],
            "IDOR vulnerability: User B was able to delete User A's routine!",
        )
        self.assertTrue(Routine.objects.filter(pk=self.routine_a.id).exists())

    def test_idor_user_b_cannot_access_user_a_workout_session(self):
        """User B cannot access User A's workout session."""
        response = self.client_b.get(f'/api/v2/workoutsession/{self.session_a.id}/')
        self.assertIn(
            response.status_code,
            [status.HTTP_404_NOT_FOUND, status.HTTP_403_FORBIDDEN],
            "IDOR vulnerability: User B accessed User A's workout session!",
        )

    def test_idor_user_b_cannot_access_user_a_weight_entry(self):
        """User B cannot access User A's weight entry."""
        response = self.client_b.get(f'/api/v2/weightentry/{self.weight_a.id}/')
        self.assertIn(
            response.status_code,
            [status.HTTP_404_NOT_FOUND, status.HTTP_403_FORBIDDEN],
            "IDOR vulnerability: User B accessed User A's weight entry!",
        )

    def test_client_endpoints_do_not_leak_admin_fields(self):
        """Profile endpoint must only return requesting user's own data with zero admin field leakage."""
        response = self.client_a.get('/api/v2/userprofile/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data_str = str(response.data)
        self.assertNotIn('totp_secret', data_str)
        self.assertNotIn('admin_audit_logs', data_str)
        self.assertNotIn('bravo@kineticprecision.app', data_str)

    def test_client_jwt_rejected_on_all_admin_routes(self):
        """Assert both User A and User B tokens are rejected (403) across all admin routes."""
        admin_routes = [
            '/api/v2/admin/users/',
            '/api/v2/admin/system/health/',
            '/api/v2/admin/analytics/overview/',
            '/api/v2/admin/audit-logs/',
            f'/api/v2/admin/users/{self.user_a.id}/suspend/',
            f'/api/v2/admin/users/{self.user_a.id}/soft-delete/',
        ]

        for route in admin_routes:
            # Test User A
            resp_a = self.client_a.get(route)
            self.assertEqual(
                resp_a.status_code,
                status.HTTP_403_FORBIDDEN,
                f"Client token A was not rejected on admin route {route}!",
            )

            # Test User B
            resp_b = self.client_b.get(route)
            self.assertEqual(
                resp_b.status_code,
                status.HTTP_403_FORBIDDEN,
                f"Client token B was not rejected on admin route {route}!",
            )
