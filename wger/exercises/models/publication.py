# -*- coding: utf-8 -*-
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class ExercisePublicationState(models.Model):
    """
    Lifecycle governance and curation state for exercises:
    draft -> in_review (community suggestion) -> published -> archived.
    """
    STATUS_CHOICES = (
        ('draft', 'Draft'),
        ('in_review', 'In Review / Community Suggestion'),
        ('published', 'Published'),
        ('archived', 'Archived / Deactivated'),
    )

    exercise = models.OneToOneField(
        'exercises.Exercise',
        on_delete=models.CASCADE,
        related_name='publication_state',
    )
    status = models.CharField(
        max_length=32,
        choices=STATUS_CHOICES,
        default='published',
        db_index=True,
    )
    author = models.ForeignKey(
        User,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='authored_exercises',
    )
    reviewed_by = models.ForeignKey(
        User,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='reviewed_exercises',
    )
    default_sets = models.IntegerField(default=3)
    default_reps = models.IntegerField(default=10)
    video_url = models.URLField(blank=True, default='')
    admin_notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    published_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Exercise Publication State'
        verbose_name_plural = 'Exercise Publication States'

    def __str__(self):
        return f"ExercisePublicationState({self.exercise_id} - {self.status})"


class UserExerciseFavorite(models.Model):
    """
    Per-user favorite pinned exercises for instant access.
    """
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='exercise_favorites',
    )
    exercise = models.ForeignKey(
        'exercises.Exercise',
        on_delete=models.CASCADE,
        related_name='favorited_by',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'exercise')
        ordering = ['-created_at']
        verbose_name = 'User Exercise Favorite'
        verbose_name_plural = 'User Exercise Favorites'

    def __str__(self):
        return f"{self.user.username} favorited Exercise #{self.exercise_id}"


class ExerciseLibraryMetadata(models.Model):
    """
    Singleton storing the monotonic library_version counter for local cache invalidation.
    """
    current_version = models.IntegerField(default=1)
    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Exercise Library Metadata'
        verbose_name_plural = 'Exercise Library Metadata'

    @classmethod
    def get_current_version(cls) -> int:
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj.current_version

    @classmethod
    def bump_version(cls) -> int:
        obj, _ = cls.objects.get_or_create(pk=1)
        obj.current_version += 1
        obj.save()
        return obj.current_version
