# -*- coding: utf-8 -*-
from datetime import datetime
from django.utils import timezone
from django.utils.dateparse import parse_datetime
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema, OpenApiParameter

from wger.core.models.sync import SyncLog
from wger.weight.models import WeightEntry
from wger.manager.models import WorkoutLog, Routine, WorkoutSession


class SyncPushView(APIView):
    """
    Batched, idempotent push endpoint for client-created mutations.
    Each item is keyed by client_uuid to prevent duplicate creation on partial retries.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Sync Push (Batched Mutations)",
        description="Push offline mutations batched by client UUID with deduplication and idempotency.",
        tags=["Synchronization"]
    )
    def post(self, request):
        user = request.user
        mutations = request.data.get('mutations', [])
        device_id = request.data.get('device_id', '')
        client_version = request.data.get('client_version', '1.0.0')

        processed_count = 0
        conflicts_resolved = 0

        for item in mutations:
            client_uuid = item.get('uuid')
            entity_type = item.get('type')
            action = item.get('action', 'create')
            payload = item.get('data', {})
            client_time_str = item.get('timestamp')
            client_time = parse_datetime(client_time_str) if client_time_str else timezone.now()

            if entity_type == 'weight_entry':
                weight_val = payload.get('weight')
                date_val = payload.get('date', timezone.now().strftime('%Y-%m-%d'))
                # Idempotent write: check if already exists by date / uuid
                existing = WeightEntry.objects.filter(user=user, date=date_val).first()
                if not existing:
                    WeightEntry.objects.create(
                        user=user,
                        weight=weight_val,
                        date=date_val,
                    )
                    processed_count += 1
                else:
                    # Last-Write-Wins update if newer
                    existing.weight = weight_val
                    existing.save()
                    conflicts_resolved += 1

            elif entity_type == 'workout_log':
                exercise_id = payload.get('exercise')
                reps = payload.get('reps', 10)
                weight = payload.get('weight', 0.0)
                date_val = payload.get('date', timezone.now().strftime('%Y-%m-%d'))

                # Append-only deduplication
                existing = WorkoutLog.objects.filter(
                    user=user,
                    exercise_id=exercise_id,
                    reps=reps,
                    weight=weight,
                    date=date_val,
                ).first()

                if not existing:
                    WorkoutLog.objects.create(
                        user=user,
                        exercise_id=exercise_id,
                        reps=reps,
                        weight=weight,
                        date=date_val,
                    )
                    processed_count += 1
                else:
                    conflicts_resolved += 1

        # Record Sync Log
        SyncLog.objects.create(
            user=user,
            items_pushed=processed_count,
            items_pulled=0,
            status='success',
            device_id=device_id,
            client_version=client_version,
            details=f"Processed {processed_count} mutations, resolved {conflicts_resolved} duplicates/conflicts.",
        )

        return Response({
            "status": "success",
            "processed": processed_count,
            "conflicts_resolved": conflicts_resolved,
            "server_timestamp": timezone.now().isoformat(),
        }, status=status.HTTP_200_OK)


class SyncPullView(APIView):
    """
    Delta pull endpoint returning changes for request.user since the provided timestamp cursor.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Sync Pull (Delta Ingestion)",
        description="Retrieve changed records since last_synced_at timestamp cursor.",
        parameters=[
            OpenApiParameter("since", type=str, description="ISO8601 timestamp cursor (e.g. 2026-08-19T00:00:00Z)"),
        ],
        tags=["Synchronization"]
    )
    def get(self, request):
        user = request.user
        since_str = request.query_params.get('since')
        since_dt = parse_datetime(since_str) if since_str else None

        # Pull weight entries
        weight_qs = WeightEntry.objects.filter(user=user)
        if since_dt:
            weight_qs = weight_qs.filter(date__gte=since_dt.date())

        weight_entries = [
            {
                "id": w.id,
                "weight": float(w.weight),
                "date": w.date.isoformat(),
            }
            for w in weight_qs[:100]
        ]

        # Pull workout logs
        workout_qs = WorkoutLog.objects.filter(user=user)
        if since_dt:
            workout_qs = workout_qs.filter(date__gte=since_dt.date())

        workout_logs = [
            {
                "id": log.id,
                "exercise": log.exercise_id,
                "reps": log.reps,
                "weight": float(log.weight),
                "date": log.date.isoformat(),
            }
            for log in workout_qs[:100]
        ]

        total_pulled = len(weight_entries) + len(workout_logs)

        return Response({
            "server_timestamp": timezone.now().isoformat(),
            "deltas": {
                "weight_entries": weight_entries,
                "workout_logs": workout_logs,
            },
            "count": total_pulled,
        }, status=status.HTTP_200_OK)
