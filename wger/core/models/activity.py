# -*- coding: utf-8 -*-
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class ActivityLog(models.Model):
    """
    Ingested real-world physical activity, GPS routes, and step count telemetry.
    """
    ACTIVITY_TYPES = (
        ('running', 'Outdoor Running'),
        ('walking', 'Walking / Hiking'),
        ('cycling', 'Cycling'),
        ('general_steps', 'Daily Passive Steps'),
    )

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='activity_logs',
    )
    activity_type = models.CharField(
        max_length=32,
        choices=ACTIVITY_TYPES,
        default='general_steps',
        db_index=True,
    )
    start_time = models.DateTimeField(default=timezone.now, db_index=True)
    end_time = models.DateTimeField(null=True, blank=True)
    distance_meters = models.FloatField(default=0.0, help_text="Total GPS distance covered in meters")
    step_count = models.IntegerField(default=0, help_text="Total pedometer steps recorded")
    avg_pace_min_per_km = models.FloatField(default=0.0, help_text="Average pace in minutes per km")
    calories_burned = models.FloatField(default=0.0, help_text="Estimated active calories burned (kcal)")
    route_geojson = models.JSONField(
        default=dict,
        blank=True,
        help_text="GeoJSON LineString or list of [lat, lng, altitude, timestamp] coordinates"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-start_time']
        verbose_name = 'Activity Log'
        verbose_name_plural = 'Activity Logs'

    def __str__(self):
        return f"ActivityLog({self.user.username} - {self.activity_type}: {self.step_count} steps, {self.distance_meters/1000.0:.2f}km)"
