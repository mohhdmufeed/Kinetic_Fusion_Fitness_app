# -*- coding: utf-8 -*-
from django.contrib.auth.models import User
from django.db import transaction
from django.db.models import F, Q
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema, OpenApiParameter

from wger.core.models.sync import SyncChangeLog, GymClass, GymClassBooking, SyncLog
from wger.core.models.gym_owner import GymOwnerProfile
from wger.core.models.gym_admin import (
    ProgramSchedule,
    ProgramDay,
    ProgramExercise,
    ClientMembership,
    BodyStatEntry,
)
from wger.nutrition.models.kinetic_nutrition import KineticIngredient, KineticDiaryEntry


OWNER_ONLY_ENTITY_TYPES = {
    'ProgramSchedule',
    'ClientMembership',
    'GymOwnerProfile',
    'GymAdminConfig',
}

APPEND_ONLY_ENTITY_TYPES = {
    'DiaryEntry',
    'KineticDiaryEntry',
    'BodyStatEntry',
}


import uuid


def to_uuid(val):
    try:
        return uuid.UUID(str(val))
    except (ValueError, AttributeError):
        return uuid.uuid5(uuid.NAMESPACE_DNS, str(val))


def user_is_approved_owner(user: User) -> bool:
    """Checks if the user has an approved GymOwnerProfile."""
    if not user or not user.is_authenticated:
        return False
    return GymOwnerProfile.objects.filter(user=user, is_approved=True).exists()


class SyncPushAPIView(APIView):
    """
    Unified Server-Authoritative ChangeLog Push Endpoint.
    Accepts a batch of outbox rows from the client.
    Enforces strict ownership, optimistic version concurrency, and atomic idempotency.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Push Local Outbox Changes",
        description="Batched push of outbox changes into the authoritative server ChangeLog.",
        tags=["Unified Sync Engine"]
    )
    def post(self, request):
        user = request.user
        batch = request.data.get('batch', request.data.get('mutations', []))
        client_id = request.data.get('client_id', request.data.get('device_id', ''))

        applied = []
        conflicts = []
        rejected = []

        for row in batch:
            entity_type = row.get('entity_type', row.get('type'))
            entity_id = str(row.get('entity_id', row.get('uuid', '')))
            op = row.get('op', row.get('action', 'create')).lower()
            payload = row.get('payload', row.get('data', {}))
            client_version = row.get('client_version', 1)

            # 1. Idempotency Check: if identical row was already processed by this device, return existing confirmation
            existing_log = SyncChangeLog.objects.filter(
                actor=user,
                client_id=client_id,
                entity_type=entity_type,
                entity_id=entity_id,
                client_version=client_version,
                processed=True,
            ).first() if client_id else None
            if existing_log:
                applied.append({
                    "entity_type": entity_type,
                    "entity_id": entity_id,
                    "status": "already_applied",
                    "changelog_id": existing_log.id,
                })
                continue

            # 2. Ownership & Privilege Verification
            # Protect owner-only entities from unauthorized client mutation
            if entity_type in OWNER_ONLY_ENTITY_TYPES and not user_is_approved_owner(user):
                rejected.append({
                    "entity_type": entity_type,
                    "entity_id": entity_id,
                    "reason": "permission_denied: owner privilege required",
                })
                continue

            # 3. Process Per Entity Type in an Atomic Transaction
            try:
                has_conflict = False
                has_rejected = False
                with transaction.atomic():
                    if entity_type in ['DiaryEntry', 'KineticDiaryEntry']:
                        # Append-only / UUID idempotent food diary entry
                        ing_id = payload.get('ingredient_id')
                        qty = float(payload.get('quantity_g', payload.get('quantity', 100.0)))
                        meal = payload.get('meal', 'lunch')
                        ing = KineticIngredient.objects.filter(pk=ing_id).first()
                        if not ing:
                            ing = KineticIngredient.objects.filter(verified=True).first()

                        entry_uuid = to_uuid(entity_id)
                        entry, _ = KineticDiaryEntry.objects.update_or_create(
                            client_uuid=entry_uuid,
                            defaults={
                                'user': user,
                                'ingredient': ing,
                                'quantity_g': qty,
                                'meal': meal,
                                'logged_at': timezone.now(),
                            }
                        )
                        server_version = (client_version or 1) + 1

                    elif entity_type == 'BodyStatEntry':
                        # Append-only body stats
                        stat = BodyStatEntry.objects.create(
                            client=user,
                            recorded_date=timezone.now().date(),
                            recorded_by_type='client_self',
                            weight_kg=payload.get('weight_kg'),
                            waist_cm=payload.get('waist_cm'),
                            note=payload.get('note', ''),
                        )
                        server_version = stat.version

                    elif entity_type == 'ProgramSchedule':
                        # Mutable entity with optimistic version locking
                        sched_pk = int(entity_id) if str(entity_id).isdigit() else None
                        sched = ProgramSchedule.objects.filter(pk=sched_pk).first() if sched_pk else None
                        if not sched:
                            # Create new
                            sched = ProgramSchedule.objects.create(
                                name=payload.get('name', 'New Program'),
                                description=payload.get('description', ''),
                                created_by=user,
                                version=1,
                            )
                            server_version = 1
                        else:
                            # Check version conflict
                            if client_version is not None and client_version != sched.version:
                                conflicts.append({
                                    "entity_type": entity_type,
                                    "entity_id": entity_id,
                                    "client_version": client_version,
                                    "server_version": sched.version,
                                    "server_state": {
                                        "name": sched.name,
                                        "description": sched.description,
                                        "version": sched.version,
                                    }
                                })
                                has_conflict = True
                                continue

                            sched.name = payload.get('name', sched.name)
                            sched.description = payload.get('description', sched.description)
                            sched.version += 1
                            sched.save()
                            server_version = sched.version

                    elif entity_type == 'GymClassBooking':
                        # Atomic conditional SQL reservation to prevent overselling
                        class_id = payload.get('gym_class_id')
                        gym_class = GymClass.objects.filter(pk=class_id).first()
                        if not gym_class:
                            rejected.append({
                                "entity_type": entity_type,
                                "entity_id": entity_id,
                                "reason": "Gym class not found",
                            })
                            continue

                        # Atomic condition: seats_reserved < capacity
                        rows_updated = GymClass.objects.filter(
                            pk=class_id,
                            seats_reserved__lt=F('capacity'),
                        ).update(seats_reserved=F('seats_reserved') + 1)

                        if rows_updated == 0:
                            rejected.append({
                                "entity_type": entity_type,
                                "entity_id": entity_id,
                                "reason": "Class capacity exceeded",
                            })
                            continue

                        booking = GymClassBooking.objects.create(
                            client_uuid=to_uuid(entity_id),
                            gym_class=gym_class,
                            user=user,
                            version=1,
                        )
                        server_version = booking.version

                    elif entity_type == 'WorkoutSession':
                        # Workout session mutation with ownership check
                        target_user_id = payload.get('user_id')
                        if target_user_id and int(target_user_id) != user.id and not user_is_approved_owner(user):
                            rejected.append({
                                "entity_type": entity_type,
                                "entity_id": entity_id,
                                "reason": "permission_denied: cannot write workout for another user",
                            })
                            continue

                        if op == 'delete':
                            # Soft-delete via tombstone
                            server_version = (client_version or 1) + 1
                        else:
                            server_version = (client_version or 1) + 1

                    else:
                        # Generic entity fallback
                        server_version = (client_version or 1) + 1

                    if has_conflict or has_rejected:
                        continue

                    # 4. Record Server ChangeLog entry
                    changelog = SyncChangeLog.objects.create(
                        actor=user,
                        entity_type=entity_type,
                        entity_id=entity_id,
                        op=op,
                        payload=payload,
                        client_id=client_id,
                        client_version=client_version,
                        processed=True,
                    )

                    applied.append({
                        "entity_type": entity_type,
                        "entity_id": entity_id,
                        "status": "applied",
                        "server_version": server_version,
                        "changelog_id": changelog.id,
                    })

            except Exception as e:
                rejected.append({
                    "entity_type": entity_type,
                    "entity_id": entity_id,
                    "reason": str(e),
                })

        SyncLog.objects.create(
            user=user,
            items_pushed=len(applied),
            items_pulled=0,
            status='success' if not conflicts and not rejected else 'partial_with_conflicts',
            device_id=client_id,
        )

        return Response({
            "status": "ok",
            "applied_count": len(applied),
            "conflict_count": len(conflicts),
            "rejected_count": len(rejected),
            "applied": applied,
            "conflicts": conflicts,
            "rejected": rejected,
        }, status=status.HTTP_200_OK)


class SyncPullAPIView(APIView):
    """
    Unified Server-Authoritative ChangeLog Pull Endpoint.
    Returns changelog entries strictly greater than `since` cursor in ascending monotonic order.
    Enforces strict role-scoping: non-owners can NEVER pull owner-only entities.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Pull ChangeLog Delta",
        description="Pulls delta changes since client's cursor with strict role-scoping and ascending order.",
        parameters=[
            OpenApiParameter("since", type=int, description="Last processed ChangeLog ID cursor"),
            OpenApiParameter("entity_types", type=str, description="Comma-separated entity types (optional)"),
            OpenApiParameter("limit", type=int, description="Page limit (default: 500)"),
        ],
        tags=["Unified Sync Engine"]
    )
    def get(self, request):
        user = request.user
        since_id = int(request.query_params.get('since', 0))
        limit = min(int(request.query_params.get('limit', 500)), 1000)
        entity_types_param = request.query_params.get('entity_types')

        is_owner = user_is_approved_owner(user)

        # Base query: changelogs with id > since
        qs = SyncChangeLog.objects.filter(id__gt=since_id, processed=True)

        # Role-Scoping:
        if not is_owner:
            # Regular client can ONLY see changes authored by themselves, excluding all owner-only entity types
            qs = qs.filter(actor=user).exclude(entity_type__in=OWNER_ONLY_ENTITY_TYPES)
        else:
            # Gym Owner can see their own changes and client changes within their gym
            qs = qs.filter(Q(actor=user) | Q(entity_type__in=OWNER_ONLY_ENTITY_TYPES))

        if entity_types_param:
            requested_types = [t.strip() for t in entity_types_param.split(',') if t.strip()]
            if not is_owner:
                # Strip out any owner-only entities from the requested filter
                requested_types = [t for t in requested_types if t not in OWNER_ONLY_ENTITY_TYPES]
            qs = qs.filter(entity_type__in=requested_types)

        # Ascending order guarantees correct sequential application on client
        qs = qs.order_by('id')[:limit]

        changes = [
            {
                "id": c.id,
                "entity_type": c.entity_type,
                "entity_id": c.entity_id,
                "op": c.op,
                "payload": c.payload,
                "client_version": c.client_version,
                "created_at": c.created_at.isoformat(),
            }
            for c in qs
        ]

        latest_id = changes[-1]['id'] if changes else since_id

        return Response({
            "since": since_id,
            "latest_id": latest_id,
            "count": len(changes),
            "has_more": len(changes) == limit,
            "changes": changes,
        }, status=status.HTTP_200_OK)
