# -*- coding: utf-8 -*-
"""
Module 13 — Community / Social Feed Models
Kinetic Precision: Post, Follow, Like, Comment, Poll, ContentReport, Notification
"""
import uuid
from django.db import models
from django.contrib.auth.models import User
from django.core.validators import FileExtensionValidator


# ---------------------------------------------------------------------------
# Post
# ---------------------------------------------------------------------------

class PostType(models.TextChoices):
    TEXT   = 'text',  'Text'
    PHOTO  = 'photo', 'Photo'
    VIDEO  = 'video', 'Video'
    POLL   = 'poll',  'Poll'


class PostTagType(models.TextChoices):
    GENERAL          = 'general',          'General'
    WORKOUT_SHARING  = 'workout_sharing',  'Workout Sharing'
    CLASS_INVITE     = 'class_invite',     'Class Invite'
    TRAINER_INTRO    = 'trainer_intro',    'Trainer Intro'


class PostVisibility(models.TextChoices):
    PUBLIC          = 'public',          'Public'
    FOLLOWERS_ONLY  = 'followers_only',  'Followers Only'
    GYM_ONLY        = 'gym_only',        'Gym Only'


class Post(models.Model):
    """
    A social feed post. post_type controls composition; PostTag is an
    independent facet for feed filtering — the two are never conflated.
    Media URLs are stored as a JSON list of signed-URL strings; raw card data
    or PII is never placed here.
    """
    id          = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    author      = models.ForeignKey(User, on_delete=models.CASCADE, related_name='social_posts')
    gym_id      = models.CharField(max_length=64, default='default_gym', db_index=True,
                                   help_text='Scope posts per gym to avoid cross-gym leakage')
    post_type   = models.CharField(max_length=8, choices=PostType.choices)
    caption     = models.TextField(blank=True, max_length=2000)
    media_urls  = models.JSONField(default=list,
                                   help_text='List of relative media paths, never raw PII')
    # workout_ref intentionally exposes ONLY exercise names when serialised
    workout_session_id = models.CharField(max_length=64, null=True, blank=True,
                                          help_text='FK to WorkoutSession UUID; serialiser must exclude health metrics')
    visibility  = models.CharField(max_length=16, choices=PostVisibility.choices,
                                   default=PostVisibility.GYM_ONLY)
    is_active   = models.BooleanField(default=True, db_index=True)
    created_at  = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes  = [
            models.Index(fields=['gym_id', 'is_active', '-created_at']),
            models.Index(fields=['author', '-created_at']),
        ]

    def __str__(self):
        return f'Post({self.id}) by {self.author.username} [{self.post_type}]'


class PostTag(models.Model):
    """Independent purpose-category facet; separate from post_type."""
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='tags')
    tag  = models.CharField(max_length=24, choices=PostTagType.choices)

    class Meta:
        unique_together = ('post', 'tag')


# ---------------------------------------------------------------------------
# Follow
# ---------------------------------------------------------------------------

class Follow(models.Model):
    follower   = models.ForeignKey(User, on_delete=models.CASCADE, related_name='following')
    followed   = models.ForeignKey(User, on_delete=models.CASCADE, related_name='followers')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('follower', 'followed')
        indexes = [
            models.Index(fields=['follower']),
            models.Index(fields=['followed']),
        ]

    def __str__(self):
        return f'{self.follower.username} → {self.followed.username}'


# ---------------------------------------------------------------------------
# Like
# ---------------------------------------------------------------------------

class Like(models.Model):
    post       = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='likes')
    author     = models.ForeignKey(User, on_delete=models.CASCADE, related_name='liked_posts')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('post', 'author')


# ---------------------------------------------------------------------------
# Comment
# ---------------------------------------------------------------------------

class Comment(models.Model):
    post       = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments')
    author     = models.ForeignKey(User, on_delete=models.CASCADE, related_name='social_comments')
    body       = models.TextField(max_length=1000)
    deleted_at = models.DateTimeField(null=True, blank=True,
                                      help_text='Soft-delete: null = visible')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f'Comment by {self.author.username} on Post({self.post_id})'


# ---------------------------------------------------------------------------
# Poll
# ---------------------------------------------------------------------------

class PollOption(models.Model):
    post     = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='poll_options')
    text     = models.CharField(max_length=200)
    position = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering  = ['position']
        unique_together = ('post', 'position')


class PollVote(models.Model):
    """One vote per user per poll, enforced at DB level via unique_together."""
    poll_option = models.ForeignKey(PollOption, on_delete=models.CASCADE, related_name='votes')
    voter       = models.ForeignKey(User, on_delete=models.CASCADE, related_name='poll_votes')
    post        = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='poll_votes',
                                    help_text='Denormalised for the unique constraint')
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        # DB-level enforcement: one vote per user per poll
        unique_together = ('post', 'voter')


# ---------------------------------------------------------------------------
# Content Moderation
# ---------------------------------------------------------------------------

class ReportStatus(models.TextChoices):
    NEW        = 'new',        'New'
    IN_REVIEW  = 'in_review',  'In Review'
    RESOLVED   = 'resolved',   'Resolved'
    DISMISSED  = 'dismissed',  'Dismissed'


class ContentReport(models.Model):
    """
    Reporter-triggered content flag.  Once created, the post is immediately
    hidden from the reporter (handled in feed queryset), pending admin review.
    """
    reporter    = models.ForeignKey(User, on_delete=models.CASCADE, related_name='content_reports')
    post        = models.ForeignKey(Post, on_delete=models.SET_NULL, null=True, blank=True,
                                    related_name='reports')
    comment     = models.ForeignKey(Comment, on_delete=models.SET_NULL, null=True, blank=True,
                                    related_name='reports')
    reason      = models.CharField(max_length=500)
    status      = models.CharField(max_length=12, choices=ReportStatus.choices,
                                   default=ReportStatus.NEW, db_index=True)
    admin_note  = models.TextField(blank=True)
    created_at  = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']
        # One report per reporter per post — prevents duplicate queue items
        unique_together = ('reporter', 'post')
        indexes = [models.Index(fields=['status', '-created_at'])]

    def __str__(self):
        target = f'Post({self.post_id})' if self.post_id else f'Comment({self.comment_id})'
        return f'Report by {self.reporter.username} on {target} [{self.status}]'


# ---------------------------------------------------------------------------
# Block (user-controlled, no admin involvement)
# ---------------------------------------------------------------------------

class UserBlock(models.Model):
    blocker    = models.ForeignKey(User, on_delete=models.CASCADE, related_name='blocks_made')
    blocked    = models.ForeignKey(User, on_delete=models.CASCADE, related_name='blocked_by')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('blocker', 'blocked')


# ---------------------------------------------------------------------------
# Unified Notification (Modules 13–15)
# ---------------------------------------------------------------------------

class NotificationType(models.TextChoices):
    SOCIAL      = 'social',      'Social'       # follow, like, comment
    ACTIVITY    = 'activity',    'Activity'     # recovery recommendation
    SYNC        = 'sync',        'Sync'         # sync failure/success
    BOOKING     = 'booking',     'Booking'      # class confirmed, waitlist promoted
    ACHIEVEMENT = 'achievement', 'Achievement'  # achievement unlocked


class Notification(models.Model):
    """Single unified notification inbox — filterable by type."""
    id           = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user         = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    notif_type   = models.CharField(max_length=16, choices=NotificationType.choices, db_index=True)
    title        = models.CharField(max_length=200)
    body         = models.TextField(max_length=500)
    entity_type  = models.CharField(max_length=64, blank=True)
    entity_id    = models.CharField(max_length=64, blank=True)
    is_read      = models.BooleanField(default=False, db_index=True)
    created_at   = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ['-created_at']
        indexes  = [
            models.Index(fields=['user', 'is_read', '-created_at']),
            models.Index(fields=['user', 'notif_type', '-created_at']),
        ]

    def __str__(self):
        return f'Notification({self.notif_type}) → {self.user.username}: {self.title}'
