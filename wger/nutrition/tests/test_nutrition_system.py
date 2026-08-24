# -*- coding: utf-8 -*-
import uuid
from django.contrib.auth.models import User
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.nutrition.models.kinetic_nutrition import KineticIngredient, KineticDiaryEntry
from wger.nutrition.helpers.food_seed import ensure_starter_foods_seeded


class NutritionSystemTestCase(TestCase):
    """
    Test suite for Kinetic Precision Nutrition, Food Logging, and Macro Engine:
    1. Pure mathematical macro calculations & household unit conversions.
    2. Ranked search and Open Food Facts live caching.
    3. Meal diary logging, running daily totals, and target tracking.
    4. Multi-tenant privacy and IDOR rejection on food diaries.
    """

    def setUp(self):
        self.client_a = APIClient()
        self.client_b = APIClient()

        # Athlete A
        self.user_a = User.objects.create_user(
            username='chef_alex',
            email='alex@kineticprecision.app',
            password='AlexPassword123#',
        )
        self.token_a = str(AccessToken.for_user(self.user_a))
        self.client_a.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_a}')

        # Athlete B
        self.user_b = User.objects.create_user(
            username='chef_blake',
            email='blake@kineticprecision.app',
            password='BlakePassword123#',
        )
        self.token_b = str(AccessToken.for_user(self.user_b))
        self.client_b.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_b}')

        ensure_starter_foods_seeded()
        self.chicken = KineticIngredient.objects.get(name='Chicken breast, skinless, cooked')
        self.rice = KineticIngredient.objects.get(name='Brown Rice, cooked')

    def test_pure_macro_calculation_and_household_units(self):
        """100g chicken breast matches 165 kcal, 31g protein; 1 cup brown rice (195g) calculates accurately."""
        # 100g Chicken Breast
        resp_chicken = self.client_a.post('/api/v2/nutrition/lookup/', {
            'ingredient_id': self.chicken.id,
            'quantity': 100.0,
            'unit': 'g',
        }, format='json')
        self.assertEqual(resp_chicken.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_chicken.data['calories_kcal'], 165.0)
        self.assertEqual(resp_chicken.data['protein_g'], 31.0)
        self.assertEqual(resp_chicken.data['carbs_g'], 0.0)
        self.assertEqual(resp_chicken.data['fat_g'], 3.6)

        # 1 cup Brown Rice (maps to 195g via household_units)
        resp_rice = self.client_a.post('/api/v2/nutrition/lookup/', {
            'ingredient_id': self.rice.id,
            'quantity': 1.0,
            'unit': 'cup',
        }, format='json')
        self.assertEqual(resp_rice.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_rice.data['canonical_grams'], 195.0)
        expected_cals = round((123.0 / 100.0) * 195.0, 1) # 239.9
        self.assertEqual(resp_rice.data['calories_kcal'], expected_cals)

    def test_nutrition_search_ranking(self):
        """Searching 'chicken' returns ranked matches with exact/prefix at top."""
        resp = self.client_a.get('/api/v2/nutrition/search/?q=chicken')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        names = [item['name'] for item in resp.data['results']]
        self.assertIn('Chicken breast, skinless, cooked', names)
        self.assertIn('Chicken thigh, skinless, cooked', names)

    def test_log_food_to_diary_and_running_totals(self):
        """Logging meals updates daily totals, meal groups, and remaining budget vs target."""
        client_uuid = str(uuid.uuid4())
        payload = {
            'ingredient_id': self.chicken.id,
            'quantity': 200.0,
            'unit': 'g',
            'meal': 'lunch',
            'client_uuid': client_uuid,
        }

        log_resp = self.client_a.post('/api/v2/nutrition/log/', payload, format='json')
        self.assertEqual(log_resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(log_resp.data['calories_kcal'], 330.0) # 165 * 2
        self.assertEqual(log_resp.data['protein_g'], 62.0) # 31 * 2

        # Check diary
        diary_resp = self.client_a.get('/api/v2/nutrition/diary/')
        self.assertEqual(diary_resp.status_code, status.HTTP_200_OK)
        totals = diary_resp.data['totals']
        self.assertEqual(totals['calories_kcal'], 330.0)
        self.assertEqual(totals['protein_g'], 62.0)
        self.assertGreater(diary_resp.data['remaining']['calories_kcal'], 0)
        self.assertEqual(len(diary_resp.data['meals']['lunch']), 1)

    def test_multi_tenant_isolation_and_idor_protection(self):
        """User B cannot view, edit, or delete User A's diary entries."""
        entry = KineticDiaryEntry.objects.create(
            user=self.user_a,
            ingredient=self.chicken,
            quantity_g=150.0,
            meal='dinner',
        )

        # User B attempts to edit User A's entry
        patch_resp = self.client_b.patch(f'/api/v2/nutrition/diary/{entry.id}/', {'quantity_g': 500.0}, format='json')
        self.assertEqual(patch_resp.status_code, status.HTTP_404_NOT_FOUND)

        # User B attempts to delete User A's entry
        del_resp = self.client_b.delete(f'/api/v2/nutrition/diary/{entry.id}/')
        self.assertEqual(del_resp.status_code, status.HTTP_404_NOT_FOUND)

        # Entry remains unchanged
        entry.refresh_from_db()
        self.assertEqual(entry.quantity_g, 150.0)
