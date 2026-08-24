# -*- coding: utf-8 -*-
from django.contrib.auth.models import User
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.core.models import Language
from wger.core.models.admin import AdminProfile, AdminAuditLog
from wger.exercises.models import Exercise, ExerciseCategory
from wger.exercises.models.base import ExerciseBase
from wger.exercises.models.publication import (
    ExercisePublicationState,
    UserExerciseFavorite,
    ExerciseLibraryMetadata,
)
from wger.manager.models import WorkoutLog


class ExerciseLibraryLifecycleTestCase(TestCase):
    """
    Test suite for Kinetic Precision Exercise Library lifecycle:
    1. Client browsing, searching, and filtering.
    2. Draft / In-Review isolation (hidden until published).
    3. Super Admin publishing workflow with version invalidation and audit logging.
    4. Athlete favorites and personal PR tracking.
    """

    def setUp(self):
        self.client = APIClient()
        self.admin_client = APIClient()

        # Regular Athlete
        self.athlete = User.objects.create_user(
            username='athlete_gym',
            email='athlete@kineticprecision.app',
            password='AthleteSecurePassword123#',
        )
        self.athlete_token = str(AccessToken.for_user(self.athlete))
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.athlete_token}')

        # Super Admin
        self.admin_user = User.objects.create_superuser(
            username='gym_super_admin',
            email='admin@kineticprecision.app',
            password='AdminSecurePassword123#',
        )
        AdminProfile.objects.create(user=self.admin_user, is_active=True, can_access_admin=True)

        admin_jwt = AccessToken.for_user(self.admin_user)
        admin_jwt['scope'] = 'admin_jwt'
        self.admin_token = str(admin_jwt)
        self.admin_client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.admin_token}')

        # Base category & language
        self.language = Language.objects.filter(pk=2).first() or Language.objects.create(id=2, short_name='en', name='English')
        self.category = ExerciseCategory.objects.create(name='Chest')

        # Create 1 Published Exercise
        self.base_published = ExerciseBase.objects.create(category=self.category)
        self.ex_published = Exercise.objects.create(
            exercise_base=self.base_published,
            name='Barbell Bench Press',
            description='Compound upper body pressing movement',
            language=self.language,
        )
        ExercisePublicationState.objects.create(
            exercise_base=self.base_published,
            status='published',
        )

        # Create 1 Draft Exercise
        self.base_draft = ExerciseBase.objects.create(category=self.category)
        self.ex_draft = Exercise.objects.create(
            exercise_base=self.base_draft,
            name='Incline Dumbbell Flyes (Draft)',
            description='Draft movement under development',
            language=self.language,
        )
        ExercisePublicationState.objects.create(
            exercise_base=self.base_draft,
            status='draft',
        )

    def test_client_cannot_see_draft_exercises(self):
        """Client-facing exercise library must only return published exercises."""
        response = self.client.get('/api/v2/exercise-library/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        names = [item['name'] for item in response.data['results']]
        self.assertIn('Barbell Bench Press', names)
        self.assertNotIn('Incline Dumbbell Flyes (Draft)', names)

    def test_admin_publishing_flow_and_version_invalidation(self):
        """Admin publishes draft -> version increments -> client can now see it."""
        initial_version = ExerciseLibraryMetadata.get_current_version()

        # Admin publishes draft
        pub_resp = self.admin_client.post(f'/api/v2/admin/exercises/{self.base_draft.id}/publish/')
        self.assertEqual(pub_resp.status_code, status.HTTP_200_OK)
        new_version = pub_resp.data['library_version']
        self.assertGreater(new_version, initial_version)

        # Verify audit log created
        self.assertTrue(
            AdminAuditLog.objects.filter(
                actor=self.admin_user,
                target_id=str(self.base_draft.id),
            ).exists()
        )

        # Client now sees the newly published exercise
        client_resp = self.client.get('/api/v2/exercise-library/')
        names = [item['name'] for item in client_resp.data['results']]
        self.assertIn('Incline Dumbbell Flyes (Draft)', names)

    def test_athlete_favorites_and_pr_history(self):
        """Athlete can favorite exercises and retrieve calculated PR history."""
        # 1. Favorite toggle
        fav_resp = self.client.post(f'/api/v2/exercise-library/{self.ex_published.id}/favorite/')
        self.assertEqual(fav_resp.status_code, status.HTTP_200_OK)
        self.assertTrue(fav_resp.data['is_favorite'])

        # 2. Log workout and query PR history
        WorkoutLog.objects.create(
            user=self.athlete,
            exercise_id=self.ex_published.id,
            weight=100.0,
            reps=5,
            date=timezone.now().date(),
        )

        hist_resp = self.client.get(f'/api/v2/exercise-library/{self.ex_published.id}/history/')
        self.assertEqual(hist_resp.status_code, status.HTTP_200_OK)
        prs = hist_resp.data['personal_records']
        self.assertEqual(prs['max_weight_kg'], 100.0)
        # e1RM = 100 * (1 + 5/30) = 116.7
        self.assertEqual(prs['estimated_1rm_kg'], 116.7)
        self.assertEqual(prs['total_sets_logged'], 1)
