# -*- coding: utf-8 -*-
from datetime import timedelta
from django.contrib.auth.models import User
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.core.models.gym_owner import GymOwnerProfile
from wger.core.models.gym_admin import (
    ProgramSchedule,
    ProgramDay,
    ProgramExercise,
    ClientMembership,
    BodyStatEntry,
)
from wger.exercises.models import Exercise, ExerciseCategory
from wger.core.models import Language, License
from wger.manager.models import Routine


class GymCommandCenterTestCase(TestCase):
    """
    Test suite for Gym Command Center:
    1. Unapproved or non-owner tokens rejected on all /api/v2/owner/** routes.
    2. Real-time DB re-validation: Mid-session revocation locks out immediately.
    3. Update-in-place (not append): Idempotent full day/exercise replacement without duplicate programs.
    4. Atomic drag-and-drop reorder persists exact positions.
    5. Weight-based prescription in canonical kilograms.
    """

    def setUp(self):
        Language.objects.get_or_create(id=2, defaults={'short_name': 'en', 'full_name': 'English'})
        License.objects.get_or_create(id=1, defaults={'short_name': 'PD', 'full_name': 'Public Domain'})
        License.objects.get_or_create(id=2, defaults={'short_name': 'CC', 'full_name': 'Creative Commons'})
        self.athlete_client = APIClient()
        self.staff_client = APIClient()
        self.owner_client = APIClient()

        # Regular Athlete
        self.athlete = User.objects.create_user(
            username='athlete_user',
            email='athlete@kineticprecision.app',
            password='Password123#',
        )
        self.athlete_token = str(AccessToken.for_user(self.athlete))
        self.athlete_client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.athlete_token}')

        # Generic Module 2 Staff Admin (Not an approved Gym Owner)
        self.staff = User.objects.create_user(
            username='staff_admin',
            email='staff@kineticprecision.app',
            password='Password123#',
            is_staff=True,
        )
        staff_jwt = AccessToken.for_user(self.staff)
        staff_jwt['scope'] = 'admin_jwt'
        self.staff_token = str(staff_jwt)
        self.staff_client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.staff_token}')

        # Verified & Approved Gym Owner
        self.owner = User.objects.create_user(
            username='gym_owner_boss',
            email='boss@kineticprecision.app',
            password='OwnerPassword123#',
            is_staff=True,
        )
        self.owner_profile = GymOwnerProfile.objects.create(
            user=self.owner,
            gym_name='Kinetic Flagship Gym',
            is_approved=True,
        )
        owner_jwt = AccessToken.for_user(self.owner)
        owner_jwt['scope'] = 'owner_jwt'
        self.owner_token = str(owner_jwt)
        self.owner_client.force_authenticate(user=self.owner, token=self.owner_token)
        self.athlete_client.force_authenticate(user=self.athlete)
        self.staff_client.force_authenticate(user=self.staff)

        # Exercises
        cat, _ = ExerciseCategory.objects.get_or_create(name='Chest')
        self.bench = Exercise.objects.create(category=cat)
        self.incline = Exercise.objects.create(category=cat)

    def test_non_owner_and_unapproved_owner_rejected(self):
        """Athlete and generic staff tokens are rejected (403 Forbidden) on Command Center routes."""
        # Athlete
        resp_athlete = self.athlete_client.get('/api/v2/owner/clients/')
        self.assertEqual(resp_athlete.status_code, status.HTTP_403_FORBIDDEN)

        # Generic Staff Admin
        resp_staff = self.staff_client.get('/api/v2/owner/clients/')
        self.assertEqual(resp_staff.status_code, status.HTTP_403_FORBIDDEN)

        # Unapproved Owner applicant
        unapproved_user = User.objects.create_user(username='applicant', password='Password123#')
        GymOwnerProfile.objects.create(user=unapproved_user, gym_name='Pending Gym', is_approved=False)
        unapp_jwt = AccessToken.for_user(unapproved_user)
        unapp_jwt['scope'] = 'owner_jwt'
        unapp_client = APIClient()
        unapp_client.force_authenticate(user=unapproved_user, token=str(unapp_jwt))

        resp_unapp = unapp_client.get('/api/v2/owner/clients/')
        self.assertEqual(resp_unapp.status_code, status.HTTP_403_FORBIDDEN)

    def test_mid_session_owner_revocation_locks_out_immediately(self):
        """Revoking is_approved in the DB locks out the owner on the very next request."""
        # 1. Initial request succeeds
        resp1 = self.owner_client.get('/api/v2/owner/clients/')
        self.assertEqual(resp1.status_code, status.HTTP_200_OK)

        # 2. Revoke owner in DB
        self.owner_profile.is_approved = False
        self.owner_profile.save()

        # 3. Next request rejected immediately with 403
        resp2 = self.owner_client.get('/api/v2/owner/clients/')
        self.assertEqual(resp2.status_code, status.HTTP_403_FORBIDDEN)

    def test_weight_based_program_creation_and_update_in_place(self):
        """
        Editing an assigned program updates in-place with zero duplicate parallel programs
        and zero leftover old exercises.
        """
        # 1. Create Initial Program
        create_payload = {
            'name': 'Powerbuilding Split',
            'description': 'Initial program version',
            'days': [
                {
                    'day_number': 1,
                    'label': 'Day 1 - Push',
                    'order': 0,
                    'exercises': [
                        {
                            'exercise_id': self.bench.id,
                            'sets': 4,
                            'reps': '6',
                            'target_weight_kg': 100.0,
                            'technique': 'normal',
                            'rest_seconds': 120,
                            'order': 0,
                        }
                    ]
                }
            ]
        }
        create_resp = self.owner_client.post('/api/v2/owner/schedules/', create_payload, format='json')
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED)
        sched_id = create_resp.data['schedule_id']

        # 2. PUT Update-in-Place: Replace with Incline Dumbbell Press only
        update_payload = {
            'name': 'Powerbuilding Split (Updated)',
            'days': [
                {
                    'day_number': 1,
                    'label': 'Day 1 - Hypertrophy Push',
                    'order': 0,
                    'exercises': [
                        {
                            'exercise_id': self.incline.id,
                            'sets': 3,
                            'reps': '10-12',
                            'target_weight_kg': 36.0,
                            'technique': 'drop_set',
                            'rest_seconds': 90,
                            'order': 0,
                        }
                    ]
                }
            ]
        }
        put_resp = self.owner_client.put(f'/api/v2/owner/schedules/{sched_id}/', update_payload, format='json')
        self.assertEqual(put_resp.status_code, status.HTTP_200_OK)

        # 3. Assert exactly 1 ProgramSchedule exists, version incremented
        self.assertEqual(ProgramSchedule.objects.count(), 1)
        schedule = ProgramSchedule.objects.get(pk=sched_id)
        self.assertEqual(schedule.version, 2)

        # 4. Assert old Bench Press is gone, only Incline Press remains
        day = schedule.days.first()
        self.assertEqual(day.exercises.count(), 1)
        self.assertEqual(day.exercises.first().exercise, self.incline)
        self.assertEqual(day.exercises.first().target_weight_kg, 36.0)

    def test_atomic_drag_and_drop_reordering(self):
        """Reordering days and exercises updates positions atomically in one transaction."""
        schedule = ProgramSchedule.objects.create(name='Split', created_by=self.owner)
        d1 = ProgramDay.objects.create(schedule=schedule, day_number=1, label='Push', order=0)
        d2 = ProgramDay.objects.create(schedule=schedule, day_number=2, label='Pull', order=1)

        ex1 = ProgramExercise.objects.create(program_day=d1, exercise=self.bench, order=0)
        ex2 = ProgramExercise.objects.create(program_day=d1, exercise=self.incline, order=1)

        # Reorder payload: Swap day order and exercise order
        reorder_payload = {
            'days': [
                {
                    'id': d1.id,
                    'order': 1,  # Push moved to 2nd
                    'exercises': [
                        {'id': ex1.id, 'order': 1},  # Bench moved to 2nd
                        {'id': ex2.id, 'order': 0},  # Incline moved to 1st
                    ]
                },
                {
                    'id': d2.id,
                    'order': 0,  # Pull moved to 1st
                    'exercises': []
                }
            ]
        }

        patch_resp = self.owner_client.patch(f'/api/v2/owner/schedules/{schedule.id}/reorder/', reorder_payload, format='json')
        self.assertEqual(patch_resp.status_code, status.HTTP_200_OK)

        # Verify persisted positions
        d1.refresh_from_db()
        d2.refresh_from_db()
        ex1.refresh_from_db()
        ex2.refresh_from_db()

        self.assertEqual(d1.order, 1)
        self.assertEqual(d2.order, 0)
        self.assertEqual(ex1.order, 1)
        self.assertEqual(ex2.order, 0)
