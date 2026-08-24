# -*- coding: utf-8 -*-
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class WearableIntegration(models.Model):
    """
    Stores encrypted OAuth2 credentials and connection states for third-party wearable devices.
    Applies encryption-at-rest and strict data isolation per user.
    """
    PROVIDER_CHOICES = [
        ('oura', 'Oura Ring'),
        ('apple_health', 'Apple Health (HealthKit)'),
        ('health_connect', 'Health Connect (Android)'),
    ]

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='wearable_integrations',
    )
    provider = models.CharField(
        max_length=32,
        choices=PROVIDER_CHOICES,
        db_index=True,
    )
    encrypted_access_token = models.TextField(blank=True, default='')
    encrypted_refresh_token = models.TextField(blank=True, default='')
    token_expires_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True, db_index=True)
    last_sync_at = models.DateTimeField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'provider')
        verbose_name = 'Wearable Integration'
        verbose_name_plural = 'Wearable Integrations'

    def __str__(self):
        return f"{self.user.username} - {self.get_provider_display()} ({'Active' if self.is_active else 'Inactive'})"

    def is_expired(self):
        if not self.token_expires_at:
            return False
        return timezone.now() >= self.token_expires_at

    def revoke(self):
        self.is_active = False
        self.encrypted_access_token = ''
        self.encrypted_refresh_token = ''
        self.save(update_fields=['is_active', 'encrypted_access_token', 'encrypted_refresh_token', 'updated_at'])
