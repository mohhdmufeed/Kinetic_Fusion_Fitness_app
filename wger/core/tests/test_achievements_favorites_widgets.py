# -*- coding: utf-8 -*-
"""
Module 15 Tests — Achievements, Favorites & Home Widgets
Covers: achievement 403 for client POST, Celery task unlocks correctly,
favorites uniform shape, widget reorder persistence, widget value consistency.
"""
from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status

from wger.core.models import (
    Achievement, UserAchievement, Favorite, HomeWidget,
    AchievementRuleType, WidgetType, FavoriteEntityType,
)
from wger.core.tasks.achievement_evaluator import evaluate_achievements


def _make_user(username, password='testpass123!'):
    return User.objects.create_user(username=username, email=f'{username}@test.com', password=password)


def _auth_client(user):
    c = APIClient()
    c.force_authenticate(user=user)
    return c


def _make_achievement(code='first_workout', rule=AchievementRuleType.WORKOUT_COUNT, threshold=1):
    return Achievement.objects.create(
        code=code, title='First Workout!',
        description='Complete your first workout',
        rule_type=rule, threshold=threshold,
    )


class AchievementSecurityTest(TestCase):
    fixtures = ['wger/core/fixtures/languages.json']

    def setUp(self):
        self.alice = _make_user('alice_ach')
        self.ach   = _make_achievement()

    def test_client_post_achievement_returns_403(self):
        """Clients cannot self-claim achievements via POST."""
        resp = _auth_client(self.alice).post('/api/v2/achievements/', {
            'user': self.alice.pk, 'achievement': self.ach.pk
        }, format='json')
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_unauthenticated_achievement_rejected(self):
        resp = APIClient().get('/api/v2/achievements/')
        self.assertIn(resp.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

    def test_celery_task_unlocks_achievement(self):
        """Background task unlocks achievement when threshold is met."""
        # Simulate having 1 workout session
        from django.utils import timezone
        from wger.manager.models import WorkoutSession
        WorkoutSession.objects.create(user=self.alice, date=timezone.now().date())

        evaluate_achievements(self.alice.pk)
        self.assertTrue(
            UserAchievement.objects.filter(user=self.alice, achievement=self.ach).exists()
        )

    def test_celery_task_idempotent(self):
        """Running task twice never creates duplicate UserAchievement rows."""
        from django.utils import timezone
        from wger.manager.models import WorkoutSession
        WorkoutSession.objects.create(user=self.alice, date=timezone.now().date())

        evaluate_achievements(self.alice.pk)
        evaluate_achievements(self.alice.pk)  # Second call
        self.assertEqual(
            UserAchievement.objects.filter(user=self.alice, achievement=self.ach).count(), 1
        )

    def test_achievement_not_unlocked_below_threshold(self):
        """Achievement with threshold=5 not unlocked with 2 workouts."""
        ach5 = _make_achievement(code='five_workouts', threshold=5)
        from django.utils import timezone
        from wger.manager.models import WorkoutSession
        WorkoutSession.objects.create(user=self.alice, date=timezone.now().date())
        WorkoutSession.objects.create(user=self.alice, date=timezone.now().date())

        evaluate_achievements(self.alice.pk)
        self.assertFalse(
            UserAchievement.objects.filter(user=self.alice, achievement=ach5).exists()
        )

    def test_achievement_list_returns_only_own(self):
        """A user only sees their own unlocked achievements."""
        bob = _make_user('bob_ach')
        UserAchievement.objects.create(user=self.alice, achievement=self.ach)
        resp = _auth_client(bob).get('/api/v2/achievements/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data), 0)  # Bob has no achievements


class FavoritesTest(TestCase):
    fixtures = ['wger/core/fixtures/languages.json']

    def setUp(self):
        self.alice = _make_user('alice_fav')
        self.bob   = _make_user('bob_fav')

    def test_favorite_workout(self):
        resp = _auth_client(self.alice).post('/api/v2/favorites/', {
            'entity_type': 'workout', 'entity_id': 'abc-123'
        }, format='json')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['entity_type'], 'workout')

    def test_favorite_exercise(self):
        resp = _auth_client(self.alice).post('/api/v2/favorites/', {
            'entity_type': 'exercise', 'entity_id': '42'
        }, format='json')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

    def test_favorite_trainer(self):
        resp = _auth_client(self.alice).post('/api/v2/favorites/', {
            'entity_type': 'trainer', 'entity_id': '7'
        }, format='json')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

    def test_favorite_is_idempotent(self):
        """Favoriting the same entity twice returns the existing record, no duplicate."""
        c = _auth_client(self.alice)
        c.post('/api/v2/favorites/', {'entity_type': 'workout', 'entity_id': 'xyz'}, format='json')
        c.post('/api/v2/favorites/', {'entity_type': 'workout', 'entity_id': 'xyz'}, format='json')
        self.assertEqual(
            Favorite.objects.filter(user=self.alice, entity_type='workout', entity_id='xyz').count(), 1
        )

    def test_unfavorite(self):
        fav = Favorite.objects.create(user=self.alice, entity_type='exercise', entity_id='99')
        resp = _auth_client(self.alice).delete(f'/api/v2/favorites/{fav.pk}/')
        self.assertEqual(resp.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Favorite.objects.filter(pk=fav.pk).exists())

    def test_user_cannot_delete_others_favorite(self):
        fav = Favorite.objects.create(user=self.alice, entity_type='trainer', entity_id='5')
        resp = _auth_client(self.bob).delete(f'/api/v2/favorites/{fav.pk}/')
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)

    def test_filter_by_entity_type(self):
        Favorite.objects.create(user=self.alice, entity_type='workout', entity_id='1')
        Favorite.objects.create(user=self.alice, entity_type='exercise', entity_id='2')
        resp = _auth_client(self.alice).get('/api/v2/favorites/?entity_type=workout')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data), 1)
        self.assertEqual(resp.data[0]['entity_type'], 'workout')


class HomeWidgetTest(TestCase):
    fixtures = ['wger/core/fixtures/languages.json']

    def setUp(self):
        self.alice = _make_user('alice_wid')

    def test_get_widgets_initially_empty(self):
        resp = _auth_client(self.alice).get('/api/v2/home-widgets/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data), 0)

    def test_put_replaces_widget_list(self):
        widgets = [
            {'widget_type': 'recovery_score', 'position': 0},
            {'widget_type': 'steps', 'position': 1},
        ]
        resp = _auth_client(self.alice).put('/api/v2/home-widgets/', widgets, format='json')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data), 2)

    def test_reorder_persists_and_survives_reload(self):
        """Dragging widgets to new positions survives re-fetch."""
        HomeWidget.objects.create(user=self.alice, widget_type='recovery_score', position=0)
        HomeWidget.objects.create(user=self.alice, widget_type='steps', position=1)
        HomeWidget.objects.create(user=self.alice, widget_type='weight', position=2)

        # Reorder: steps first, recovery second, weight third
        resp = _auth_client(self.alice).patch('/api/v2/home-widgets/reorder/', [
            {'widget_type': 'steps', 'position': 0},
            {'widget_type': 'recovery_score', 'position': 1},
            {'widget_type': 'weight', 'position': 2},
        ], format='json')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

        # Re-fetch and confirm persisted order
        resp2 = _auth_client(self.alice).get('/api/v2/home-widgets/')
        order = [w['widget_type'] for w in sorted(resp2.data, key=lambda x: x['position'])]
        self.assertEqual(order[0], 'steps')
        self.assertEqual(order[1], 'recovery_score')

    def test_put_is_full_replace_not_append(self):
        """PUT replaces all widgets, not appends — no orphans from previous version."""
        HomeWidget.objects.create(user=self.alice, widget_type='recovery_score', position=0)
        HomeWidget.objects.create(user=self.alice, widget_type='steps', position=1)

        # PUT with only one widget
        _auth_client(self.alice).put('/api/v2/home-widgets/', [
            {'widget_type': 'weight', 'position': 0}
        ], format='json')

        # Old widgets must be gone
        self.assertFalse(HomeWidget.objects.filter(user=self.alice, widget_type='recovery_score').exists())
        self.assertFalse(HomeWidget.objects.filter(user=self.alice, widget_type='steps').exists())
        self.assertTrue(HomeWidget.objects.filter(user=self.alice, widget_type='weight').exists())

    def test_unauthenticated_rejected(self):
        resp = APIClient().get('/api/v2/home-widgets/')
        self.assertIn(resp.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])
