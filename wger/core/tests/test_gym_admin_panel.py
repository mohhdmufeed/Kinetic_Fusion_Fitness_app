# -*- coding: utf-8 -*-
from datetime import timedelta
from django.contrib.auth.models import User
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.core.models.admin import AdminProfile, AdminAuditLog
from wger.core.models.gym_admin import (
    ProgramSchedule,
    ProgramDay,
    ProgramExercise,
    ClientMembership,
    BodyStatEntry,
)
from wger.core.models.ml import DailyMetrics
from wger.exercises.models import Exercise, ExerciseCategory, Language
from wger.routines.models import Routine


class GymAdminPanelTestCase(TestCase):
    """
    Test suite for Kinetic Precision Gym Owner & Trainer Management Panel:
    1. Dynamic live days_remaining calculation (including negative lapsed values).
    2. Multi-day program builder with shared Exercise Library linkage.
    3. Program schedule assignment syncing to client's Train tab.
    4. In-person body stat recording reflecting in client progress history.
    5. Strict 2FA admin JWT security boundary.
    """

    def setUp(self):
        self.admin_client = APIClient()
        self.athlete_client = APIClient()

        # Super Admin / Gym Owner
        self.admin_user = User.objects.create_superuser(
            username='gym_owner',
            email='owner@kineticprecision.app',
            password='OwnerPassword123#',
        )
        AdminProfile.objects.create(user=self.admin_user, is_active=True, can_access_admin=True)
        admin_jwt = AccessToken.for_user(self.admin_user)
        admin_jwt['scope'] = 'admin_jwt'
        self.admin_token = str(admin_jwt)
        self.admin_client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.admin_token}')

        # Regular Athlete Client
        self.athlete_user = User.objects.create_user(
            username='client_sarah',
            email='sarah@kineticprecision.app',
            password='SarahPassword123#',
            first_name='Sarah',
            last_name='Connor',
        )
        self.athlete_token = str(AccessToken.for_user(self.athlete_user))
        self.athlete_client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.athlete_token}')

        # Base exercises
        self.lang, _ = Language.objects.get_or_create(language='English', short_name='en')
        self.cat_chest, _ = ExerciseCategory.objects.get_or_create(name='Chest')
        self.bench_press = Exercise.objects.create(
            name='Barbell Bench Press',
            category=self.cat_chest,
            language=self.lang,
        )

    def test_live_days_remaining_and_lapsed_membership(self):
        """Membership days_remaining is computed live; lapsed member correctly shows negative days."""
        today = timezone.now().date()
        # Lapsed client (expired 10 days ago)
        lapsed_client = User.objects.create_user(
            username='lapsed_john',
            email='john@kineticprecision.app',
            password='Password123#',
        )
        ClientMembership.objects.create(
            user=lapsed_client,
            membership_start_date=today - timedelta(days=40),
            membership_end_date=today - timedelta(days=10),
        )

        # Active client
        ClientMembership.objects.create(
            user=self.athlete_user,
            membership_start_date=today,
            membership_end_date=today + timedelta(days=30),
        )

        resp = self.admin_client.get('/api/v2/admin/clients/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        results = {item['username']: item for item in resp.data['results']}

        # Assert lapsed John has -10 days remaining
        self.assertEqual(results['lapsed_john']['days_remaining'], -10)
        self.assertEqual(results['lapsed_john']['alert_status'], 'lapsed')

        # Assert active Sarah has 30 days remaining
        self.assertEqual(results['client_sarah']['days_remaining'], 30)
        self.assertEqual(results['client_sarah']['alert_status'], 'active')

    def test_program_builder_and_client_assignment(self):
        """Admin builds a program using shared Exercise Library and assigns it to client."""
        # 1. Create Program
        prog_payload = {
            'name': '5-Day Strength & Hypertrophy Split',
            'description': 'Targeted progressive overload split for intermediate lifters.',
            'days': [
                {
                    'day_number': 1,
                    'label': 'Day 1 - Heavy Push',
                    'exercises': [
                        {
                            'exercise_id': self.bench_press.id,
                            'sets': 4,
                            'reps': '5',
                            'technique': 'max',
                        }
                    ]
                }
            ]
        }
        create_resp = self.admin_client.post('/api/v2/admin/schedules/', prog_payload, format='json')
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED)
        schedule_id = create_resp.data['schedule_id']

        # 2. Assign to Sarah
        assign_resp = self.admin_client.post(f'/api/v2/admin/clients/{self.athlete_user.id}/assign-schedule/', {
            'schedule_id': schedule_id,
        }, format='json')
        self.assertEqual(assign_resp.status_code, status.HTTP_200_OK)

        # 3. Verify Sarah has active routine mirrored
        routine = Routine.objects.filter(user=self.athlete_user).first()
        self.assertIsNotNone(routine)
        self.assertEqual(routine.days.count(), 1)
        self.assertEqual(routine.days.first().set_set.count(), 1)

    def test_in_person_body_stats_recording_and_sync(self):
        """Admin records in-person body measurements; updates DailyMetrics for progress charts."""
        stat_payload = {
            'recorded_date': timezone.now().date().isoformat(),
            'height_cm': 178.0,
            'weight_kg': 82.5,
            'chest_cm': 104.0,
            'waist_cm': 81.0,
            'arm_cm': 38.5,
            'note': 'Initial baseline assessment before starting program.',
        }

        stat_resp = self.admin_client.post(
            f'/api/v2/admin/clients/{self.athlete_user.id}/stats/',
            stat_payload,
            format='json'
        )
        self.assertEqual(stat_resp.status_code, status.HTTP_201_CREATED)

        # Check BodyStatEntry created with admin tag
        stat_entry = BodyStatEntry.objects.get(pk=stat_resp.data['stat_id'])
        self.assertEqual(stat_entry.recorded_by_type, 'admin')
        self.assertEqual(stat_entry.weight_kg, 82.5)

        # Check DailyMetrics updated
        daily = DailyMetrics.objects.get(user=self.athlete_user, date=timezone.now().date())
        self.assertEqual(daily.weight_kg, 82.5)

    def test_strict_2fa_admin_route_security(self):
        """Regular athlete client token is rejected on /api/v2/admin/**."""
        resp = self.athlete_client.get('/api/v2/admin/clients/')
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)
