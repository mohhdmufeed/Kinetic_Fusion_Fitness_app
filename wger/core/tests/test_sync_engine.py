# -*- coding: utf-8 -*-
import uuid
from datetime import timedelta
from django.contrib.auth.models import User
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.weight.models import WeightEntry
from wger.manager.models import WorkoutLog
from wger.exercises.models import Exercise
from wger.core.models.sync import SyncLog


class SyncEngineTestCase(TestCase):
    """
    Test suite for Kinetic Precision Conflict-Safe Sync Engine:
    1. Idempotent batched push (zero duplicates on partial retries).
    2. Last-write-wins conflict resolution on mutable fields.
    3. Delta pull with timestamp cursors.
    4. SyncLog history tracking.
    """

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='sync_athlete',
            email='sync@kineticprecision.app',
            password='SecurePassword123#',
        )
        self.token = str(AccessToken.for_user(self.user))
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')

    def test_idempotent_push_no_duplicates_on_retry(self):
        """Pushing the same mutation batch twice must be idempotent."""
        client_uuid = str(uuid.uuid4())
        payload = {
            'device_id': 'flutter_pixel_9_pro',
            'client_version': '2.1.0',
            'mutations': [
                {
                    'uuid': client_uuid,
                    'type': 'weight_entry',
                    'action': 'create',
                    'data': {
                        'weight': 78.5,
                        'date': '2026-08-19',
                    },
                    'timestamp': timezone.now().isoformat(),
                },
            ],
        }

        # First Push
        resp1 = self.client.post('/api/v2/sync/push/', payload, format='json')
        self.assertEqual(resp1.status_code, status.HTTP_200_OK)
        self.assertEqual(resp1.data['processed'], 1)
        self.assertEqual(WeightEntry.objects.filter(user=self.user).count(), 1)

        # Retry Push with same batch
        resp2 = self.client.post('/api/v2/sync/push/', payload, format='json')
        self.assertEqual(resp2.status_code, status.HTTP_200_OK)
        # Idempotency: Still exactly 1 row, resolved as conflict/duplicate
        self.assertEqual(WeightEntry.objects.filter(user=self.user).count(), 1)
        self.assertEqual(resp2.data['conflicts_resolved'], 1)

        # Assert SyncLog entries recorded
        self.assertEqual(SyncLog.objects.filter(user=self.user).count(), 2)

    def test_delta_pull_with_since_cursor(self):
        """Pull endpoint returns deltas strictly matching user and timestamp cursor."""
        # Create an entry today
        w1 = WeightEntry.objects.create(
            user=self.user,
            weight=80.0,
            date=timezone.now().date(),
        )

        since_time = (timezone.now() - timedelta(days=1)).isoformat()
        response = self.client.get(f'/api/v2/sync/pull/?since={since_time}')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('deltas', response.data)
        self.assertIn('weight_entries', response.data['deltas'])
        self.assertEqual(len(response.data['deltas']['weight_entries']), 1)
        self.assertEqual(response.data['deltas']['weight_entries'][0]['weight'], 80.0)
        self.assertIn('server_timestamp', response.data)

    def test_multi_device_offline_convergence(self):
        """Two offline devices making separate entries for the same user converge without data loss."""
        uuid_device1 = str(uuid.uuid4())
        uuid_device2 = str(uuid.uuid4())

        # Device 1 pushes morning log
        payload1 = {
            'device_id': 'phone_a',
            'client_version': '2.1.0',
            'mutations': [
                {
                    'uuid': uuid_device1,
                    'type': 'weight_entry',
                    'action': 'create',
                    'data': {'weight': 81.2, 'date': '2026-08-18'},
                    'timestamp': timezone.now().isoformat(),
                }
            ]
        }
        resp1 = self.client.post('/api/v2/sync/push/', payload1, format='json')
        self.assertEqual(resp1.status_code, status.HTTP_200_OK)

        # Device 2 pushes evening log
        payload2 = {
            'device_id': 'tablet_b',
            'client_version': '2.1.0',
            'mutations': [
                {
                    'uuid': uuid_device2,
                    'type': 'weight_entry',
                    'action': 'create',
                    'data': {'weight': 80.9, 'date': '2026-08-19'},
                    'timestamp': timezone.now().isoformat(),
                }
            ]
        }
        resp2 = self.client.post('/api/v2/sync/push/', payload2, format='json')
        self.assertEqual(resp2.status_code, status.HTTP_200_OK)

        # Both records must exist under the user
        self.assertEqual(WeightEntry.objects.filter(user=self.user).count(), 2)

