# -*- coding: utf-8 -*-
from django.db import models
from django.contrib.auth.models import User
from django.core.exceptions import PermissionDenied
from django.utils import timezone


class AdminProfile(models.Model):
    """
    Dedicated admin profile required for staff members to access the administrative tier.
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='admin_profile',
    )
    can_access_admin = models.BooleanField(
        default=False,
        help_text="Explicit authorization flag required for admin API and console access.",
    )
    totp_secret = models.CharField(
        max_length=64,
        blank=True,
        default='',
        help_text="Base32 encoded TOTP secret for mandatory two-factor authentication.",
    )
    is_totp_verified = models.BooleanField(
        default=False,
        help_text="Whether 2FA device has been enrolled and verified.",
    )
    role = models.CharField(
        max_length=32,
        default='superadmin',
        choices=(
            ('superadmin', 'Super Admin / Gym Owner'),
            ('staff_coach', 'Staff Coach'),
            ('auditor', 'Security Auditor'),
        ),
    )
    created_at = models.DateTimeField(auto_now_add=True)
    last_admin_login = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"AdminProfile({self.user.username} - {self.role} - Access: {self.can_access_admin})"


class AdminAuditLog(models.Model):
    """
    Immutable, append-only security audit log recording every admin action, login attempt,
    suspension, soft-deletion, and configuration change with full before/after diffs.
    """
    timestamp = models.DateTimeField(default=timezone.now, db_index=True, editable=False)
    admin_user = models.ForeignKey(
        User,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='admin_audit_logs',
        editable=False,
    )
    action = models.CharField(max_length=64, db_index=True, editable=False)
    target_model = models.CharField(max_length=64, blank=True, default='', editable=False)
    target_id = models.CharField(max_length=64, blank=True, default='', editable=False)
    ip_address = models.GenericIPAddressField(null=True, blank=True, editable=False)
    user_agent = models.TextField(blank=True, default='', editable=False)
    before_state = models.JSONField(default=dict, blank=True, editable=False)
    after_state = models.JSONField(default=dict, blank=True, editable=False)
    details = models.TextField(blank=True, default='', editable=False)

    class Meta:
        ordering = ['-timestamp']
        verbose_name = 'Admin Audit Log'
        verbose_name_plural = 'Admin Audit Logs'

    def save(self, *args, **kwargs):
        # Enforce append-only immutability
        if self.pk:
            raise PermissionDenied("AdminAuditLog records are append-only and cannot be modified.")
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        # Enforce append-only immutability
        raise PermissionDenied("AdminAuditLog records are permanent and cannot be deleted.")

    def __str__(self):
        user_repr = self.admin_user.username if self.admin_user else "System/Anon"
        return f"[{self.timestamp.strftime('%Y-%m-%d %H:%M:%S')}] {user_repr} -> {self.action} (Target: {self.target_model}:{self.target_id})"
