# -*- coding: utf-8 -*-
from datetime import timedelta
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone

from wger.exercises.models import Exercise


class ProgramSchedule(models.Model):
    """
    Versioned multi-day workout program created by a trainer/admin.
    """
    name = models.CharField(max_length=200, help_text="e.g. 5-Day Hypertrophy Split")
    description = models.TextField(blank=True)
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='authored_programs',
    )
    version = models.IntegerField(default=1, help_text="Version integer to prevent rewriting mid-program history")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Program Schedule'
        verbose_name_plural = 'Program Schedules'

    def __str__(self):
        return f"{self.name} (v{self.version})"


class ProgramDay(models.Model):
    """
    A specific day in a multi-day program (e.g. Day 1: Push, Day 2: Pull).
    Explicit order integer field for drag-and-drop reordering.
    """
    schedule = models.ForeignKey(
        ProgramSchedule,
        on_delete=models.CASCADE,
        related_name='days',
    )
    day_number = models.IntegerField(help_text="Day index (1, 2, 3, 4, 5, etc.)")
    label = models.CharField(max_length=150, help_text="e.g. Day 1 - Push (Chest, Shoulders, Triceps)")
    order = models.IntegerField(default=0, help_text="Explicit sequence position")

    class Meta:
        ordering = ['order', 'day_number']
        unique_together = ('schedule', 'day_number')
        verbose_name = 'Program Day'
        verbose_name_plural = 'Program Days'

    def __str__(self):
        return f"{self.schedule.name} - Day {self.day_number}: {self.label}"


class ProgramExercise(models.Model):
    """
    An exercise linked to a program day with weight-based prescription in canonical kg.
    """
    TECHNIQUE_CHOICES = (
        ('normal', 'Normal Straight Sets'),
        ('superset', 'Superset'),
        ('drop_set', 'Drop Set'),
        ('max', 'Max Effort (1-3RM)'),
        ('amrap', 'AMRAP (As Many Reps As Possible)'),
    )

    program_day = models.ForeignKey(
        ProgramDay,
        on_delete=models.CASCADE,
        related_name='exercises',
    )
    exercise = models.ForeignKey(
        Exercise,
        on_delete=models.CASCADE,
        related_name='program_prescriptions',
        help_text="Strict foreign key to shared Exercise Library",
    )
    exercise_name = models.CharField(max_length=200, blank=True)
    target_muscle = models.CharField(max_length=100, blank=True, help_text="Derived from linked exercise")
    sets = models.IntegerField(default=3)
    reps = models.CharField(max_length=32, default="8-12", help_text="e.g. '8-12', '5', 'AMRAP'")
    target_weight_kg = models.FloatField(default=0.0, help_text="Canonical weight-based prescription in kilograms")
    technique = models.CharField(max_length=32, choices=TECHNIQUE_CHOICES, default='normal')
    rest_seconds = models.IntegerField(default=90, help_text="Prescribed rest interval in seconds")
    order = models.IntegerField(default=0, help_text="Explicit sequence position")

    class Meta:
        ordering = ['order', 'id']
        verbose_name = 'Program Exercise'
        verbose_name_plural = 'Program Exercises'

    def save(self, *args, **kwargs):
        if self.exercise:
            self.exercise_name = getattr(self.exercise, 'name', None) or str(self.exercise)
            if hasattr(self.exercise, 'category') and self.exercise.category:
                self.target_muscle = str(getattr(self.exercise.category, 'name', ''))
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.program_day} - {self.exercise_name} ({self.sets}x{self.reps}, {self.technique})"


class ClientMembership(models.Model):
    """
    Gym member profile with live computed days_remaining and active program assignment.
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='membership',
    )
    phone_number = models.CharField(max_length=32, blank=True, default='')
    membership_start_date = models.DateField(default=timezone.now)
    membership_end_date = models.DateField(default=timezone.now)
    assigned_trainer = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='trained_clients',
    )
    active_program = models.ForeignKey(
        ProgramSchedule,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='enrolled_clients',
    )
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['membership_end_date']
        verbose_name = 'Client Membership'
        verbose_name_plural = 'Client Memberships'

    @property
    def days_remaining(self) -> int:
        """
        Computed live against the current real date (end_date - today).
        Negative values accurately denote expired/lapsed memberships (e.g. -10 days).
        """
        today = timezone.now().date()
        return (self.membership_end_date - today).days

    @property
    def membership_duration_days(self) -> int:
        """Total duration in days of the membership cycle."""
        return max(0, (self.membership_end_date - self.membership_start_date).days)

    def __str__(self):
        return f"{self.user.get_full_name() or self.user.username} ({self.days_remaining}d remaining)"


class BodyStatEntry(models.Model):
    """
    Circumference and body composition history recorded during in-person check-ins or self-logged.
    Historical records are immutable (append-only) to guarantee auditability.
    """
    RECORDED_BY_CHOICES = (
        ('admin', 'Gym Owner / Trainer In-Person Check-In'),
        ('client_self', 'Athlete Self-Logged'),
    )

    client = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='body_stat_entries',
    )
    recorded_date = models.DateField(default=timezone.now, db_index=True)
    recorded_by_type = models.CharField(
        max_length=32,
        choices=RECORDED_BY_CHOICES,
        default='admin',
        db_index=True,
    )
    recorded_by_user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='recorded_body_stats',
    )
    height_cm = models.FloatField(null=True, blank=True)
    weight_kg = models.FloatField(null=True, blank=True)
    shoulder_cm = models.FloatField(null=True, blank=True)
    chest_cm = models.FloatField(null=True, blank=True)
    arm_cm = models.FloatField(null=True, blank=True)
    waist_cm = models.FloatField(null=True, blank=True)
    hip_cm = models.FloatField(null=True, blank=True)
    thigh_cm = models.FloatField(null=True, blank=True)
    calf_cm = models.FloatField(null=True, blank=True)
    note = models.TextField(blank=True, help_text="Açıklama / Context description e.g. 'Before starting program'")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-recorded_date', '-created_at']
        verbose_name = 'Body Stat Entry'
        verbose_name_plural = 'Body Stat Entries'

    def __str__(self):
        return f"{self.client.username} BodyStats ({self.recorded_date}): {self.weight_kg}kg, waist: {self.waist_cm}cm ({self.recorded_by_type})"
