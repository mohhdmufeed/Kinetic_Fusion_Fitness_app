# -*- coding: utf-8 -*-
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class GymOwnerProfile(models.Model):
    """
    Dedicated Gym Owner profile. Requires explicit approval before granting access
    to the Gym Command Center.
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='gym_owner_profile',
    )
    gym_name = models.CharField(max_length=150, help_text="e.g. Kinetic Performance Lab")
    gym_id = models.CharField(max_length=64, default='default_gym', db_index=True)
    is_approved = models.BooleanField(default=False, db_index=True, help_text="Must be approved by operator/verified owner")
    approved_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='approved_owners',
    )
    approved_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Gym Owner Profile'
        verbose_name_plural = 'Gym Owner Profiles'

    def __str__(self):
        status_str = "Approved" if self.is_approved else "Pending Approval"
        return f"{self.user.username} - {self.gym_name} ({status_str})"
