# -*- coding: utf-8 -*-
from datetime import timedelta
from django.contrib.auth.models import User
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.core.models.ml import DailyMetrics, MLRecoveryScore, MLTrainingLoad, MLStrengthTrajectory


class HistoricalChartsTestCase(TestCase):
    """
    Test suite for Kinetic Precision Full Historical Charting Suite:
    1. Paginated date-range filtering (7d, 30d, 90d, custom).
    2. Generation of dynamic plain-language analytical summary strings.
    3. Transparent missing-data gap handling (no silent fake interpolation).
    4. Multi-tenant privacy.
    """

    def setUp(self):
        self.client_a = APIClient()
        self.client_b = APIClient()

        # Athlete A
        self.user_a = User.objects.create_user(
            username='chart_athlete_a',
            email='chart_a@kineticprecision.app',
            password='Password123#',
        )
        self.token_a = str(AccessToken.for_user(self.user_a))
        self.client_a.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_a}')

        # Athlete B
        self.user_b = User.objects.create_user(
            username='chart_athlete_b',
            email='chart_b@kineticprecision.app',
            password='Password123#',
        )
        self.token_b = str(AccessToken.for_user(self.user_b))
        self.client_b.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_b}')

        # Seed 10 days of metrics for User A
        today = timezone.now().date()
        for i in range(10):
            d = today - timedelta(days=i)
            DailyMetrics.objects.create(
                user=self.user_a,
                date=d,
                hrv_rmssd=70.0 + i,
                resting_hr=55.0,
                sleep_duration_hrs=8.0,
                sleep_quality_score=88.0,
                steps=10000 + i * 200,
                weight_kg=80.0 - (i * 0.05),
            )
            MLRecoveryScore.objects.create(
                user=self.user_a,
                date=d,
                score=75 + i,
                confidence=0.9,
                contributing_factors={'verdict': 'Solid recovery'},
            )
            MLTrainingLoad.objects.create(
                user=self.user_a,
                date=d,
                acute_load_7d=4000.0,
                chronic_load_28d=3800.0,
                acwr=1.05,
                load_status='optimal',
            )

        MLStrengthTrajectory.objects.create(
            user=self.user_a,
            exercise_name='Barbell Bench Press',
            current_e1rm_kg=105.0,
            projected_e1rm_4w_kg=108.0,
            rate_of_change_kg_per_week=0.75,
            weeks_to_next_benchmark=4.0,
            trajectory_json={'points': []},
        )

    def test_date_range_filtering(self):
        """GET /api/v2/dashboard/history/?range=7d returns exactly 8 date entries (0-7 days)."""
        response = self.client_a.get('/api/v2/dashboard/history/?range=7d')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['range'], '7d')
        self.assertEqual(len(response.data['charts']['recovery']['series']), 8)

    def test_plain_language_summaries_generation(self):
        """Every chart category contains an informative analytical summary string."""
        response = self.client_a.get('/api/v2/dashboard/history/?range=30d')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        charts = response.data['charts']
        self.assertIn('summary', charts['recovery'])
        self.assertIn('Recovery', charts['recovery']['summary'])
        self.assertIn('summary', charts['sleep'])
        self.assertIn('Sleep', charts['sleep']['summary'])
        self.assertIn('summary', charts['weight'])
        self.assertIn('summary', charts['activity'])
        self.assertIn('summary', charts['training_load'])
        self.assertIn('summary', charts['strength'])

    def test_transparent_data_gap_handling(self):
        """Unrecorded days are marked explicitly as is_gap=True without crashing."""
        response = self.client_a.get('/api/v2/dashboard/history/?range=30d')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        rec_series = response.data['charts']['recovery']['series']
        # User only has 10 days of data, so earlier days must be gaps
        gaps = [item for item in rec_series if item['is_gap']]
        self.assertGreater(len(gaps), 0)
        self.assertIsNone(gaps[0]['score'])

    def test_multi_tenant_chart_isolation(self):
        """Athlete B does not receive Athlete A's chart data."""
        response = self.client_b.get('/api/v2/dashboard/history/?range=30d')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        rec_series = response.data['charts']['recovery']['series']
        # All days should be gaps for User B
        non_gaps = [item for item in rec_series if not item['is_gap']]
        self.assertEqual(len(non_gaps), 0)
