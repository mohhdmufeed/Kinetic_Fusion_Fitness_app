# -*- coding: utf-8 -*-
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class FeedbackReport(models.Model):
    """
    Athlete in-app feedback, bug reports, and feature requests.
    Supports auto-attached client device telemetry, offline sync outbox ingestion,
    and admin replies.
    """
    CATEGORY_CHOICES = (
        ('bug', 'Bug Report'),
        ('feature_request', 'Feature Request / Suggestion'),
        ('exercise', 'Exercise / Routine Request'),
        ('general', 'General Feedback'),
    )

    STATUS_CHOICES = (
        ('new', 'New'),
        ('in_review', 'In Review'),
        ('resolved', 'Resolved'),
        ('wontfix', 'Won\'t Fix'),
    )

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='feedback_reports',
    )
    category = models.CharField(
        max_length=32,
        choices=CATEGORY_CHOICES,
        default='general',
        db_index=True,
    )
    rating = models.IntegerField(default=5)
    message = models.TextField()
    device_metadata = models.JSONField(
        default=dict,
        blank=True,
        help_text="Sanitized client environment telemetry (app_version, os_version, device_model). Never credentials."
    )
    status = models.CharField(
        max_length=32,
        choices=STATUS_CHOICES,
        default='new',
        db_index=True,
    )
    admin_reply = models.TextField(blank=True, default='')
    admin_replied_by = models.ForeignKey(
        User,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='replied_feedbacks',
    )
    created_at = models.DateTimeField(default=timezone.now, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Feedback Report'
        verbose_name_plural = 'Feedback Reports'

    def __str__(self):
        return f"FeedbackReport(#{self.id} [{self.category}] by {self.user.username} - Status: {self.status})"
