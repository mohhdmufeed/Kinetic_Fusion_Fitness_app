# -*- coding: utf-8 -*-
from datetime import timedelta
from django.utils import timezone
from rest_framework import status, views
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from wger.core.models.wearable import WearableIntegration
from wger.core.models.sync import SyncChangeLog


class WearableStatusView(views.APIView):
    """
    Returns connection statuses for all wearable integrations for the authenticated user.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        integrations = WearableIntegration.objects.filter(user=request.user)
        data = {
            item.provider: {
                'is_active': item.is_active,
                'is_expired': item.is_expired(),
                'last_sync_at': item.last_sync_at.isoformat() if item.last_sync_at else None,
                'metadata': item.metadata,
            }
            for item in integrations
        }
        return Response(data, status=status.HTTP_200_OK)


class OuraAuthView(views.APIView):
    """
    Handles Oura Ring OAuth2 token registration / exchange and revocation.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        action = request.data.get('action', 'connect')
        if action == 'disconnect':
            WearableIntegration.objects.filter(user=request.user, provider='oura').update(
                is_active=False,
                encrypted_access_token='',
                encrypted_refresh_token='',
                updated_at=timezone.now(),
            )
            return Response({'status': 'revoked'}, status=status.HTTP_200_OK)

        access_token = request.data.get('access_token')
        refresh_token = request.data.get('refresh_token', '')
        expires_in = request.data.get('expires_in', 86400)

        if not access_token:
            return Response({'error': 'access_token is required'}, status=status.HTTP_400_BAD_REQUEST)

        expires_at = timezone.now() + timedelta(seconds=int(expires_in))
        integration, _ = WearableIntegration.objects.update_or_create(
            user=request.user,
            provider='oura',
            defaults={
                'encrypted_access_token': access_token,
                'encrypted_refresh_token': refresh_token,
                'token_expires_at': expires_at,
                'is_active': True,
                'last_sync_at': timezone.now(),
            },
        )
        return Response({
            'status': 'connected',
            'provider': 'oura',
            'expires_at': expires_at.isoformat(),
        }, status=status.HTTP_200_OK)


class OuraSyncView(views.APIView):
    """
    Ingests raw physiological signals from Oura Ring.
    Extracts raw nocturnal HRV, lowest heart rate, total sleep duration, and steps.
    Strictly bypasses proprietary opinionated scores (readiness_score, sleep_score).
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        integration = WearableIntegration.objects.filter(
            user=request.user,
            provider='oura',
            is_active=True,
        ).first()

        if not integration or integration.is_expired():
            return Response(
                {'error': 'Oura integration is disconnected or expired'},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        documents = request.data.get('documents', [])
        synced_count = 0

        for doc in documents:
            day_str = doc.get('day', timezone.now().strftime('%Y-%m-%d'))
            # 1. Raw HRV (rMSSD in ms)
            if 'average_hrv' in doc:
                SyncChangeLog.objects.create(
                    entity_type='Measurement',
                    entity_id=f"oura_hrv_{day_str}_{request.user.id}",
                    op='create',
                    payload={
                        'metric': 'hrv_rmssd',
                        'value': float(doc['average_hrv']),
                        'unit': 'ms',
                        'source': 'oura',
                        'quality': 'observed',
                    },
                    actor=request.user,
                )
                synced_count += 1

            # 2. Raw Resting HR (bpm)
            if 'lowest_heart_rate' in doc or 'resting_heart_rate' in doc:
                val = doc.get('lowest_heart_rate') or doc.get('resting_heart_rate')
                SyncChangeLog.objects.create(
                    entity_type='Measurement',
                    entity_id=f"oura_rhr_{day_str}_{request.user.id}",
                    op='create',
                    payload={
                        'metric': 'rhr',
                        'value': float(val),
                        'unit': 'bpm',
                        'source': 'oura',
                        'quality': 'observed',
                    },
                    actor=request.user,
                )
                synced_count += 1

            # 3. Raw Sleep duration (hours)
            if 'total_sleep_duration' in doc:
                hours = round(float(doc['total_sleep_duration']) / 3600.0, 2)
                SyncChangeLog.objects.create(
                    entity_type='Measurement',
                    entity_id=f"oura_sleep_{day_str}_{request.user.id}",
                    op='create',
                    payload={
                        'metric': 'sleep_duration_hrs',
                        'value': hours,
                        'unit': 'hours',
                        'source': 'oura',
                        'quality': 'observed',
                    },
                    actor=request.user,
                )
                synced_count += 1

            # 4. Raw Steps
            if 'steps' in doc:
                SyncChangeLog.objects.create(
                    entity_type='Measurement',
                    entity_id=f"oura_steps_{day_str}_{request.user.id}",
                    op='create',
                    payload={
                        'metric': 'steps',
                        'value': float(doc['steps']),
                        'unit': 'count',
                        'source': 'oura',
                        'quality': 'observed',
                    },
                    actor=request.user,
                )
                synced_count += 1

        integration.last_sync_at = timezone.now()
        integration.save(update_fields=['last_sync_at'])

        return Response({
            'status': 'success',
            'synced_measurements': synced_count,
        }, status=status.HTTP_200_OK)
