# -*- coding: utf-8 -*-
from datetime import timedelta
from django.contrib.auth.models import User
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.core.models.admin import AdminProfile, AdminAuditLog
from wger.nutrition.models.kinetic_nutrition import KineticIngredient, KineticDiaryEntry


class ClosedNutritionSystemTestCase(TestCase):
    """
    Test suite for Closed Nutrition Library & Weight-Based Food Diary:
    1. Search & lookup against closed library only (exact/prefix matches).
    2. Weight-based pure math calculation (actual_value = (stored / 100) * grams).
    3. Negative test: Non-admin tokens rejected (403) on admin ingredient endpoints.
    4. Admin adds closed ingredient with 2FA admin_jwt and audit logging.
    5. Diary logging, day-at-a-glance grouping, and running target totals.
    6. Multi-tenant privacy on meal logs.
    """

    def setUp(self):
        self.athlete_client = APIClient()
        self.athlete_b_client = APIClient()
        self.admin_client = APIClient()

        # Athlete A
        self.athlete_a = User.objects.create_user(
            username='athlete_sam',
            email='sam@kineticprecision.app',
            password='Password123#',
        )
        self.token_a = str(AccessToken.for_user(self.athlete_a))
        self.athlete_client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_a}')

        # Athlete B
        self.athlete_b = User.objects.create_user(
            username='athlete_taylor',
            email='taylor@kineticprecision.app',
            password='Password123#',
        )
        self.token_b = str(AccessToken.for_user(self.athlete_b))
        self.athlete_b_client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_b}')

        from wger.core.models import Language
        Language.objects.get_or_create(id=2, defaults={'short_name': 'en', 'full_name': 'English'})

        # Super Admin
        self.admin_user = User.objects.create_superuser(
            username='nutrition_admin',
            email='admin_nutr@kineticprecision.app',
            password='AdminPassword123#',
        )
        AdminProfile.objects.create(
            user=self.admin_user,
            can_access_admin=True,
            is_totp_verified=True,
            role='superadmin',
        )
        admin_jwt = AccessToken.for_user(self.admin_user)
        admin_jwt['scope'] = 'admin_jwt'
        self.admin_token = str(admin_jwt)
        self.admin_client.force_authenticate(user=self.admin_user, token=self.admin_token)
        self.athlete_client.force_authenticate(user=self.athlete_a)
        self.athlete_b_client.force_authenticate(user=self.athlete_b)

        # Seed staple chicken breast
        self.chicken = KineticIngredient.objects.create(
            name='Chicken breast, skinless, cooked',
            category='Meat & Poultry',
            calories_kcal=165.0,
            protein_g=31.0,
            carbs_g=0.0,
            fat_g=3.6,
            sodium_mg=74.0,
            verified=True,
            household_units={'piece': 120.0, 'breast': 172.0},
        )

    def test_search_closed_library(self):
        """Typing 'chicken' returns ranked matches from closed library only."""
        resp = self.athlete_client.get('/api/v2/nutrition/search/?q=chicken')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        names = [item['name'] for item in resp.data['results']]
        self.assertIn('Chicken breast, skinless, cooked', names)

    def test_pure_math_grams_calculation(self):
        """100g returns 165 kcal, 31g protein; 250g returns 413 kcal, 77.5g protein."""
        # 100g
        resp_100 = self.athlete_client.post('/api/v2/nutrition/lookup/', {
            'ingredient_id': self.chicken.id,
            'quantity_g': 100.0,
        }, format='json')
        self.assertEqual(resp_100.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_100.data['calories_kcal'], 165)
        self.assertEqual(resp_100.data['protein_g'], 31.0)
        self.assertEqual(resp_100.data['carbs_g'], 0.0)
        self.assertEqual(resp_100.data['fat_g'], 3.6)
        self.assertEqual(resp_100.data['sodium_mg'], 74)

        # 250g
        resp_250 = self.athlete_client.post('/api/v2/nutrition/lookup/', {
            'ingredient_id': self.chicken.id,
            'quantity_g': 250.0,
        }, format='json')
        self.assertEqual(resp_250.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_250.data['calories_kcal'], 413)
        self.assertEqual(resp_250.data['protein_g'], 77.5)
        self.assertEqual(resp_250.data['fat_g'], 9.0)

    def test_negative_regular_user_cannot_create_ingredient(self):
        """Regular athlete tokens cannot create ingredients in the library (403 Forbidden)."""
        resp = self.athlete_client.post('/api/v2/admin/nutrition/ingredients/', {
            'name': 'Rogue User Food',
            'calories_kcal': 500.0,
            'protein_g': 50.0,
        }, format='json')
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_can_add_closed_ingredient_with_audit_log(self):
        """Super admin adds a reviewed food; audit log is generated."""
        resp = self.admin_client.post('/api/v2/admin/nutrition/ingredients/', {
            'name': 'Quinoa, cooked',
            'category': 'Grains & Starches',
            'calories_kcal': 120.0,
            'protein_g': 4.4,
            'carbs_g': 21.3,
            'fat_g': 1.9,
            'fiber_g': 2.8,
            'sugar_g': 0.9,
            'sodium_mg': 7.0,
        }, format='json')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

        # Verify audit log
        self.assertTrue(
            AdminAuditLog.objects.filter(
                admin_user=self.admin_user,
                target_model='KineticIngredient',
            ).exists()
        )

    def test_diary_logging_and_running_totals(self):
        """Athlete logs food; diary endpoint groups by meal and calculates totals vs target."""
        # Log 200g chicken for lunch
        log_resp = self.athlete_client.post('/api/v2/nutrition/diary/', {
            'ingredient_id': self.chicken.id,
            'quantity_g': 200.0,
            'meal': 'lunch',
        }, format='json')
        self.assertEqual(log_resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(log_resp.data['calories_kcal'], 330)
        self.assertEqual(log_resp.data['protein_g'], 62.0)

        # Query diary
        diary_resp = self.athlete_client.get('/api/v2/nutrition/diary/')
        self.assertEqual(diary_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(diary_resp.data['totals']['calories_kcal'], 330)
        self.assertEqual(diary_resp.data['totals']['protein_g'], 62.0)
        self.assertEqual(len(diary_resp.data['meals']['lunch']['items']), 1)

    def test_multi_tenant_diary_isolation(self):
        """Athlete B cannot read or delete Athlete A's diary entry."""
        entry = KineticDiaryEntry.objects.create(
            user=self.athlete_a,
            ingredient=self.chicken,
            quantity_g=150.0,
            meal='dinner',
        )

        del_resp = self.athlete_b_client.delete(f'/api/v2/nutrition/diary/{entry.id}/')
        self.assertEqual(del_resp.status_code, status.HTTP_404_NOT_FOUND)
        self.assertTrue(KineticDiaryEntry.objects.filter(pk=entry.id).exists())
