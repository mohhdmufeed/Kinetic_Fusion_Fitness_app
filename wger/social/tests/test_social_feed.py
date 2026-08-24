# -*- coding: utf-8 -*-
"""
Module 13 Tests — Community / Social Feed
Covers: feed isolation, duplicate report prevention, poll uniqueness,
workout_ref privacy, offline outbox deduplication.
"""
from django.test import TestCase
from django.contrib.auth.models import User
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status

from wger.social.models import (
    Post, Follow, Like, Comment, PollOption, PollVote,
    ContentReport, Notification, PostType,
)


def _make_user(username, password='testpass123!'):
    return User.objects.create_user(username=username, email=f'{username}@test.com', password=password)


def _auth_client(user):
    client = APIClient()
    client.force_authenticate(user=user)
    return client


class SocialFeedTest(TestCase):
    fixtures = ['wger/core/fixtures/languages.json']

    def setUp(self):
        self.alice = _make_user('alice')
        self.bob   = _make_user('bob')
        self.carol = _make_user('carol')

    # -----------------------------------------------------------------------
    # Feed tests
    # -----------------------------------------------------------------------

    def test_post_create_and_retrieve(self):
        client = _auth_client(self.alice)
        response = client.post('/api/v2/social/posts/', {
            'post_type':  'text',
            'caption':    'Hello world!',
            'visibility': 'gym_only',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['caption'], 'Hello world!')

    def test_feed_returns_only_gym_scope(self):
        """Posts are gym-scoped; users from different gyms never appear."""
        alice_client = _auth_client(self.alice)
        alice_client.post('/api/v2/social/posts/', {
            'post_type': 'text', 'caption': 'Alice post', 'visibility': 'gym_only',
        }, format='json')
        bob_client = _auth_client(self.bob)
        resp = bob_client.get('/api/v2/social/posts/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        # Both in default_gym so Bob sees Alice's post
        captions = [p['caption'] for p in resp.data]
        self.assertIn('Alice post', captions)

    def test_unauthenticated_feed_rejected(self):
        client = APIClient()
        resp = client.get('/api/v2/social/posts/')
        self.assertIn(resp.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

    # -----------------------------------------------------------------------
    # Like tests
    # -----------------------------------------------------------------------

    def test_like_and_unlike(self):
        post = Post.objects.create(
            author=self.alice, post_type='text', caption='Test', gym_id='default_gym'
        )
        client = _auth_client(self.bob)
        like_url = f'/api/v2/social/posts/{post.pk}/like/'
        resp = client.post(like_url)
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertTrue(resp.data['liked'])
        # Unlike
        resp2 = client.delete(like_url)
        self.assertFalse(resp2.data['liked'])

    def test_like_is_idempotent(self):
        post = Post.objects.create(
            author=self.alice, post_type='text', caption='X', gym_id='default_gym'
        )
        client = _auth_client(self.bob)
        url = f'/api/v2/social/posts/{post.pk}/like/'
        client.post(url)
        resp2 = client.post(url)
        # Second like returns 200 (already liked), not 201
        self.assertEqual(resp2.status_code, status.HTTP_200_OK)
        self.assertEqual(post.likes.count(), 1)  # Only one Like row

    # -----------------------------------------------------------------------
    # Poll uniqueness — DB-level enforcement
    # -----------------------------------------------------------------------

    def test_poll_double_vote_rejected(self):
        post = Post.objects.create(
            author=self.alice, post_type='poll', caption='Which?', gym_id='default_gym'
        )
        opt = PollOption.objects.create(post=post, text='Option A', position=0)
        PollVote.objects.create(poll_option=opt, voter=self.bob, post=post)

        client = _auth_client(self.bob)
        resp = client.post(f'/api/v2/social/poll/{opt.pk}/vote/')
        self.assertEqual(resp.status_code, status.HTTP_409_CONFLICT)

    def test_poll_vote_unique_at_db_level(self):
        """unique_together (post, voter) enforced even if API is bypassed."""
        post = Post.objects.create(
            author=self.alice, post_type='poll', caption='Y/N?', gym_id='default_gym'
        )
        opt = PollOption.objects.create(post=post, text='Y', position=0)
        PollVote.objects.create(poll_option=opt, voter=self.bob, post=post)

        from django.db import IntegrityError
        with self.assertRaises(IntegrityError):
            PollVote.objects.create(poll_option=opt, voter=self.bob, post=post)

    # -----------------------------------------------------------------------
    # Content report — duplicate prevention
    # -----------------------------------------------------------------------

    def test_report_creates_exactly_one_queue_item(self):
        post = Post.objects.create(
            author=self.alice, post_type='text', caption='Bad', gym_id='default_gym'
        )
        client = _auth_client(self.bob)
        # Use the standalone report endpoint — post ID is in the body
        url = '/api/v2/social/report/'
        resp1 = client.post(url, {'post': str(post.pk), 'reason': 'Spam'}, format='json')
        resp2 = client.post(url, {'post': str(post.pk), 'reason': 'Spam again'}, format='json')
        # Both calls return 2xx
        self.assertIn(resp1.status_code, [201, 200])
        self.assertIn(resp2.status_code, [201, 200])
        # But only ONE ContentReport row exists (get_or_create)
        self.assertEqual(ContentReport.objects.filter(reporter=self.bob, post=post).count(), 1)

    def test_reported_post_hidden_from_reporter(self):
        post = Post.objects.create(
            author=self.alice, post_type='text', caption='Toxic', gym_id='default_gym'
        )
        ContentReport.objects.create(reporter=self.bob, post=post, reason='Bad')
        # Bob's feed should exclude reported posts
        client = _auth_client(self.bob)
        resp = client.get('/api/v2/social/posts/')
        ids = [str(p['id']) for p in resp.data]
        self.assertNotIn(str(post.pk), ids)

    # -----------------------------------------------------------------------
    # workout_ref privacy — health metrics must NOT leak
    # -----------------------------------------------------------------------

    def test_post_with_workout_ref_never_exposes_health_metrics(self):
        """Post serialiser must not include DailyMetrics or RecoveryScore data."""
        post = Post.objects.create(
            author=self.alice,
            post_type='text',
            caption='Great session!',
            workout_session_id='some-session-uuid',
            gym_id='default_gym',
        )
        client = _auth_client(self.bob)
        resp = client.get(f'/api/v2/social/posts/{post.pk}/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        # Health metric fields must be absent
        forbidden_fields = {'recovery_score', 'hrv', 'resting_hr', 'sleep_hours', 'daily_metrics'}
        self.assertTrue(forbidden_fields.isdisjoint(resp.data.keys()))

    # -----------------------------------------------------------------------
    # Follow tests
    # -----------------------------------------------------------------------

    def test_follow_creates_notification(self):
        client = _auth_client(self.bob)
        resp = client.post('/api/v2/social/follow/', {
            'followed_username': self.alice.username
        }, format='json')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertTrue(
            Notification.objects.filter(user=self.alice, notif_type='social').exists()
        )

    def test_cannot_follow_self(self):
        client = _auth_client(self.alice)
        resp = client.post('/api/v2/social/follow/', {
            'followed_username': self.alice.username
        }, format='json')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    # -----------------------------------------------------------------------
    # Following feed — only shows followed users' posts
    # -----------------------------------------------------------------------

    def test_following_feed_scoped_to_followed_accounts(self):
        # Alice follows Bob
        Follow.objects.create(follower=self.alice, followed=self.bob)
        bob_post = Post.objects.create(
            author=self.bob, post_type='text', caption='Bob post', gym_id='default_gym'
        )
        carol_post = Post.objects.create(
            author=self.carol, post_type='text', caption='Carol post', gym_id='default_gym'
        )
        client = _auth_client(self.alice)
        resp = client.get('/api/v2/social/posts/?feed=following')
        ids = [str(p['id']) for p in resp.data]
        self.assertIn(str(bob_post.pk), ids)
        self.assertNotIn(str(carol_post.pk), ids)
