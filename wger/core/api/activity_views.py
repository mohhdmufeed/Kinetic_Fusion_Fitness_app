# -*- coding: utf-8 -*-
from datetime import timedelta
from django.utils import timezone
from django.utils.dateparse import parse_datetime
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema, OpenApiParameter

from wger.core.models.activity import ActivityLog
from wger.core.models.ml import DailyMetrics


class ActivityRecordView(APIView):
    """
    Ingests real device GPS routes, step counts, and active distance.
    Automatically feeds daily steps into DailyMetrics for ML recovery scoring.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Record GPS / Pedometer Activity",
        description="Ingests GPS workout or passive daily step count telemetry scoped to athlete.",
        tags=["Activity & Location Telemetry"]
    )
    def post(self, request):
        user = request.user
        activity_type = request.data.get('activity_type', 'general_steps')
        start_time_str = request.data.get('start_time')
        end_time_str = request.data.get('end_time')
        distance_meters = float(request.data.get('distance_meters', 0.0))
        step_count = int(request.data.get('step_count', 0))
        avg_pace = float(request.data.get('avg_pace_min_per_km', 0.0))
        calories = float(request.data.get('calories_burned', 0.0))
        route_geojson = request.data.get('route_geojson', {})

        start_dt = parse_datetime(start_time_str) if start_time_str else timezone.now()
        end_dt = parse_datetime(end_time_str) if end_time_str else None

        activity = ActivityLog.objects.create(
            user=user,
            activity_type=activity_type,
            start_time=start_dt,
            end_time=end_dt,
            distance_meters=distance_meters,
            step_count=step_count,
            avg_pace_min_per_km=avg_pace,
            calories_burned=calories,
            route_geojson=route_geojson,
        )

        # Update DailyMetrics step count for today
        target_date = start_dt.date()
        daily, _ = DailyMetrics.objects.get_or_create(user=user, date=target_date)
        daily.steps = (daily.steps or 0) + step_count
        daily.save()

        return Response({
            "status": "success",
            "activity_id": activity.id,
            "activity_type": activity.activity_type,
            "distance_km": round(activity.distance_meters / 1000.0, 2),
            "step_count": activity.step_count,
            "daily_total_steps": daily.steps,
        }, status=status.HTTP_201_CREATED)


class ActivityHistoryView(APIView):
    """
    Returns athlete's chronological activity sessions.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Athlete Activity History",
        description="Returns list of recorded GPS runs, walks, cycles, and daily step logs.",
        parameters=[
            OpenApiParameter("type", type=str, description="Filter by activity_type: running | walking | cycling | general_steps"),
        ],
        tags=["Activity & Location Telemetry"]
    )
    def get(self, request):
        user = request.user
        type_filter = request.query_params.get('type')
        qs = ActivityLog.objects.filter(user=user)

        if type_filter:
            qs = qs.filter(activity_type=type_filter)

        results = [
            {
                "id": a.id,
                "activity_type": a.activity_type,
                "start_time": a.start_time.isoformat(),
                "end_time": a.end_time.isoformat() if a.end_time else None,
                "distance_km": round(a.distance_meters / 1000.0, 2),
                "step_count": a.step_count,
                "avg_pace_min_per_km": a.avg_pace_min_per_km,
                "calories_burned": a.calories_burned,
                "has_gps_route": bool(a.route_geojson),
            }
            for a in qs[:50]
        ]

        return Response({
            "count": len(results),
            "results": results,
        }, status=status.HTTP_200_OK)


class ActivityLocationPurgeView(APIView):
    """
    GDPR / CCPA data subject rights endpoint: immediately purges all historical GPS coordinate
    breadcrumbs across all activity logs for the requesting user.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Purge Historical Location Data (GDPR / Privacy)",
        description="Deletes all stored GPS coordinate breadcrumbs for the requesting athlete while preserving non-location aggregate metrics.",
        tags=["Activity & Location Telemetry"]
    )
    def delete(self, request):
        user = request.user
        count = ActivityLog.objects.filter(user=user).exclude(route_geojson={}).update(route_geojson={})

        return Response({
            "status": "success",
            "message": f"Successfully purged GPS coordinates from {count} activity records.",
            "records_cleared": count,
        }, status=status.HTTP_200_OK)
