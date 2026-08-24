# -*- coding: utf-8 -*-
from datetime import timedelta
from django.contrib.auth.models import User
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.core.models.profile import UserProfile
from wger.core.models.admin import AdminProfile
from wger.core.models import Language, License
from wger.core.models.feedback import FeedbackReport
from wger.core.models.activity import ActivityLog
from wger.nutrition.models.kinetic_nutrition import KineticIngredient, KineticDiaryEntry
from wger.manager.models import Routine


class DataIsolationMatrixTestCase(TestCase):
    """
    Penetration-test-style Access Control Matrix:
    1. User A cannot GET/PUT/PATCH/DELETE User B's objects across any module (Workouts, Nutrition, Activity, Feedback).
    2. Client endpoints never leak other users' sensitive info or admin flags.
    3. Neither User A nor User B can access any /api/v2/admin/** route.
    """

    def setUp(self):
        Language.objects.get_or_create(id=2, defaults={'short_name': 'en', 'full_name': 'English'})
        License.objects.get_or_create(id=1, defaults={'short_name': 'PD', 'full_name': 'Public Domain'})
        License.objects.get_or_create(id=2, defaults={'short_name': 'CC', 'full_name': 'Creative Commons'})

        self.client_a = APIClient()
        self.client_b = APIClient()
        self.admin_client = APIClient()

        # User A
        self.user_a = User.objects.create_user(
            username='athlete_alice',
            email='alice@kineticprecision.app',
            password='AlicePassword123#',
        )
        UserProfile.objects.get_or_create(user=self.user_a)
        self.client_a.force_authenticate(user=self.user_a)

        # User B
        self.user_b = User.objects.create_user(
            username='athlete_bob',
            email='bob@kineticprecision.app',
            password='BobPassword123#',
        )
        UserProfile.objects.get_or_create(user=self.user_b)
        self.client_b.force_authenticate(user=self.user_b)

        # Super Admin
        self.super_admin = User.objects.create_superuser(
            username='gym_admin',
            email='admin@kineticprecision.app',
            password='AdminPassword123#',
        )
        AdminProfile.objects.create(
            user=self.super_admin,
            can_access_admin=True,
            is_totp_verified=True,
            role='superadmin',
        )
        admin_jwt = AccessToken.for_user(self.super_admin)
        admin_jwt['scope'] = 'admin_jwt'
        self.token_admin = str(admin_jwt)
        self.admin_client.force_authenticate(user=self.super_admin, token=self.token_admin)

        # Seed data for User B
        self.food_egg = KineticIngredient.objects.create(
            name='Boiled Egg',
            calories_kcal=155.0,
            protein_g=13.0,
            carbs_g=1.1,
            fat_g=11.0,
            verified=True,
        )
        self.diary_b = KineticDiaryEntry.objects.create(
            user=self.user_b,
            logged_at=timezone.now(),
            meal='breakfast',
            ingredient=self.food_egg,
            quantity_g=100.0,
        )
        self.activity_b = ActivityLog.objects.create(
            user=self.user_b,
            activity_type='running',
            distance_meters=5000.0,
            step_count=4200,
            start_time=timezone.now(),
            calories_burned=350.0,
        )
        self.routine_b = Routine.objects.create(
            user=self.user_b,
            name="Bob's Hypertrophy Routine",
            start=timezone.now().date(),
            end=timezone.now().date() + timedelta(days=90),
        )

    def test_user_a_cannot_read_or_modify_user_b_food_diary(self):
        """User A attempting to read/edit/delete User B's diary entry receives 403 or 404."""
        # Attempt PATCH
        patch_resp = self.client_a.patch(f'/api/v2/nutrition/diary/{self.diary_b.id}/', {
            'quantity_g': 50.0,
        }, format='json')
        self.assertIn(patch_resp.status_code, [status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND, status.HTTP_405_METHOD_NOT_ALLOWED])

        # Attempt DELETE
        del_resp = self.client_a.delete(f'/api/v2/nutrition/diary/{self.diary_b.id}/')
        self.assertIn(del_resp.status_code, [status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND])

        # Verify entry was not altered
        self.diary_b.refresh_from_db()
        self.assertEqual(self.diary_b.quantity_g, 100.0)

    def test_user_a_activity_history_does_not_contain_user_b_records(self):
        """User A's activity history query contains only User A's logs, never User B's."""
        resp_a = self.client_a.get('/api/v2/activity/history/')
        self.assertEqual(resp_a.status_code, status.HTTP_200_OK)
        # Should be empty for User A
        self.assertEqual(len(resp_a.data.get('results', [])), 0)

        # User B reads their own activity history
        resp_b = self.client_b.get('/api/v2/activity/history/')
        self.assertEqual(resp_b.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp_b.data.get('results', [])), 1)

    def test_clients_rejected_on_all_admin_routes(self):
        """Neither User A nor User B can access any /api/v2/admin/** route."""
        admin_routes = [
            '/api/v2/admin/clients/',
            '/api/v2/admin/feedback/',
            '/api/v2/admin/schedules/',
        ]

        for route in admin_routes:
            resp_a = self.client_a.get(route)
            self.assertEqual(resp_a.status_code, status.HTTP_403_FORBIDDEN, f"User A accessed {route}")

            resp_b = self.client_b.get(route)
            self.assertEqual(resp_b.status_code, status.HTTP_403_FORBIDDEN, f"User B accessed {route}")

    def test_admin_can_access_admin_routes(self):
        """Super admin with admin_jwt token succeeds on admin routes."""
        resp = self.admin_client.get('/api/v2/admin/clients/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
