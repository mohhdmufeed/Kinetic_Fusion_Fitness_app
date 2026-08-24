# -*- coding: utf-8 -*-
from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.utils.unit_conversion import kg_to_lb, lb_to_kg, to_display_weight, from_display_weight
from wger.weight.models import WeightEntry


class UnitHandlingTestCase(TestCase):
    """
    Test suite for Kinetic Precision Canonical Unit Handling:
    1. Zero-drift round-trip conversions between canonical kg and display lb.
    2. Input conversion accuracy from lb mode to canonical kg storage.
    3. Database records strictly store float kilograms.
    """

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='unit_athlete',
            email='unit@kineticprecision.app',
            password='SecurePassword123#',
        )
        self.token = str(AccessToken.for_user(self.user))
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')

    def test_zero_drift_round_trip_conversions(self):
        """Converting 185.0 lb to kg and back to lb must remain exactly 185.0 lb with zero numerical drift."""
        original_lb = 185.0
        canonical_kg = lb_to_kg(original_lb, precision=2)  # 83.91 kg

        # Convert back to lb display
        converted_lb = kg_to_lb(canonical_kg, precision=1)
        self.assertEqual(converted_lb, 185.0)

        # Run 20 consecutive round-trip cycles to verify drift immunity
        test_val = original_lb
        for _ in range(20):
            kg_val = from_display_weight(test_val, use_kilograms=False, precision=2)
            display_val, unit = to_display_weight(kg_val, use_kilograms=False, precision=1)
            test_val = display_val

        self.assertEqual(test_val, 185.0)

    def test_canonical_kg_storage_in_database(self):
        """User logs 185 lb -> converted to 83.91 kg before storing in WeightEntry."""
        user_input_lb = 185.0
        kg_to_save = from_display_weight(user_input_lb, use_kilograms=False)

        entry = WeightEntry.objects.create(
            user=self.user,
            weight=kg_to_save,
        )

        entry.refresh_from_db()
        self.assertEqual(float(entry.weight), 83.91)
        self.assertNotEqual(float(entry.weight), 185.0)  # Never stores lbs
