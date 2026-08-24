# -*- coding: utf-8 -*-
from django.utils import timezone
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema, OpenApiParameter

from wger.core.api.admin_permissions import IsSuperAdmin
from wger.core.models.admin import AdminAuditLog
from wger.exercises.models import Exercise, ExerciseCategory, Muscle, Equipment
from wger.exercises.models.publication import (
    ExercisePublicationState,
    ExerciseLibraryMetadata,
)
from wger.core.models import Language


class AdminExerciseListView(APIView):
    """
    Super Admin endpoint to list, review, and filter exercises across draft, in_review, published, and archived states.
    """
    permission_classes = [IsSuperAdmin]

    @extend_schema(
        summary="Admin Exercise Management List",
        description="Lists all exercises including drafts, suggestions in review, published, and archived items.",
        tags=["Admin Exercise Governance"]
    )
    def get(self, request):
        status_filter = request.query_params.get('status')
        qs = Exercise.objects.all()

        if status_filter:
            qs = qs.filter(publication_state__status=status_filter)

        results = []
        for ex in qs[:100]:
            pub_state = getattr(ex, 'publication_state', None)

            results.append({
                "id": ex.id,
                "uuid": str(ex.uuid),
                "name": ex.name,
                "description": ex.description,
                "status": pub_state.status if pub_state else "published",
                "author": pub_state.author.username if pub_state and pub_state.author else "System",
                "default_sets": pub_state.default_sets if pub_state else 3,
                "default_reps": pub_state.default_reps if pub_state else 10,
                "created_at": ex.created.isoformat() if ex.created else timezone.now().isoformat(),
            })

        return Response({
            "library_version": ExerciseLibraryMetadata.get_current_version(),
            "count": len(results),
            "results": results,
        }, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Admin Create Exercise",
        description="Creates a new exercise (draft or published) and records audit trail.",
        tags=["Admin Exercise Governance"]
    )
    def post(self, request):
        admin_user = request.user
        name = request.data.get('name', '').strip()
        description = request.data.get('description', '').strip()
        category_id = request.data.get('category')
        pub_status = request.data.get('status', 'draft')

        if not name:
            return Response({"error": "Exercise name is required"}, status=status.HTTP_400_BAD_REQUEST)

        en_lang = Language.objects.filter(pk=2).first() or Language.objects.first()
        category = ExerciseCategory.objects.filter(pk=category_id).first() if category_id else ExerciseCategory.objects.first()

        ex = Exercise.objects.create(
            category=category,
            name=name,
            description=description,
            language=en_lang,
        )

        pub_state = ExercisePublicationState.objects.create(
            exercise=ex,
            status=pub_status,
            author=admin_user,
            reviewed_by=admin_user if pub_status == 'published' else None,
            default_sets=int(request.data.get('default_sets', 3)),
            default_reps=int(request.data.get('default_reps', 10)),
            video_url=request.data.get('video_url', ''),
            published_at=timezone.now() if pub_status == 'published' else None,
        )

        if pub_status == 'published':
            ExerciseLibraryMetadata.bump_version()

        # Audit Log
        AdminAuditLog.objects.create(
            actor=admin_user,
            action=f"Created exercise '{name}' with status '{pub_status}'",
            target_model="Exercise",
            target_id=str(ex.id),
            details_json={
                "name": name,
                "status": pub_status,
                "library_version": ExerciseLibraryMetadata.get_current_version(),
            }
        )

        return Response({
            "status": "success",
            "exercise_id": ex.id,
            "publication_status": pub_status,
            "library_version": ExerciseLibraryMetadata.get_current_version(),
        }, status=status.HTTP_201_CREATED)


class AdminExercisePublishView(APIView):
    """
    Approves and publishes an exercise, bumping the global library version for client cache invalidation.
    """
    permission_classes = [IsSuperAdmin]

    @extend_schema(
        summary="Admin Publish Exercise",
        description="Publishes a draft/review exercise, invalidates client cache by bumping library version, and logs audit trail.",
        tags=["Admin Exercise Governance"]
    )
    def post(self, request, base_id):
        admin_user = request.user
        ex = Exercise.objects.filter(pk=base_id).first()
        if not ex:
            return Response({"error": "Exercise not found"}, status=status.HTTP_404_NOT_FOUND)

        pub_state, _ = ExercisePublicationState.objects.get_or_create(exercise=ex)
        old_status = pub_state.status

        pub_state.status = 'published'
        pub_state.reviewed_by = admin_user
        pub_state.published_at = timezone.now()
        pub_state.save()

        new_version = ExerciseLibraryMetadata.bump_version()

        # Audit Log
        AdminAuditLog.objects.create(
            actor=admin_user,
            action=f"Published exercise #{ex.id} (Status: {old_status} -> published)",
            target_model="Exercise",
            target_id=str(ex.id),
            details_json={
                "previous_status": old_status,
                "new_status": "published",
                "new_library_version": new_version,
            }
        )

        return Response({
            "status": "success",
            "message": f"Exercise #{ex.id} published successfully.",
            "library_version": new_version,
        }, status=status.HTTP_200_OK)


class AdminExerciseDeactivateView(APIView):
    """
    Deactivates / archives an exercise and bumps library version.
    """
    permission_classes = [IsSuperAdmin]

    @extend_schema(
        summary="Admin Deactivate Exercise",
        description="Deactivates/archives an exercise and logs audit trail.",
        tags=["Admin Exercise Governance"]
    )
    def post(self, request, base_id):
        admin_user = request.user
        ex = Exercise.objects.filter(pk=base_id).first()
        if not ex:
            return Response({"error": "Exercise not found"}, status=status.HTTP_404_NOT_FOUND)

        pub_state, _ = ExercisePublicationState.objects.get_or_create(exercise=ex)
        pub_state.status = 'archived'
        pub_state.save()

        new_version = ExerciseLibraryMetadata.bump_version()

        # Audit Log
        AdminAuditLog.objects.create(
            actor=admin_user,
            action=f"Archived/Deactivated exercise #{ex.id}",
            target_model="Exercise",
            target_id=str(ex.id),
            details_json={
                "new_status": "archived",
                "new_library_version": new_version,
            }
        )

        return Response({
            "status": "success",
            "message": f"Exercise #{ex.id} archived.",
            "library_version": new_version,
        }, status=status.HTTP_200_OK)
