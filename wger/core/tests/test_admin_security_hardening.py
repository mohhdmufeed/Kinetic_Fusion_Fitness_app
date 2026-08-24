# -*- coding: utf-8 -*-
from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.core.models.admin import AdminProfile, AdminAuditLog


class AdminSecurityHardeningTestCase(TestCase):
    """
    Test suite for Module 2: Admin Security & Hardening:
    1. A normal user token (even if is_staff=True) CANNOT call /api/v2/admin/** without admin-scoped JWT.
    2. Admin token with 'scope': 'admin_jwt' succeeds on /api/v2/admin/**.
    3. Every admin action generates an immutable AdminAuditLog entry.
    4. Admin can soft-deactivate a user with audit tracking.
    """

    def setUp(self):
        self.client = APIClient()

        # Regular Athlete User (is_staff=False)
        self.athlete_user = User.objects.create_user(
            username='regular_athlete',
            email='athlete@kineticprecision.app',
            password='Password123#',
        )
        athlete_jwt = AccessToken.for_user(self.athlete_user)
        self.athlete_token = str(athlete_jwt)

        # Staff User without AdminProfile or 2FA admin-scoped token
        self.rogue_staff_user = User.objects.create_user(
            username='rogue_staff',
            email='rogue@kineticprecision.app',
            password='Password123#',
            is_staff=True,
        )
        rogue_jwt = AccessToken.for_user(self.rogue_staff_user)  # Standard token, scope != admin_jwt
        self.rogue_token = str(rogue_jwt)

        # Authorized Super Admin with AdminProfile and 2FA admin-scoped token
        self.super_admin_user = User.objects.create_superuser(
            username='gym_owner_boss',
            email='owner@kineticprecision.app',
            password='OwnerSuperPassword123#',
        )
        AdminProfile.objects.create(
            user=self.super_admin_user,
            is_active=True,
            can_access_admin=True,
        )
        admin_jwt = AccessToken.for_user(self.super_admin_user)
        admin_jwt['scope'] = 'admin_jwt'
        self.admin_token = str(admin_jwt)

    def test_regular_athlete_token_rejected_on_admin_routes(self):
        """Athlete token is rejected with 403 on /api/v2/admin/clients/."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.athlete_token}')
        resp = self.client.get('/api/v2/admin/clients/')
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_rogue_staff_without_admin_jwt_scope_rejected(self):
        """Staff user with standard token (no 2FA admin_jwt scope) is rejected with 403."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.rogue_token}')
        resp = self.client.get('/api/v2/admin/clients/')
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_authorized_admin_token_succeeds_and_creates_audit_log(self):
        """Super Admin with verified 2FA admin_jwt scope succeeds and actions are logged."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.admin_token}')
        resp = self.client.get('/api/v2/admin/clients/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

        # Perform soft-deactivation of athlete account
        deactivate_resp = self.client.delete(f'/api/v2/admin/clients/{self.athlete_user.id}/')
        self.assertEqual(deactivate_resp.status_code, status.HTTP_200_OK)

        # Verify athlete is deactivated
        self.athlete_user.refresh_from_db()
        self.assertFalse(self.athlete_user.is_active)

        # Verify AdminAuditLog record created
        log_entry = AdminAuditLog.objects.filter(
            actor=self.super_admin_user,
            action_type='deactivate',
            target_id=str(self.athlete_user.id),
        ).first()
        self.assertIsNotNone(log_entry)
        self.assertEqual(log_entry.details.get('username'), 'regular_athlete')
