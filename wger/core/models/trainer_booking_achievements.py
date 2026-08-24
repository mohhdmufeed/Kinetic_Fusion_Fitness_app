# -*- coding: utf-8 -*-
"""
Module 14 — Trainer Directory & Session/Class Booking Models
Module 15 — Achievements, Favorites & Home Widgets Models
All in wger.core to reuse existing migrations and app structure.
"""
import uuid
from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator


# =============================================================================
# MODULE 14 — TRAINER DIRECTORY & BOOKING
# =============================================================================

class TrainerProfile(models.Model):
    """
    Trainer identity card. Status (is_accepting_bookings) is managed by the
    gym owner via Module 12 Command Center — never self-granted.
    """
    user                = models.OneToOneField(User, on_delete=models.CASCADE,
                                               related_name='trainer_profile')
    gym_id              = models.CharField(max_length=64, default='default_gym', db_index=True)
    bio                 = models.TextField(max_length=2000, blank=True)
    specialties         = models.JSONField(default=list,
                                           help_text='List of specialty strings')
    certifications      = models.JSONField(default=list,
                                           help_text='List of certification strings')
    media_urls          = models.JSONField(default=list,
                                           help_text='Profile/banner image relative paths')
    is_accepting_bookings = models.BooleanField(default=False,
                                                help_text='Set by gym owner, not self')
    created_at          = models.DateTimeField(auto_now_add=True)
    updated_at          = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['user__username']

    def __str__(self):
        return f'Trainer: {self.user.username} @ gym={self.gym_id}'


class ClassStatus(models.TextChoices):
    SCHEDULED = 'scheduled', 'Scheduled'
    CANCELLED = 'cancelled', 'Cancelled'
    COMPLETED = 'completed', 'Completed'


class GroupClass(models.Model):
    """
    An instructor-led group fitness class. `capacity` is authoritative;
    `seats_reserved` is NEVER stored — always derived live from
    COUNT(Booking WHERE class_ref=self AND status='booked').
    GPS coordinates are real device coordinates — never mocked.
    """
    trainer         = models.ForeignKey(TrainerProfile, on_delete=models.CASCADE,
                                        related_name='group_classes')
    gym_id          = models.CharField(max_length=64, default='default_gym', db_index=True)
    title           = models.CharField(max_length=200)
    description     = models.TextField(max_length=1000, blank=True)
    start_time      = models.DateTimeField(db_index=True)
    end_time        = models.DateTimeField()
    capacity        = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    venue_name      = models.CharField(max_length=200, blank=True)
    venue_lat       = models.FloatField(null=True, blank=True,
                                        help_text='Real GPS latitude — never mocked')
    venue_lng       = models.FloatField(null=True, blank=True,
                                        help_text='Real GPS longitude — never mocked')
    is_online       = models.BooleanField(default=False)
    recurrence_rule = models.CharField(max_length=200, blank=True,
                                        help_text='RRULE string for recurring classes')
    status          = models.CharField(max_length=12, choices=ClassStatus.choices,
                                       default=ClassStatus.SCHEDULED, db_index=True)
    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['start_time']
        indexes  = [
            models.Index(fields=['gym_id', 'status', 'start_time']),
        ]

    def seats_available(self):
        """Live computation — never cached to prevent over-booking."""
        booked = self.bookings.filter(status=BookingStatus.BOOKED).count()
        return max(0, self.capacity - booked)

    def __str__(self):
        return f'GroupClass: {self.title} @ {self.start_time}'


class SessionType(models.TextChoices):
    ONLINE_WORKOUT          = 'online_workout',          'Online Workout'
    NUTRITION_CONSULTATION  = 'nutrition_consultation',  'Nutrition Consultation'


class SessionStatus(models.TextChoices):
    REQUESTED  = 'requested',  'Requested'
    CONFIRMED  = 'confirmed',  'Confirmed'
    COMPLETED  = 'completed',  'Completed'
    CANCELLED  = 'cancelled',  'Cancelled'


class PrivateSession(models.Model):
    """
    One-to-one trainer/client booking. payment_ref is an opaque token from
    the payment provider — raw card data is never stored here.
    """
    trainer         = models.ForeignKey(TrainerProfile, on_delete=models.CASCADE,
                                        related_name='private_sessions')
    client          = models.ForeignKey(User, on_delete=models.CASCADE,
                                        related_name='private_sessions')
    session_type    = models.CharField(max_length=32, choices=SessionType.choices)
    requested_time  = models.DateTimeField()
    status          = models.CharField(max_length=12, choices=SessionStatus.choices,
                                       default=SessionStatus.REQUESTED)
    payment_ref     = models.CharField(max_length=200, blank=True,
                                       help_text='Opaque payment-provider token — never raw card data')
    notes           = models.TextField(max_length=1000, blank=True)
    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'PrivateSession: {self.client.username} with {self.trainer.user.username}'


class BookingStatus(models.TextChoices):
    BOOKED      = 'booked',      'Booked'
    WAITLISTED  = 'waitlisted',  'Waitlisted'
    CANCELLED   = 'cancelled',   'Cancelled'


class Booking(models.Model):
    """
    Joins a user to a GroupClass OR a PrivateSession (exactly one must be set).
    unique_together(class_ref, user) prevents double-booking.
    Capacity enforcement uses SELECT FOR UPDATE inside a transaction — never
    read-modify-write in application code.
    """
    id               = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user             = models.ForeignKey(User, on_delete=models.CASCADE, related_name='bookings')
    class_ref        = models.ForeignKey(GroupClass, on_delete=models.CASCADE,
                                         related_name='bookings', null=True, blank=True)
    private_session  = models.ForeignKey(PrivateSession, on_delete=models.CASCADE,
                                         related_name='bookings', null=True, blank=True)
    status           = models.CharField(max_length=12, choices=BookingStatus.choices,
                                        default=BookingStatus.BOOKED, db_index=True)
    waitlist_position = models.PositiveIntegerField(null=True, blank=True,
                                                    help_text='Null when status=booked')
    created_at       = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']
        constraints = [
            # Exactly one of class_ref / private_session must be set
            models.CheckConstraint(
                name='booking_exactly_one_ref',
                condition=(
                    models.Q(class_ref__isnull=False, private_session__isnull=True) |
                    models.Q(class_ref__isnull=True, private_session__isnull=False)
                ),
            ),
        ]
        unique_together = [('class_ref', 'user')]  # prevents double-booking same class

    def __str__(self):
        target = self.class_ref or self.private_session
        return f'Booking: {self.user.username} → {target} [{self.status}]'


# =============================================================================
# MODULE 15 — ACHIEVEMENTS, FAVORITES & HOME WIDGETS
# =============================================================================

class AchievementRuleType(models.TextChoices):
    WORKOUT_COUNT   = 'workout_count',   'Workout Count'
    STREAK_DAYS     = 'streak_days',     'Streak Days'
    BENCHMARK_HIT   = 'benchmark_hit',   'Benchmark Hit'
    CLASS_ATTENDED  = 'class_attended',  'Class Attended'
    NUTRITION_STREAK = 'nutrition_streak', 'Nutrition Streak'
    BODY_GOAL       = 'body_goal',       'Body Goal'


class Achievement(models.Model):
    """
    Rule definitions live in code/config — not free text — so they're testable.
    Only background Celery task writes UserAchievement; client POSTs return 403.
    """
    code        = models.SlugField(max_length=80, unique=True,
                                   help_text='Stable slug; changing this breaks existing UserAchievements')
    title       = models.CharField(max_length=200)
    description = models.TextField(max_length=500)
    rule_type   = models.CharField(max_length=24, choices=AchievementRuleType.choices)
    threshold   = models.PositiveIntegerField(default=1,
                                              help_text='e.g. 10 workouts, 7-day streak, etc.')
    icon_url    = models.CharField(max_length=300, blank=True)
    is_active   = models.BooleanField(default=True)

    class Meta:
        ordering = ['rule_type', 'threshold']

    def __str__(self):
        return f'Achievement: {self.title} ({self.code})'


class UserAchievement(models.Model):
    """
    Written ONLY by the background evaluate_achievements Celery task.
    Any direct client POST to create this is rejected at the view layer.
    """
    user          = models.ForeignKey(User, on_delete=models.CASCADE,
                                      related_name='achievements')
    achievement   = models.ForeignKey(Achievement, on_delete=models.CASCADE,
                                      related_name='user_achievements')
    unlocked_at   = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'achievement')
        ordering = ['-unlocked_at']

    def __str__(self):
        return f'{self.user.username} unlocked {self.achievement.code}'


class FavoriteEntityType(models.TextChoices):
    WORKOUT  = 'workout',  'Workout'
    PROGRAM  = 'program',  'Program'
    EXERCISE = 'exercise', 'Exercise'
    TRAINER  = 'trainer',  'Trainer'


class Favorite(models.Model):
    """
    Unified favorites table — same endpoint shape for all entity types.
    entity_id is a string to accommodate UUID-PKs across different models.
    """
    user        = models.ForeignKey(User, on_delete=models.CASCADE, related_name='favorites')
    entity_type = models.CharField(max_length=12, choices=FavoriteEntityType.choices)
    entity_id   = models.CharField(max_length=64,
                                   help_text='UUID or PK string of the favorited entity')
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'entity_type', 'entity_id')
        ordering = ['-created_at']
        indexes  = [
            models.Index(fields=['user', 'entity_type']),
        ]

    def __str__(self):
        return f'{self.user.username} ❤ {self.entity_type}:{self.entity_id}'


class WidgetType(models.TextChoices):
    RECOVERY_SCORE  = 'recovery_score',  'Recovery Score'
    NEXT_CLASS      = 'next_class',      'Next Class'
    STREAK          = 'streak',          'Streak'
    WEEKLY_VOLUME   = 'weekly_volume',   'Weekly Volume'
    STEPS           = 'steps',           'Steps'
    SLEEP           = 'sleep',           'Sleep'
    WEIGHT          = 'weight',          'Weight'
    TRAINING_LOAD   = 'training_load',   'Training Load'


class HomeWidget(models.Model):
    """
    User-configurable Home screen widget grid.  Reorder uses the same atomic
    full-replace pattern as Module 12 ProgramExercise reorder — never
    sequential individual move operations.
    """
    user        = models.ForeignKey(User, on_delete=models.CASCADE, related_name='home_widgets')
    widget_type = models.CharField(max_length=24, choices=WidgetType.choices)
    position    = models.PositiveSmallIntegerField(default=0,
                                                   help_text='Explicit position; never inferred from array index')
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'widget_type')
        ordering = ['position']
        indexes  = [
            models.Index(fields=['user', 'position']),
        ]

    def __str__(self):
        return f'Widget({self.widget_type}) pos={self.position} for {self.user.username}'
