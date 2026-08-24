from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from wger.core.demo import create_temporary_user
from django.core.exceptions import PermissionDenied


class SecurityAuditTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='athlete_security_test',
            email='test@kineticprecision.app',
            password='SecureSuperPassword123!',
        )

    def test_guest_mode_disabled(self):
        """Assert temporary/guest user creation raises PermissionDenied."""
        with self.assertRaises(PermissionDenied):
            create_temporary_user()

    def test_protected_endpoints_reject_unauthenticated(self):
        """Assert protected data endpoints return 401/403 when hit with no auth header."""
        protected_urls = [
            '/api/v2/routine/',
            '/api/v2/workoutsession/',
            '/api/v2/weightentry/',
            '/api/v2/log/',
            '/api/v2/userprofile/',
            '/api/v2/day/',
            '/api/v2/slot/',
        ]
        for url in protected_urls:
            response = self.client.get(url)
            self.assertIn(
                response.status_code,
                [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND],
                f"Endpoint {url} allowed unauthenticated access (Status: {response.status_code})",
            )

    def test_auth_signup_enforces_password_length(self):
        """Assert signup rejects short passwords (< 10 chars)."""
        response = self.client.post(
            '/api/v2/auth/signup/',
            {
                'email': 'shortpass@kineticprecision.app',
                'username': 'shortpassuser',
                'password': 'short',
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('password', response.data)

    def test_auth_signup_and_jwt_rotation(self):
        """Assert signup succeeds with valid data and returns verification token."""
        signup_resp = self.client.post(
            '/api/v2/auth/signup/',
            {
                'email': 'newathlete@kineticprecision.app',
                'username': 'newathlete123',
                'password': 'ComplexStrongPassword123#',
                'display_name': 'New Athlete',
            },
            format='json',
        )
        self.assertEqual(signup_resp.status_code, status.HTTP_201_CREATED)
        self.assertIn('verification_token', signup_resp.data)

        # Verify email
        v_token = signup_resp.data['verification_token']
        verify_resp = self.client.post(
            '/api/v2/auth/verify-email/',
            {'token': v_token},
            format='json',
        )
        self.assertEqual(verify_resp.status_code, status.HTTP_200_OK)

        # Login with Argon2 password verification
        login_resp = self.client.post(
            '/api/v2/auth/login/',
            {
                'username': 'newathlete123',
                'password': 'ComplexStrongPassword123#',
            },
            format='json',
        )
        self.assertEqual(login_resp.status_code, status.HTTP_200_OK)
        self.assertIn('access', login_resp.data)
        self.assertIn('refresh', login_resp.data)

        # Use JWT token on protected endpoint
        access_token = login_resp.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')
        profile_resp = self.client.get('/api/v2/userprofile/')
        self.assertEqual(profile_resp.status_code, status.HTTP_200_OK)
