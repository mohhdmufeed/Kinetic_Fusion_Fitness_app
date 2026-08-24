# -*- coding: utf-8 -*-
from django.core.exceptions import PermissionDenied


def create_temporary_user(request=None):
    """
    Guest and anonymous access is disabled in Kinetic Precision.
    """
    raise PermissionDenied("Guest and temporary user creation is disabled.")


def create_demo_entries(user):
    """
    Demo data generation for guest users is disabled.
    """
    raise PermissionDenied("Demo data generation is disabled.")
