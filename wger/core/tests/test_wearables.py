# -*- coding: utf-8 -*-
from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status

from wger.core.models.language import Language
from wger.core.models.wearable import WearableIntegration
from wger.core.models.sync import SyncChangeLog
from wger.core.tasks.wearable_tasks import sync_wearables_periodic


class WearablesIntegrationBackendTests(TestCase):
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
            username='wearable_tester',
            password='Password1234!',
            email='wearables@example.com',
        )
        self.client.force_authenticate(user=self.user)

    def test_oura_oauth_connection_and_revocation(self):
        # 1. Connect Oura
        response = self.client.post('/api/v2/wearables/oura/auth/', {
            'access_token': 'oura_test_access_token_123',
            'refresh_token': 'oura_test_refresh_token_456',
            'expires_in': 86400,
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'connected')

        integration = WearableIntegration.objects.get(user=self.user, provider='oura')
        self.assertTrue(integration.is_active)
        self.assertEqual(integration.encrypted_access_token, 'oura_test_access_token_123')

        # 2. Check status
        status_resp = self.client.get('/api/v2/wearables/status/')
        self.assertEqual(status_resp.status_code, status.HTTP_200_OK)
        self.assertTrue(status_resp.data['oura']['is_active'])

        # 3. Disconnect / Revoke
        disconnect_resp = self.client.post('/api/v2/wearables/oura/auth/', {'action': 'disconnect'})
        self.assertEqual(disconnect_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(disconnect_resp.data['status'], 'revoked')

        integration.refresh_from_db()
        self.assertFalse(integration.is_active)
        self.assertEqual(integration.encrypted_access_token, '')

    def test_oura_raw_sync_and_score_bypassing(self):
        # Establish active integration
        WearableIntegration.objects.create(
            user=self.user,
            provider='oura',
            encrypted_access_token='oura_active_token',
            is_active=True,
        )

        mock_documents = [
            {
                'day': '2026-08-24',
                'average_hrv': 74.5,
                'lowest_heart_rate': 46.0,
                'total_sleep_duration': 28800,  # 8.0 hours
                'steps': 11400,
                'readiness_score': 92,  # Must be ignored
                'sleep_score': 89,      # Must be ignored
            }
        ]

        response = self.client.post('/api/v2/wearables/oura/sync/', {'documents': mock_documents}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['synced_measurements'], 4)

        # Check changelog rows
        logs = SyncChangeLog.objects.filter(actor=self.user, entity_type='Measurement')
        self.assertEqual(logs.count(), 4)

        metrics = [log.payload['metric'] for log in logs]
        self.assertIn('hrv_rmssd', metrics)
        self.assertIn('rhr', metrics)
        self.assertIn('sleep_duration_hrs', metrics)
        self.assertIn('steps', metrics)

        # Ensure no proprietary score metrics exist in the changelog
        for m in metrics:
            self.assertNotIn('score', m)
            self.assertNotIn('readiness', m)

    def test_periodic_wearable_celery_task(self):
        WearableIntegration.objects.create(
            user=self.user,
            provider='oura',
            encrypted_access_token='oura_valid_token',
            is_active=True,
        )

        result = sync_wearables_periodic()
        self.assertEqual(result['status'], 'completed')
        self.assertEqual(result['synced'], 1)
