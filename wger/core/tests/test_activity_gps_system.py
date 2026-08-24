# -*- coding: utf-8 -*-
from datetime import timedelta
from django.contrib.auth.models import User
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.core.models.activity import ActivityLog
from wger.core.models.ml import DailyMetrics


class ActivityGPSSystemTestCase(TestCase):
    """
    Test suite for Kinetic Precision Real GPS & Pedometer Activity Tracking:
    1. GPS workout recording with distance, steps, and DailyMetrics sync.
    2. Athlete history retrieval and multi-tenant isolation.
    3. GDPR / Privacy location history purge endpoint.
    """

    def setUp(self):
        self.client_a = APIClient()
        self.client_b = APIClient()

        # Athlete A
        self.user_a = User.objects.create_user(
            username='runner_alice',
            email='alice@kineticprecision.app',
            password='AlicePassword123#',
        )
        self.token_a = str(AccessToken.for_user(self.user_a))
        self.client_a.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_a}')

        # Athlete B
        self.user_b = User.objects.create_user(
            username='runner_bob',
            email='bob@kineticprecision.app',
            password='BobPassword123#',
        )
        self.token_b = str(AccessToken.for_user(self.user_b))
        self.client_b.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_b}')

    def test_record_gps_run_and_update_daily_metrics(self):
        """Recording a GPS run updates ActivityLog and DailyMetrics step totals."""
        payload = {
            'activity_type': 'running',
            'start_time': timezone.now().isoformat(),
            'distance_meters': 5230.0,
            'step_count': 4850,
            'avg_pace_min_per_km': 4.75,
            'calories_burned': 365.0,
            'route_geojson': {
                'type': 'LineString',
                'coordinates': [
                    [37.7749, -122.4194],
                    [37.7752, -122.4180],
                    [37.7760, -122.4165],
                ]
            }
        }

        response = self.client_a.post('/api/v2/activity/record/', payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['distance_km'], 5.23)
        self.assertEqual(response.data['step_count'], 4850)

        # Check DailyMetrics updated
        today = timezone.now().date()
        daily = DailyMetrics.objects.get(user=self.user_a, date=today)
        self.assertEqual(daily.steps, 4850)

    def test_athlete_isolation_on_activity_history(self):
        """Athlete A can only view their own activity history."""
        ActivityLog.objects.create(
            user=self.user_a,
            activity_type='running',
            distance_meters=5000.0,
            step_count=4500,
        )
        ActivityLog.objects.create(
            user=self.user_b,
            activity_type='cycling',
            distance_meters=15000.0,
            step_count=0,
        )

        response = self.client_a.get('/api/v2/activity/history/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        types = [item['activity_type'] for item in response.data['results']]
        self.assertIn('running', types)
        self.assertNotIn('cycling', types)

    def test_gdpr_location_history_purge(self):
        """DELETE /api/v2/activity/location-history/ purges GPS breadcrumbs while keeping aggregate stats."""
        ActivityLog.objects.create(
            user=self.user_a,
            activity_type='running',
            distance_meters=5000.0,
            step_count=4500,
            route_geojson={'coordinates': [[37.77, -122.41]]},
        )

        del_resp = self.client_a.delete('/api/v2/activity/location-history/')
        self.assertEqual(del_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(del_resp.data['records_cleared'], 1)

        # Assert coordinates cleared
        log = ActivityLog.objects.get(user=self.user_a)
        self.assertEqual(log.route_geojson, {})
        self.assertEqual(log.distance_meters, 5000.0)  # Aggregates preserved
