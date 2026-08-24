# -*- coding: utf-8 -*-
"""
Module 15 — Achievements, Favorites & Home Widgets API Views
Achievements: ONLY unlocked by background Celery task — client POSTs return 403.
Favorites: unified endpoint for all entity types.
HomeWidget: atomic full-replace reorder (same pattern as Module 12 ProgramExercise).
"""
from django.db import transaction
from rest_framework import serializers as drf_serializers
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from wger.core.models import (
    Achievement, UserAchievement, Favorite, FavoriteEntityType,
    HomeWidget, WidgetType,
)


# ---------------------------------------------------------------------------
# Serializers
# ---------------------------------------------------------------------------

class AchievementSerializer(drf_serializers.ModelSerializer):
    class Meta:
        model  = Achievement
        fields = ('id', 'code', 'title', 'description', 'rule_type', 'threshold', 'icon_url')


class UserAchievementSerializer(drf_serializers.ModelSerializer):
    achievement = AchievementSerializer(read_only=True)

    class Meta:
        model  = UserAchievement
        fields = ('id', 'achievement', 'unlocked_at')
        read_only_fields = ('id', 'achievement', 'unlocked_at')


class FavoriteSerializer(drf_serializers.ModelSerializer):
    class Meta:
        model  = Favorite
        fields = ('id', 'entity_type', 'entity_id', 'created_at')
        read_only_fields = ('id', 'created_at')

    def validate_entity_type(self, value):
        valid = [e.value for e in FavoriteEntityType]
        if value not in valid:
            raise drf_serializers.ValidationError(f'entity_type must be one of {valid}')
        return value

    def validate_entity_id(self, value):
        if not value.strip():
            raise drf_serializers.ValidationError('entity_id cannot be empty.')
        return value.strip()

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        obj, _ = Favorite.objects.get_or_create(
            user=validated_data['user'],
            entity_type=validated_data['entity_type'],
            entity_id=validated_data['entity_id'],
        )
        return obj


class HomeWidgetSerializer(drf_serializers.ModelSerializer):
    class Meta:
        model  = HomeWidget
        fields = ('id', 'widget_type', 'position')
        read_only_fields = ('id',)

    def validate_widget_type(self, value):
        valid = [w.value for w in WidgetType]
        if value not in valid:
            raise drf_serializers.ValidationError(f'widget_type must be one of {valid}')
        return value


# ---------------------------------------------------------------------------
# Achievements — GET /api/v2/achievements/
#               POST /api/v2/achievements/  → always 403 for clients
# ---------------------------------------------------------------------------

class UserAchievementListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = UserAchievement.objects.filter(
            user=request.user
        ).select_related('achievement').order_by('-unlocked_at')
        return Response(UserAchievementSerializer(qs, many=True).data)

    def post(self, request):
        """Explicit rejection: achievements cannot be self-claimed by clients."""
        return Response(
            {'detail': 'Achievements are awarded automatically. Direct creation is not permitted.'},
            status=status.HTTP_403_FORBIDDEN,
        )


# ---------------------------------------------------------------------------
# All Achievements (catalogue) — GET /api/v2/achievements/catalogue/
# ---------------------------------------------------------------------------

class AchievementCatalogueView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = Achievement.objects.filter(is_active=True)
        return Response(AchievementSerializer(qs, many=True).data)


# ---------------------------------------------------------------------------
# Favorites — GET/POST /api/v2/favorites/
#            DELETE   /api/v2/favorites/<id>/
# Uniform shape for workout, program, exercise, trainer
# ---------------------------------------------------------------------------

class FavoriteListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        entity_type = request.query_params.get('entity_type')
        qs = Favorite.objects.filter(user=request.user)
        if entity_type:
            qs = qs.filter(entity_type=entity_type)
        return Response(FavoriteSerializer(qs, many=True).data)

    def post(self, request):
        serializer = FavoriteSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            fav = serializer.save()
            return Response(FavoriteSerializer(fav).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class FavoriteDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        deleted, _ = Favorite.objects.filter(pk=pk, user=request.user).delete()
        if not deleted:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(status=status.HTTP_204_NO_CONTENT)


# ---------------------------------------------------------------------------
# Home Widgets — GET/PUT /api/v2/home-widgets/
#               PATCH   /api/v2/home-widgets/reorder/
# ---------------------------------------------------------------------------

class HomeWidgetListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = HomeWidget.objects.filter(user=request.user).order_by('position')
        return Response(HomeWidgetSerializer(qs, many=True).data)

    def put(self, request):
        """Full replace: set the user's widget list to exactly what was submitted."""
        serializer = HomeWidgetSerializer(data=request.data, many=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            HomeWidget.objects.filter(user=request.user).delete()
            for idx, item in enumerate(serializer.validated_data):
                HomeWidget.objects.create(
                    user=request.user,
                    widget_type=item['widget_type'],
                    position=item.get('position', idx),
                )

        qs = HomeWidget.objects.filter(user=request.user).order_by('position')
        return Response(HomeWidgetSerializer(qs, many=True).data)


class HomeWidgetReorderView(APIView):
    """
    PATCH /api/v2/home-widgets/reorder/
    Body: [{"widget_type": "recovery_score", "position": 0}, ...]
    Atomic full-replace of positions — never sequential individual moves
    that risk leaving things half-ordered on partial failure.
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request):
        items = request.data
        if not isinstance(items, list):
            return Response({'detail': 'Expected a list of {widget_type, position} objects.'},
                            status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            for item in items:
                widget_type = item.get('widget_type', '').strip()
                try:
                    position = int(item.get('position', 0))
                except (ValueError, TypeError):
                    return Response({'detail': f'Invalid position for {widget_type}.'},
                                    status=status.HTTP_400_BAD_REQUEST)
                HomeWidget.objects.filter(
                    user=request.user, widget_type=widget_type
                ).update(position=position)

        qs = HomeWidget.objects.filter(user=request.user).order_by('position')
        return Response(HomeWidgetSerializer(qs, many=True).data)
