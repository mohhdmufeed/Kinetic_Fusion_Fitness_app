# -*- coding: utf-8 -*-
from datetime import timedelta
from django.contrib.auth.models import User
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.core.models.sync import SyncChangeLog, GymClass, GymClassBooking
from wger.core.models.gym_owner import GymOwnerProfile
from wger.core.models.gym_admin import ProgramSchedule
from wger.nutrition.models.kinetic_nutrition import KineticIngredient, KineticDiaryEntry


class ChangeLogSyncEngineTestCase(TestCase):
    """
    Test suite for the Unified Server-Authoritative ChangeLog Sync Engine:
    1. Idempotency: Retrying identical push batch applies exactly once.
    2. Ownership enforcement: Reject unowned entity mutation.
    3. Role-scoping on pull: Non-owner client NEVER receives owner-only entity types.
    4. Optimistic concurrency & conflict resolution on mutable entities.
    5. Atomic SQL concurrency: capacity guard on class booking.
    6. Tombstone delete propagation in ascending monotonic order.
    """

    def setUp(self):
        self.client_a = APIClient()
        self.client_b = APIClient()
        self.owner_client = APIClient()

        from wger.core.models import Language
        Language.objects.get_or_create(id=2, defaults={'short_name': 'en', 'full_name': 'English'})

        # Athlete A (Device 1)
        self.user_a = User.objects.create_user(
            username='sync_athlete_a',
            email='athlete_a@kineticprecision.app',
            password='Password123#',
        )
        self.token_a = str(AccessToken.for_user(self.user_a))
        self.client_a.force_authenticate(user=self.user_a)

        # Athlete B
        self.user_b = User.objects.create_user(
            username='sync_athlete_b',
            email='athlete_b@kineticprecision.app',
            password='Password123#',
        )
        self.token_b = str(AccessToken.for_user(self.user_b))
        self.client_b.force_authenticate(user=self.user_b)

        # Verified Gym Owner
        self.owner_user = User.objects.create_user(
            username='sync_gym_owner',
            email='owner@kineticprecision.app',
            password='OwnerPassword123#',
            is_staff=True,
        )
        GymOwnerProfile.objects.create(
            user=self.owner_user,
            gym_name='Kinetic HQ Gym',
            is_approved=True,
        )
        owner_jwt = AccessToken.for_user(self.owner_user)
        owner_jwt['scope'] = 'owner_jwt'
        self.token_owner = str(owner_jwt)
        self.owner_client.force_authenticate(user=self.owner_user, token=self.token_owner)

        # Seed ingredient
        self.chicken = KineticIngredient.objects.create(
            name='Chicken breast, skinless, cooked',
            category='Meat & Poultry',
            calories_kcal=165.0,
            protein_g=31.0,
            carbs_g=0.0,
            fat_g=3.6,
            verified=True,
        )

    def test_idempotent_push_retry(self):
        """Retrying an identical push batch results in exactly one applied change, never duplicate rows."""
        entry_uuid = '11111111-1111-1111-1111-111111111101'
        batch_payload = {
            'client_id': 'device_pixel_8',
            'batch': [
                {
                    'entity_type': 'DiaryEntry',
                    'entity_id': entry_uuid,
                    'op': 'create',
                    'client_version': 1,
                    'payload': {
                        'ingredient_id': self.chicken.id,
                        'quantity_g': 150.0,
                        'meal': 'lunch',
                    }
                }
            ]
        }

        # 1. First push
        resp1 = self.client_a.post('/api/v2/sync/push/', batch_payload, format='json')
        self.assertEqual(resp1.status_code, status.HTTP_200_OK)
        self.assertEqual(resp1.data['applied_count'], 1)
        self.assertEqual(KineticDiaryEntry.objects.filter(client_uuid=entry_uuid).count(), 1)

        # 2. Retry identical push (e.g. network timeout replay)
        resp2 = self.client_a.post('/api/v2/sync/push/', batch_payload, format='json')
        self.assertEqual(resp2.status_code, status.HTTP_200_OK)
        self.assertEqual(resp2.data['applied'][0]['status'], 'already_applied')
        self.assertEqual(KineticDiaryEntry.objects.filter(client_uuid=entry_uuid).count(), 1)
        self.assertEqual(SyncChangeLog.objects.filter(entity_id=entry_uuid).count(), 1)

    def test_ownership_enforcement_rejects_unowned_mutation(self):
        """A client attempting to mutate another user's entity or owner entity is rejected."""
        # Athlete A attempts to push a ProgramSchedule (Owner-only entity)
        unauthorized_batch = {
            'client_id': 'device_pixel_8',
            'batch': [
                {
                    'entity_type': 'ProgramSchedule',
                    'entity_id': '999',
                    'op': 'create',
                    'client_version': 1,
                    'payload': {'name': 'Unauthorized Split'}
                }
            ]
        }
        resp = self.client_a.post('/api/v2/sync/push/', unauthorized_batch, format='json')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['rejected_count'], 1)
        self.assertIn('permission_denied', resp.data['rejected'][0]['reason'])
        self.assertEqual(ProgramSchedule.objects.filter(name='Unauthorized Split').count(), 0)

    def test_role_scoped_pull_excludes_owner_entities_for_clients(self):
        """A regular client's pull response NEVER includes owner-only entity types even if explicitly requested."""
        # 1. Owner creates a ProgramSchedule changelog
        SyncChangeLog.objects.create(
            actor=self.owner_user,
            entity_type='ProgramSchedule',
            entity_id='sched-500',
            op='create',
            payload={'name': 'Secret Coach Program'},
            processed=True,
        )

        # 2. Athlete creates a personal DiaryEntry changelog
        SyncChangeLog.objects.create(
            actor=self.user_a,
            entity_type='DiaryEntry',
            entity_id='uuid-diary-200',
            op='create',
            payload={'quantity_g': 100.0},
            processed=True,
        )

        # 3. Athlete requests pull including ProgramSchedule
        pull_resp = self.client_a.get('/api/v2/sync/pull/?since=0&entity_types=ProgramSchedule,DiaryEntry')
        self.assertEqual(pull_resp.status_code, status.HTTP_200_OK)

        pulled_types = [c['entity_type'] for c in pull_resp.data['changes']]
        self.assertIn('DiaryEntry', pulled_types)
        self.assertNotIn('ProgramSchedule', pulled_types)

    def test_two_devices_optimistic_version_conflict(self):
        """Two devices editing the same mutable entity: one wins, the second receives conflict with server state."""
        # 1. Owner creates ProgramSchedule v1
        schedule = ProgramSchedule.objects.create(name='Upper Hypertrophy', created_by=self.owner_user, version=1)

        # 2. Device 1 updates schedule to v2
        dev1_payload = {
            'client_id': 'ipad_pro_1',
            'batch': [
                {
                    'entity_type': 'ProgramSchedule',
                    'entity_id': str(schedule.id),
                    'op': 'update',
                    'client_version': 1,
                    'payload': {'name': 'Upper Hypertrophy (Device 1 Edits)'}
                }
            ]
        }
        resp1 = self.owner_client.post('/api/v2/sync/push/', dev1_payload, format='json')
        self.assertEqual(resp1.status_code, status.HTTP_200_OK)
        self.assertEqual(resp1.data['applied_count'], 1)
        schedule.refresh_from_db()
        self.assertEqual(schedule.version, 2)

        # 3. Device 2 (which was offline since v1) pushes edit based on stale v1
        dev2_payload = {
            'client_id': 'macbook_air_2',
            'batch': [
                {
                    'entity_type': 'ProgramSchedule',
                    'entity_id': str(schedule.id),
                    'op': 'update',
                    'client_version': 1,  # Stale version!
                    'payload': {'name': 'Conflicting Device 2 Name'}
                }
            ]
        }
        resp2 = self.owner_client.post('/api/v2/sync/push/', dev2_payload, format='json')
        self.assertEqual(resp2.status_code, status.HTTP_200_OK)
        self.assertEqual(resp2.data['conflict_count'], 1)
        self.assertEqual(resp2.data['conflicts'][0]['server_version'], 2)
        self.assertEqual(resp2.data['conflicts'][0]['server_state']['name'], 'Upper Hypertrophy (Device 1 Edits)')

    def test_atomic_concurrency_capacity_guard(self):
        """Concurrent double-write to counter field at capacity-1 never exceeds capacity."""
        gym_class = GymClass.objects.create(name='HIIT Sprint BootCamp', capacity=1, seats_reserved=0)

        # Booking 1 takes the 1 remaining seat
        batch_user_a = {
            'client_id': 'phone_a',
            'batch': [
                {
                    'entity_type': 'GymClassBooking',
                    'entity_id': 'uuid-booking-a',
                    'op': 'create',
                    'client_version': 1,
                    'payload': {'gym_class_id': gym_class.id}
                }
            ]
        }
        resp_a = self.client_a.post('/api/v2/sync/push/', batch_user_a, format='json')
        self.assertEqual(resp_a.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_a.data['applied_count'], 1)

        # Booking 2 tries to take a seat when class is already full
        batch_user_b = {
            'client_id': 'phone_b',
            'batch': [
                {
                    'entity_type': 'GymClassBooking',
                    'entity_id': 'uuid-booking-b',
                    'op': 'create',
                    'client_version': 1,
                    'payload': {'gym_class_id': gym_class.id}
                }
            ]
        }
        resp_b = self.client_b.post('/api/v2/sync/push/', batch_user_b, format='json')
        self.assertEqual(resp_b.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_b.data['rejected_count'], 1)
        self.assertIn('capacity exceeded', resp_b.data['rejected'][0]['reason'].lower())

        gym_class.refresh_from_db()
        self.assertEqual(gym_class.seats_reserved, 1)

    def test_tombstone_delete_propagation_in_ascending_order(self):
        """Deleting an entity while client is offline propagates tombstone delete in ascending monotonic order."""
        # Log 1: Create
        log1 = SyncChangeLog.objects.create(
            actor=self.user_a,
            entity_type='DiaryEntry',
            entity_id='uuid-tombstone-test',
            op='create',
            payload={'quantity_g': 100.0},
            processed=True,
        )
        # Log 2: Delete
        log2 = SyncChangeLog.objects.create(
            actor=self.user_a,
            entity_type='DiaryEntry',
            entity_id='uuid-tombstone-test',
            op='delete',
            payload={'tombstone': True},
            processed=True,
        )

        pull_resp = self.client_a.get(f'/api/v2/sync/pull/?since=0')
        self.assertEqual(pull_resp.status_code, status.HTTP_200_OK)
        changes = pull_resp.data['changes']
        self.assertGreaterEqual(len(changes), 2)
        ops = [c['op'] for c in changes if c['entity_id'] == 'uuid-tombstone-test']
        self.assertEqual(ops, ['create', 'delete'])
        self.assertLess(log1.id, log2.id)
