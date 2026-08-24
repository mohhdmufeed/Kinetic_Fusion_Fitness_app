# -*- coding: utf-8 -*-
from django.db.models import Q
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema, OpenApiParameter

from wger.exercises.models import Exercise, ExerciseCategory, Muscle, Equipment
from wger.exercises.models.publication import (
    ExercisePublicationState,
    UserExerciseFavorite,
    ExerciseLibraryMetadata,
)
from wger.manager.models import WorkoutLog


class ExerciseLibraryListView(APIView):
    """
    Client-facing searchable, filterable exercise library endpoint.
    Only returns published exercises. Preserves multilingual data.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Browse Exercise Library",
        description="Searchable, filterable list of published exercises with target muscles, equipment, and user favorite status.",
        parameters=[
            OpenApiParameter("search", type=str, description="Search keyword in exercise name or description"),
            OpenApiParameter("category", type=int, description="Filter by ExerciseCategory ID"),
            OpenApiParameter("muscle", type=int, description="Filter by primary Muscle ID"),
            OpenApiParameter("equipment", type=int, description="Filter by Equipment ID"),
            OpenApiParameter("favorites_only", type=bool, description="Filter only athlete's favorited exercises"),
        ],
        tags=["Exercise Library"]
    )
    def get(self, request):
        user = request.user
        search_query = request.query_params.get('search', '').strip()
        category_id = request.query_params.get('category')
        muscle_id = request.query_params.get('muscle')
        equipment_id = request.query_params.get('equipment')
        favorites_only = request.query_params.get('favorites_only', 'false').lower() == 'true'

        # Get list of un-published exercise IDs to exclude
        excluded_ids = ExercisePublicationState.objects.exclude(status='published').values_list('exercise_base_id', flat=True)

        qs = Exercise.objects.exclude(exercise_base_id__in=excluded_ids)

        if search_query:
            qs = qs.filter(
                Q(name__icontains=search_query) |
                Q(description__icontains=search_query) |
                Q(exercise_base__translations__name__icontains=search_query)
            ).distinct()

        if category_id:
            qs = qs.filter(exercise_base__category_id=category_id)

        if muscle_id:
            qs = qs.filter(exercise_base__muscles__id=muscle_id)

        if equipment_id:
            qs = qs.filter(exercise_base__equipment__id=equipment_id)

        # User favorites set
        user_fav_ids = set(UserExerciseFavorite.objects.filter(user=user).values_list('exercise_base_id', flat=True))

        if favorites_only:
            qs = qs.filter(exercise_base_id__in=user_fav_ids)

        results = []
        for ex in qs[:100]:
            base = ex.exercise_base
            pub_state = getattr(base, 'publication_state', None)

            results.append({
                "id": ex.id,
                "uuid": str(base.uuid) if base else "",
                "name": ex.name,
                "description": ex.description,
                "category": {
                    "id": base.category.id if base and base.category else None,
                    "name": base.category.name if base and base.category else "General",
                },
                "muscles": [
                    {"id": m.id, "name": m.name, "name_en": m.name_en}
                    for m in (base.muscles.all() if base else [])
                ],
                "equipment": [
                    {"id": eq.id, "name": eq.name}
                    for eq in (base.equipment.all() if base else [])
                ],
                "default_sets": pub_state.default_sets if pub_state else 3,
                "default_reps": pub_state.default_reps if pub_state else 10,
                "video_url": pub_state.video_url if pub_state else "",
                "is_favorite": base.id in user_fav_ids if base else False,
            })

        return Response({
            "version": ExerciseLibraryMetadata.get_current_version(),
            "count": len(results),
            "results": results,
        }, status=status.HTTP_200_OK)


class ExerciseFavoriteToggleView(APIView):
    """
    Toggle athlete favorite status for an exercise.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Toggle Exercise Favorite",
        description="Add or remove an exercise from athlete's favorites list.",
        tags=["Exercise Library"]
    )
    def post(self, request, exercise_id):
        user = request.user
        ex = Exercise.objects.filter(pk=exercise_id).first()
        if not ex or not ex.exercise_base:
            return Response({"error": "Exercise not found"}, status=status.HTTP_404_NOT_FOUND)

        fav = UserExerciseFavorite.objects.filter(user=user, exercise_base=ex.exercise_base).first()
        if fav:
            fav.delete()
            is_fav = False
        else:
            UserExerciseFavorite.objects.create(user=user, exercise_base=ex.exercise_base)
            is_fav = True

        return Response({
            "exercise_id": exercise_id,
            "is_favorite": is_fav,
        }, status=status.HTTP_200_OK)


class ExerciseHistoryView(APIView):
    """
    Returns athlete's personal logs, PR (estimated 1RM), and historical volume for this exercise.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Athlete Exercise PR & History",
        description="Returns personal PR estimated 1RM, max weight, total volume, and session history.",
        tags=["Exercise Library"]
    )
    def get(self, request, exercise_id):
        user = request.user
        logs = WorkoutLog.objects.filter(user=user, exercise_id=exercise_id).order_by('-date')

        max_weight = 0.0
        pr_e1rm = 0.0
        total_reps = 0

        history_items = []
        for log in logs[:50]:
            w = float(log.weight)
            r = log.reps
            e1rm = round(w * (1 + r / 30.0), 1)

            if w > max_weight:
                max_weight = w
            if e1rm > pr_e1rm:
                pr_e1rm = e1rm
            total_reps += r

            history_items.append({
                "id": log.id,
                "date": log.date.isoformat(),
                "weight_kg": w,
                "reps": r,
                "e1rm_kg": e1rm,
            })

        return Response({
            "exercise_id": exercise_id,
            "personal_records": {
                "max_weight_kg": max_weight,
                "estimated_1rm_kg": pr_e1rm,
                "total_sets_logged": len(logs),
                "total_reps_completed": total_reps,
            },
            "history": history_items,
        }, status=status.HTTP_200_OK)


class ExerciseSuggestionView(APIView):
    """
    Allows community athletes to suggest an exercise. Lands in review queue for admin approval.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Suggest Community Exercise",
        description="Submit a community exercise suggestion for super admin approval.",
        tags=["Exercise Library"]
    )
    def post(self, request):
        user = request.user
        name = request.data.get('name', '').strip()
        description = request.data.get('description', '').strip()
        category_id = request.data.get('category')

        if not name:
            return Response({"error": "Exercise name is required"}, status=status.HTTP_400_BAD_REQUEST)

        # Create un-published exercise in review queue
        from wger.exercises.models.base import ExerciseBase
        from wger.core.models import Language

        en_lang = Language.objects.filter(pk=2).first() or Language.objects.first()
        category = ExerciseCategory.objects.filter(pk=category_id).first() if category_id else ExerciseCategory.objects.first()

        base = ExerciseBase.objects.create(category=category)
        ex = Exercise.objects.create(
            exercise_base=base,
            name=name,
            description=description,
            language=en_lang,
        )

        ExercisePublicationState.objects.create(
            exercise_base=base,
            status='in_review',
            author=user,
            default_sets=int(request.data.get('default_sets', 3)),
            default_reps=int(request.data.get('default_reps', 10)),
            video_url=request.data.get('video_url', ''),
        )

        return Response({
            "status": "in_review",
            "message": "Exercise suggestion submitted successfully for admin review.",
            "exercise_id": ex.id,
        }, status=status.HTTP_201_CREATED)
