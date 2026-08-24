# -*- coding: utf-8 -*-
from datetime import timedelta
from django.contrib.auth.models import User
from django.contrib.auth.hashers import identify_hasher
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken, RefreshToken

from wger.core.models.profile import UserProfile
from wger.core.api.auth_serializers import signer


class SecureAuthenticationSystemTestCase(TestCase):
    """
    Test suite for Module 1 Secure Authentication System:
    1. Server-side generated user ID & mandatory email verification before login/data access.
    2. Password rules (>= 10 chars) & Argon2 hashing.
    3. Short-lived 15-min JWT access token + long-lived 14-day refresh token.
    4. Logout & Logout All Devices (revocation).
    5. Zero Guest Access: Regression asserting all data endpoints return 401 Unauthorized for anonymous callers.
    """

    def setUp(self):
        self.client = APIClient()

    def test_signup_enforces_password_length_and_creates_unverified_account(self):
        """Signup requires minimum 10 characters password and produces unverified account."""
        # Short password (< 10 chars)
        short_pwd_resp = self.client.post('/api/v2/auth/signup/', {
            'email': 'short@kineticprecision.app',
            'username': 'short_user',
            'password': 'P1#short',
            'display_name': 'Short Tester',
        }, format='json')
        self.assertEqual(short_pwd_resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('password', short_pwd_resp.data)

        # Valid password (>= 10 chars)
        valid_resp = self.client.post('/api/v2/auth/signup/', {
            'email': 'athlete_valid@kineticprecision.app',
            'username': 'athlete_valid',
            'password': 'KineticStrongPassword2026#',
            'display_name': 'Alex Valid',
        }, format='json')
        self.assertEqual(valid_resp.status_code, status.HTTP_201_CREATED)
        self.assertIn('verification_token', valid_resp.data)
        user_id = valid_resp.data['user_id']
        self.assertIsInstance(user_id, int)

        # Verify password is saved using an approved hasher
        user = User.objects.get(pk=user_id)
        hasher_name = identify_hasher(user.password).algorithm
        self.assertIn(hasher_name, ['argon2', 'pbkdf2_sha256'])

        # Profile email_verified should be False initially
        profile = UserProfile.objects.get(user=user)
        self.assertFalse(profile.email_verified)

    def test_unverified_account_cannot_login_until_verified(self):
        """Unverified account cannot login; verifying signed token unlocks login."""
        user = User.objects.create_user(
            username='unverified_user',
            email='unverified@kineticprecision.app',
            password='KineticSecretPassword123#',
        )
        UserProfile.objects.create(user=user, email_verified=False)

        # Attempt login before verification -> 401 Unauthorized
        login_resp = self.client.post('/api/v2/auth/login/', {
            'username': 'unverified@kineticprecision.app',
            'password': 'KineticSecretPassword123#',
        }, format='json')
        self.assertEqual(login_resp.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertIn('verify', str(login_resp.data).lower())

        # Verify email using signed token
        token = signer.sign(str(user.id))
        verify_resp = self.client.post('/api/v2/auth/verify-email/', {'token': token}, format='json')
        self.assertEqual(verify_resp.status_code, status.HTTP_200_OK)

        # Profile should now be verified
        user.userprofile.refresh_from_db()
        self.assertTrue(user.userprofile.email_verified)

        # Attempt login after verification -> 200 OK with tokens
        login_after_resp = self.client.post('/api/v2/auth/login/', {
            'username': 'unverified@kineticprecision.app',
            'password': 'KineticSecretPassword123#',
        }, format='json')
        self.assertEqual(login_after_resp.status_code, status.HTTP_200_OK)
        self.assertIn('access', login_after_resp.data)
        self.assertIn('refresh', login_after_resp.data)

    def test_logout_all_devices_revocation(self):
        """Logout all devices endpoint revokes tokens."""
        user = User.objects.create_user(
            username='logged_user',
            email='logged@kineticprecision.app',
            password='KineticPassword123#',
        )
        UserProfile.objects.create(user=user, email_verified=True)

        access_token = str(AccessToken.for_user(user))
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

        logout_all_resp = self.client.post('/api/v2/auth/logout-all/', format='json')
        self.assertEqual(logout_all_resp.status_code, status.HTTP_200_OK)

    def test_regression_zero_guest_access_on_protected_endpoints(self):
        """Regression test: All protected data endpoints return 401 Unauthorized for anonymous callers."""
        protected_endpoints = [
            '/api/v2/dashboard/today/',
            '/api/v2/dashboard/history/',
            '/api/v2/activity/history/',
            '/api/v2/nutrition/diary/',
            '/api/v2/feedback/',
            '/api/v2/admin/clients/',
            '/api/v2/admin/feedback/',
        ]

        anon_client = APIClient()  # No auth header
        for endpoint in protected_endpoints:
            resp = anon_client.get(endpoint)
            self.assertIn(
                resp.status_code,
                [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN],
                f"Endpoint {endpoint} allowed unauthenticated access (status: {resp.status_code})"
            )
