# -*- coding: utf-8 -*-

# This file is part of wger Workout Manager.
#
# wger Workout Manager is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# wger Workout Manager is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Workout Manager.  If not, see <http://www.gnu.org/licenses/>.

# Third Party
from rest_framework import permissions


class WgerPermission(permissions.BasePermission):
    """
    Checks that the requesting user strictly owns the target object or has safe global access.
    """

    def has_permission(self, request, view):
        if hasattr(view, 'is_private') and view.is_private:
            return request.user and request.user.is_authenticated
        return request.user and request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        if not request.user or not request.user.is_authenticated:
            return False

        # Direct user ownership
        if hasattr(obj, 'user') and obj.user == request.user:
            return True

        # Owner object delegation
        if hasattr(obj, 'get_owner_object'):
            owner = obj.get_owner_object()
            if owner:
                if hasattr(owner, 'user') and owner.user == request.user:
                    return True
                if owner == request.user:
                    return True

        # Safe methods on global/shared objects only
        is_global = not hasattr(obj, 'user') and not hasattr(obj, 'get_owner_object')
        if is_global and request.method in permissions.SAFE_METHODS:
            return True

        return False


class IsStrictOwner(permissions.BasePermission):
    """
    Strict object-level permission: allows access ONLY if the object belongs to the request.user.
    """
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated)

    def has_object_permission(self, request, view, obj):
        if not request.user or not request.user.is_authenticated:
            return False
        if hasattr(obj, 'user'):
            return obj.user == request.user
        if hasattr(obj, 'get_owner_object'):
            owner = obj.get_owner_object()
            if hasattr(owner, 'user'):
                return owner.user == request.user
            return owner == request.user
        return False


class CreateOnlyPermission(permissions.BasePermission):
    """
    Custom permission that permits read access the resource but limits the
    write operations to creating (POSTing) new objects only and does not
    allow editing them. This is currently used for exercises and their
    images.
    """

    def has_permission(self, request, view):
        return request.method in ['GET', 'HEAD', 'OPTIONS'] or (
            request.user and request.user.is_authenticated and request.method == 'POST'
        )


class UpdateOnlyPermission(permissions.BasePermission):
    """
    Custom permission that restricts write operations to PATCH. This is currently
    used for the user profile.
    """

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.method in ['GET', 'HEAD', 'OPTIONS', 'PATCH']
        )
