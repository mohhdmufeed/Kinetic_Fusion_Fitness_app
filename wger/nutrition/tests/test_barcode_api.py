# -*- coding: utf-8 -*-
from unittest.mock import patch, MagicMock
from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status

from wger.core.models.language import Language
from wger.nutrition.models.kinetic_nutrition import KineticIngredient
from wger.nutrition.models import Ingredient


class BarcodeLookupAPITestCase(TestCase):
    def setUp(self):
        Language.objects.get_or_create(
            id=2,
            defaults={
                'short_name': 'en',
                'full_name': 'English',
                'full_name_en': 'English',
            },
        )
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='barcode_athlete',
            password='SecurePassword123!',
            email='athlete@barcode.com',
        )
        self.client.force_authenticate(user=self.user)

    def test_barcode_lookup_from_local_kinetic_cache(self):
        # 1. Seed a local food with barcode
        food = KineticIngredient.objects.create(
            name="Organic Rolled Oats",
            brand="Bob's Red Mill",
            barcode="039978001153",
            calories_kcal=389.0,
            protein_g=16.9,
            carbs_g=66.3,
            fat_g=6.9,
            fiber_g=10.6,
            sugar_g=0.0,
            sodium_mg=0.0,
            source="local_curated",
            verified=True,
        )

        response = self.client.get(f'/api/v2/nutrition/barcode/?code={food.barcode}')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['id'], food.id)
        self.assertEqual(response.data['name'], "Organic Rolled Oats")
        self.assertEqual(response.data['barcode'], "039978001153")
        self.assertEqual(response.data['calories_kcal'], 389)
        self.assertEqual(response.data['protein_g'], 16.9)
        self.assertEqual(response.data['unit'], "100g")

    def test_barcode_lookup_post_method(self):
        food = KineticIngredient.objects.create(
            name="Greek Yogurt 0%",
            brand="Fage",
            barcode="5201051000305",
            calories_kcal=54.0,
            protein_g=10.3,
            carbs_g=3.0,
            fat_g=0.0,
            source="local_curated",
            verified=True,
        )

        response = self.client.post('/api/v2/nutrition/barcode/', {'code': '5201051000305'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], "Greek Yogurt 0%")

    @patch.object(Ingredient, 'fetch_ingredient_from_off')
    def test_barcode_lookup_fallback_to_open_food_facts(self, mock_fetch_off):
        # Mock Open Food Facts return
        lang = Language.objects.get(id=2)
        mock_ingredient = Ingredient(
            id=999,
            name="Hazelnut Cocoa Spread",
            brand="Nutella",
            code="3017620422003",
            energy=539,
            protein=6.3,
            carbohydrates=57.5,
            fat=30.9,
            fiber=0.0,
            carbohydrates_sugar=56.3,
            sodium=40.0,
            language=lang,
        )
        mock_fetch_off.return_value = mock_ingredient

        response = self.client.get('/api/v2/nutrition/barcode/?code=3017620422003')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], "Hazelnut Cocoa Spread")
        self.assertEqual(response.data['calories_kcal'], 539)
        self.assertEqual(response.data['protein_g'], 6.3)
        self.assertEqual(response.data['source'], "open_food_facts")

        # Verify it cached to KineticIngredient
        cached = KineticIngredient.objects.filter(barcode="3017620422003").first()
        self.assertIsNotNone(cached)
        self.assertEqual(cached.name, "Hazelnut Cocoa Spread")

    @patch.object(Ingredient, 'fetch_ingredient_from_off')
    def test_barcode_lookup_not_found(self, mock_fetch_off):
        mock_fetch_off.return_value = None

        response = self.client.get('/api/v2/nutrition/barcode/?code=9999999999999')
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertTrue(response.data.get('not_found'))
        self.assertEqual(response.data.get('barcode'), '9999999999999')

    def test_barcode_lookup_missing_param(self):
        response = self.client.get('/api/v2/nutrition/barcode/')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
