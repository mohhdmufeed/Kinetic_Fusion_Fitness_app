# -*- coding: utf-8 -*-
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class SyncChangeLog(models.Model):
    """
    Unified Server-Authoritative ChangeLog for Kinetic Precision.
    Every syncable write in the system — online or offline-originated — becomes one row in this log.
    """
    id = models.BigAutoField(primary_key=True)          # monotonic cursor for pull
    entity_type = models.CharField(max_length=64)        # e.g. "WorkoutSession", "DiaryEntry", "BodyStatEntry", "ProgramSchedule"
    entity_id = models.CharField(max_length=64)           # target row's UUID/PK
    op = models.CharField(max_length=8, choices=[
        ("create", "Create"),
        ("update", "Update"),
        ("delete", "Delete"),
    ])                                                     # enum, never a free string
    payload = models.JSONField(default=dict)              # full entity state for create/update
    actor = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sync_changelogs',
    )                                                      # who made the change — required for ownership & audit
    client_id = models.CharField(max_length=64, null=True, blank=True)  # device/client that originated change
    client_version = models.IntegerField(null=True, blank=True)         # entity version client thought it was editing
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    processed = models.BooleanField(default=False, db_index=True)
    retry_count = models.IntegerField(default=0)
    error = models.TextField(null=True, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=["entity_type", "entity_id", "created_at"]),
            models.Index(fields=["processed", "created_at"]),
            models.Index(fields=["id", "created_at"]),
        ]
        ordering = ['id']
        verbose_name = 'Sync Change Log'
        verbose_name_plural = 'Sync Change Logs'

    def __str__(self):
        return f"ChangeLog #{self.id}: {self.op} {self.entity_type}:{self.entity_id} by {self.actor.username}"


class SyncLog(models.Model):
    """
    Records device synchronization sessions for telemetry, conflict analysis, and admin observability.
    """
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sync_logs',
    )
    timestamp = models.DateTimeField(default=timezone.now, db_index=True)
    items_pushed = models.IntegerField(default=0)
    items_pulled = models.IntegerField(default=0)
    status = models.CharField(max_length=32, default='success')
    device_id = models.CharField(max_length=128, blank=True, default='')
    client_version = models.CharField(max_length=32, blank=True, default='')
    details = models.TextField(blank=True, default='')

    class Meta:
        ordering = ['-timestamp']
        verbose_name = 'Sync Log'
        verbose_name_plural = 'Sync Logs'

    def __str__(self):
        return f"SyncLog({self.user.username} @ {self.timestamp.strftime('%Y-%m-%d %H:%M:%S')} - Pushed: {self.items_pushed}, Pulled: {self.items_pulled})"


class GymClass(models.Model):
    """
    Demonstration model for concurrent booking with capacity guard.
    """
    name = models.CharField(max_length=120)
    capacity = models.IntegerField(default=20)
    seats_reserved = models.IntegerField(default=0)
    version = models.IntegerField(default=1)
    tombstone = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Gym Class'
        verbose_name_plural = 'Gym Classes'

    def __str__(self):
        return f"{self.name} ({self.seats_reserved}/{self.capacity} seats)"


class GymClassBooking(models.Model):
    """
    Booking entity for GymClass, tracking client reservations.
    """
    client_uuid = models.CharField(max_length=64, unique=True, db_index=True)
    gym_class = models.ForeignKey(GymClass, on_delete=models.CASCADE, related_name='bookings')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='class_bookings')
    version = models.IntegerField(default=1)
    tombstone = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Gym Class Booking'
        verbose_name_plural = 'Gym Class Bookings'

    def __str__(self):
        return f"Booking {self.client_uuid} for {self.user.username} - {self.gym_class.name}"
