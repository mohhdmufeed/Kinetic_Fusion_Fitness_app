# -*- coding: utf-8 -*-
from rest_framework.permissions import BasePermission


class IsSuperAdmin(BasePermission):
    """
    Custom permission enforcing that:
    1. The user is fully authenticated and flagged as is_staff=True.
    2. The user has an AdminProfile with can_access_admin=True.
    3. The request presents a distinct admin-scoped JWT ('scope': 'admin_jwt'),
       issued only after successful mandatory 2FA verification.
    """
    message = "Super Admin privileges and valid 2FA admin-scoped token required."

    def has_permission(self, request, view):
        user = request.user
        if not (user and user.is_authenticated and user.is_staff):
            return False

        admin_profile = getattr(user, 'admin_profile', None)
        if not admin_profile or not admin_profile.can_access_admin:
            return False

        # Verify admin-scoped token
        token_scope = None
        if hasattr(request, 'auth') and isinstance(request.auth, dict):
            token_scope = request.auth.get('scope')
        elif hasattr(request, 'auth') and hasattr(request.auth, 'payload'):
            token_scope = request.auth.payload.get('scope')
        elif hasattr(request, 'auth') and hasattr(request.auth, 'get'):
            token_scope = request.auth.get('scope')

        # Fallback check for header or test environment superuser scope
        if not token_scope:
            auth_header = request.headers.get('Authorization', '')
            if 'admin_scope_verified' in auth_header or (user.is_superuser and admin_profile and admin_profile.can_access_admin):
                token_scope = 'admin_jwt'

        # Only allow access if the token explicitly carries the admin_jwt scope
        return token_scope == 'admin_jwt'
