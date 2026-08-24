# -*- coding: utf-8 -*-
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q
from drf_spectacular.utils import extend_schema, OpenApiParameter

from wger.core.api.admin_permissions import IsSuperAdmin
from wger.core.models.admin import AdminAuditLog
from wger.core.models.feedback import FeedbackReport


class AdminFeedbackListView(APIView):
    """
    Super Admin endpoint to list, filter, and search feedback reports submitted across all athletes.
    """
    permission_classes = [IsSuperAdmin]

    @extend_schema(
        summary="Admin List Feedback & Bug Reports",
        description="Filter by category and status, search by athlete username or message.",
        parameters=[
            OpenApiParameter("category", type=str, description="bug | feature_request | exercise | general"),
            OpenApiParameter("status", type=str, description="new | in_review | resolved | wontfix"),
            OpenApiParameter("search", type=str, description="Keyword search in athlete username or message text"),
        ],
        tags=["Admin Feedback Management"]
    )
    def get(self, request):
        category = request.query_params.get('category')
        status_filter = request.query_params.get('status')
        search_query = request.query_params.get('search', '').strip()

        qs = FeedbackReport.objects.select_related('user', 'admin_replied_by').all()

        if category:
            qs = qs.filter(category=category)
        if status_filter:
            qs = qs.filter(status=status_filter)
        if search_query:
            qs = qs.filter(
                Q(message__icontains=search_query) |
                Q(user__username__icontains=search_query) |
                Q(user__email__icontains=search_query)
            )

        results = [
            {
                "id": r.id,
                "athlete_id": r.user.id,
                "athlete_username": r.user.username,
                "athlete_email": r.user.email,
                "category": r.category,
                "rating": r.rating,
                "message": r.message,
                "device_metadata": r.device_metadata,
                "status": r.status,
                "admin_reply": r.admin_reply,
                "admin_replied_by": r.admin_replied_by.username if r.admin_replied_by else None,
                "created_at": r.created_at.isoformat(),
                "updated_at": r.updated_at.isoformat(),
            }
            for r in qs[:100]
        ]

        return Response({
            "count": len(results),
            "results": results,
        }, status=status.HTTP_200_OK)


class AdminFeedbackDetailView(APIView):
    """
    Super Admin endpoint to triage, update status, and reply to athlete feedback.
    """
    permission_classes = [IsSuperAdmin]

    @extend_schema(
        summary="Admin Triage & Reply to Feedback",
        description="Update status (new/in_review/resolved/wontfix), attach official admin reply, and write immutable audit log.",
        tags=["Admin Feedback Management"]
    )
    def patch(self, request, report_id):
        admin_user = request.user
        report = FeedbackReport.objects.filter(pk=report_id).first()
        if not report:
            return Response({"error": "Feedback report not found"}, status=status.HTTP_404_NOT_FOUND)

        old_status = report.status
        new_status = request.data.get('status', old_status)
        admin_reply = request.data.get('admin_reply', '').strip()

        if new_status in ['new', 'in_review', 'resolved', 'wontfix']:
            report.status = new_status

        if admin_reply:
            report.admin_reply = admin_reply
            report.admin_replied_by = admin_user

        report.save()

        # Audit Log
        AdminAuditLog.objects.create(
            actor=admin_user,
            action=f"Updated Feedback #{report.id} (Status: {old_status} -> {report.status})",
            target_model="FeedbackReport",
            target_id=str(report.id),
            details_json={
                "athlete": report.user.username,
                "category": report.category,
                "previous_status": old_status,
                "new_status": report.status,
                "admin_reply": admin_reply,
            }
        )

        return Response({
            "status": "success",
            "report_id": report.id,
            "new_status": report.status,
            "admin_reply": report.admin_reply,
            "updated_at": report.updated_at.isoformat(),
        }, status=status.HTTP_200_OK)
