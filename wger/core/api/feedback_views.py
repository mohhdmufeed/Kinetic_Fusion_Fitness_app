# -*- coding: utf-8 -*-
from datetime import timedelta
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import UserRateThrottle
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema

from wger.core.models.feedback import FeedbackReport


class FeedbackDailyRateThrottle(UserRateThrottle):
    rate = '10/day'


class FeedbackSubmitView(APIView):
    """
    Submits in-app feedback, bug reports, and suggestions.
    Rate-limited to 10 per day per user to prevent abuse.
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [FeedbackDailyRateThrottle]

    @extend_schema(
        summary="Submit Feedback or Bug Report",
        description="Submits client feedback with auto-attached sanitized device metadata. Rate limited to 10/day.",
        tags=["Feedback & Support"]
    )
    def post(self, request):
        user = request.user
        category = request.data.get('category', 'general')
        rating = int(request.data.get('rating', 5))
        message = request.data.get('message', '').strip()
        raw_metadata = request.data.get('device_metadata', {})

        if not message:
            return Response({"error": "Feedback message is required."}, status=status.HTTP_400_BAD_REQUEST)

        # Sanitize metadata: strictly strip any token, password, or sensitive auth data
        sanitized_metadata = {
            "app_version": str(raw_metadata.get('app_version', '2.1.0'))[:32],
            "os_version": str(raw_metadata.get('os_version', 'Unknown'))[:64],
            "device_model": str(raw_metadata.get('device_model', 'Unknown'))[:64],
            "screen_res": str(raw_metadata.get('screen_res', ''))[:32],
            "locale": str(raw_metadata.get('locale', 'en'))[:16],
            "user_id": user.id,
        }

        report = FeedbackReport.objects.create(
            user=user,
            category=category if category in ['bug', 'feature_request', 'exercise', 'general'] else 'general',
            rating=max(1, min(rating, 5)),
            message=message,
            device_metadata=sanitized_metadata,
            status='new',
        )

        return Response({
            "status": "success",
            "message": "Feedback submitted successfully.",
            "report_id": report.id,
            "created_at": report.created_at.isoformat(),
        }, status=status.HTTP_201_CREATED)


class FeedbackMineListView(APIView):
    """
    Returns requesting athlete's own feedback submissions with review status and admin replies.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Athlete Feedback Submissions",
        description="Returns list of own submitted feedback reports and admin responses.",
        tags=["Feedback & Support"]
    )
    def get(self, request):
        user = request.user
        reports = FeedbackReport.objects.filter(user=user).order_by('-created_at')

        results = [
            {
                "id": r.id,
                "category": r.category,
                "rating": r.rating,
                "message": r.message,
                "status": r.status,
                "admin_reply": r.admin_reply,
                "created_at": r.created_at.isoformat(),
                "updated_at": r.updated_at.isoformat(),
            }
            for r in reports[:50]
        ]

        return Response({
            "count": len(results),
            "results": results,
        }, status=status.HTTP_200_OK)
