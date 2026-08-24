# -*- coding: utf-8 -*-
"""
Module 14 — Trainer Directory & Session/Class Booking API Views
Capacity enforcement uses SELECT FOR UPDATE in an atomic transaction.
Booking is ALWAYS synchronous — never queued offline.
"""
import math
from django.db import transaction, IntegrityError
from django.db.models import Count, Q, F
from django.utils import timezone
from rest_framework import status, serializers
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from wger.core.models import (
    TrainerProfile, GroupClass, PrivateSession, Booking,
    BookingStatus, ClassStatus, SessionType, SessionStatus,
    ClientMembership,
)
from wger.social.models import Notification, NotificationType


# ---------------------------------------------------------------------------
# Serializers (inline for brevity — single file)
# ---------------------------------------------------------------------------

class TrainerProfileSerializer(serializers.ModelSerializer):
    username     = serializers.CharField(source='user.username', read_only=True)
    display_name = serializers.SerializerMethodField()

    class Meta:
        model  = TrainerProfile
        fields = (
            'id', 'username', 'display_name', 'gym_id', 'bio',
            'specialties', 'certifications', 'media_urls', 'is_accepting_bookings',
        )

    def get_display_name(self, obj):
        return obj.user.get_full_name() or obj.user.username


class GroupClassSerializer(serializers.ModelSerializer):
    trainer_name    = serializers.CharField(source='trainer.user.username', read_only=True)
    seats_available = serializers.SerializerMethodField()
    distance_km     = serializers.SerializerMethodField()

    class Meta:
        model  = GroupClass
        fields = (
            'id', 'trainer_name', 'title', 'description',
            'start_time', 'end_time', 'capacity', 'seats_available',
            'venue_name', 'venue_lat', 'venue_lng', 'is_online',
            'status', 'distance_km',
        )

    def get_seats_available(self, obj):
        return obj.seats_available()

    def get_distance_km(self, obj):
        """Compute real distance from user lat/lng passed via context."""
        user_lat = self.context.get('user_lat')
        user_lng = self.context.get('user_lng')
        if user_lat is None or user_lng is None or obj.venue_lat is None:
            return None
        # Haversine formula
        R  = 6371
        d_lat = math.radians(obj.venue_lat - user_lat)
        d_lng = math.radians(obj.venue_lng - user_lng)
        a  = (math.sin(d_lat / 2) ** 2
              + math.cos(math.radians(user_lat))
              * math.cos(math.radians(obj.venue_lat))
              * math.sin(d_lng / 2) ** 2)
        return round(R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)), 2)


class PrivateSessionSerializer(serializers.ModelSerializer):
    trainer_id = serializers.IntegerField(write_only=True)

    class Meta:
        model  = PrivateSession
        fields = (
            'id', 'trainer_id', 'session_type', 'requested_time',
            'status', 'payment_ref', 'notes', 'created_at',
        )
        read_only_fields = ('id', 'status', 'payment_ref', 'created_at')

    def validate_trainer_id(self, value):
        try:
            tp = TrainerProfile.objects.get(pk=value, is_accepting_bookings=True)
            return tp
        except TrainerProfile.DoesNotExist:
            raise serializers.ValidationError('Trainer not found or not accepting bookings.')

    def create(self, validated_data):
        trainer = validated_data.pop('trainer_id')
        validated_data['trainer'] = trainer
        validated_data['client']  = self.context['request'].user
        return PrivateSession.objects.create(**validated_data)


class BookingSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Booking
        fields = ('id', 'class_ref', 'private_session', 'status', 'waitlist_position', 'created_at')
        read_only_fields = ('id', 'status', 'waitlist_position', 'created_at')


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _check_active_membership(user):
    """Return True iff the user has an active membership (end date in future)."""
    try:
        membership = ClientMembership.objects.filter(
            user=user,
            membership_start_date__lte=timezone.now().date(),
            membership_end_date__gte=timezone.now().date(),
        ).first()
        return membership is not None
    except Exception:
        return False


# ---------------------------------------------------------------------------
# Trainer List  — GET /api/v2/trainers/
# ---------------------------------------------------------------------------

class TrainerListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        gym_id = request.query_params.get('gym_id', 'default_gym')
        qs = TrainerProfile.objects.filter(gym_id=gym_id).select_related('user')
        return Response(TrainerProfileSerializer(qs, many=True).data)


class TrainerDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            trainer = TrainerProfile.objects.select_related('user').get(pk=pk)
        except TrainerProfile.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(TrainerProfileSerializer(trainer).data)


# ---------------------------------------------------------------------------
# Group Classes — GET /api/v2/classes/?near=<lat,lng>&date=<date>
# ---------------------------------------------------------------------------

class GroupClassListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        gym_id = 'default_gym'
        qs = GroupClass.objects.filter(
            gym_id=gym_id,
            status=ClassStatus.SCHEDULED,
            start_time__gte=timezone.now(),
        ).select_related('trainer__user').order_by('start_time')

        # Date filter
        date_str = request.query_params.get('date')
        if date_str:
            try:
                from datetime import datetime
                d = datetime.strptime(date_str, '%Y-%m-%d').date()
                qs = qs.filter(start_time__date=d)
            except ValueError:
                pass

        # Parse user location for distance calculation
        user_lat = user_lng = None
        near = request.query_params.get('near', '')
        if near:
            try:
                parts = near.split(',')
                user_lat = float(parts[0])
                user_lng = float(parts[1])
            except (ValueError, IndexError):
                pass

        ctx = {'request': request, 'user_lat': user_lat, 'user_lng': user_lng}
        return Response(GroupClassSerializer(qs, many=True, context=ctx).data)


# ---------------------------------------------------------------------------
# Book / Cancel Class — POST /api/v2/classes/<id>/book/ and /cancel/
# ---------------------------------------------------------------------------

class ClassBookView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        # Booking requires connectivity — never offline-queued
        if not _check_active_membership(request.user):
            return Response(
                {'detail': 'Active membership required to book a class.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        with transaction.atomic():
            # Lock the class row to prevent concurrent over-booking
            try:
                cls = GroupClass.objects.select_for_update().get(
                    pk=pk, status=ClassStatus.SCHEDULED
                )
            except GroupClass.DoesNotExist:
                return Response({'detail': 'Class not found.'}, status=status.HTTP_404_NOT_FOUND)

            # Prevent double-booking
            if Booking.objects.filter(class_ref=cls, user=request.user).exclude(
                status=BookingStatus.CANCELLED
            ).exists():
                return Response({'detail': 'Already booked.'}, status=status.HTTP_409_CONFLICT)

            booked_count = cls.bookings.filter(status=BookingStatus.BOOKED).count()

            if booked_count < cls.capacity:
                booking = Booking.objects.create(
                    user=request.user, class_ref=cls, status=BookingStatus.BOOKED
                )
                Notification.objects.create(
                    user=request.user,
                    notif_type=NotificationType.BOOKING,
                    title='Booking Confirmed',
                    body=f'You are booked for {cls.title} at {cls.start_time.strftime("%H:%M")}.',
                    entity_type='GroupClass',
                    entity_id=str(cls.pk),
                )
                return Response(
                    BookingSerializer(booking).data, status=status.HTTP_201_CREATED
                )
            else:
                # Add to waitlist
                waitlist_pos = Booking.objects.filter(
                    class_ref=cls, status=BookingStatus.WAITLISTED
                ).count() + 1
                booking = Booking.objects.create(
                    user=request.user,
                    class_ref=cls,
                    status=BookingStatus.WAITLISTED,
                    waitlist_position=waitlist_pos,
                )
                return Response(
                    {**BookingSerializer(booking).data, 'message': 'Class full — added to waitlist'},
                    status=status.HTTP_202_ACCEPTED,
                )


class ClassCancelView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        with transaction.atomic():
            booking = Booking.objects.select_for_update().filter(
                class_ref_id=pk,
                user=request.user,
            ).exclude(status=BookingStatus.CANCELLED).first()

            if not booking:
                return Response({'detail': 'Booking not found.'}, status=status.HTTP_404_NOT_FOUND)

            booking.status = BookingStatus.CANCELLED
            booking.save(update_fields=['status'])

            # Promote next waitlisted user atomically in same transaction
            next_waitlisted = Booking.objects.select_for_update().filter(
                class_ref_id=pk,
                status=BookingStatus.WAITLISTED,
            ).order_by('waitlist_position').first()

            if next_waitlisted:
                next_waitlisted.status = BookingStatus.BOOKED
                next_waitlisted.waitlist_position = None
                next_waitlisted.save(update_fields=['status', 'waitlist_position'])
                Notification.objects.create(
                    user=next_waitlisted.user,
                    notif_type=NotificationType.BOOKING,
                    title='Waitlist Promoted!',
                    body=f'A spot opened up — you are now booked for {booking.class_ref.title}.',
                    entity_type='GroupClass',
                    entity_id=str(pk),
                )

        return Response({'cancelled': True})


# ---------------------------------------------------------------------------
# Private Sessions — POST /api/v2/private-sessions/
#                   PATCH /api/v2/private-sessions/<id>/
# ---------------------------------------------------------------------------

class PrivateSessionListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = PrivateSession.objects.filter(
            client=request.user
        ).select_related('trainer__user').order_by('-created_at')
        return Response(PrivateSessionSerializer(qs, many=True).data)

    def post(self, request):
        if not _check_active_membership(request.user):
            return Response(
                {'detail': 'Active membership required to book a session.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        serializer = PrivateSessionSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            session = serializer.save()
            return Response(PrivateSessionSerializer(session).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PrivateSessionDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            session = PrivateSession.objects.get(pk=pk, client=request.user)
        except PrivateSession.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(PrivateSessionSerializer(session).data)

    def patch(self, request, pk):
        """Client can only cancel their own pending sessions."""
        try:
            session = PrivateSession.objects.get(
                pk=pk, client=request.user, status=SessionStatus.REQUESTED
            )
        except PrivateSession.DoesNotExist:
            return Response({'detail': 'Not found or not cancellable.'}, status=status.HTTP_404_NOT_FOUND)
        session.status = SessionStatus.CANCELLED
        session.save(update_fields=['status'])
        return Response(PrivateSessionSerializer(session).data)


# ---------------------------------------------------------------------------
# Owner: Assign Trainer Profile — POST /api/v2/owner/trainers/
# ---------------------------------------------------------------------------

class OwnerTrainerAssignView(APIView):
    """Gym owner assigns a user as a trainer. Not self-granted."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        from wger.core.api.admin_permissions import IsGymOwner
        # Re-check owner permission inline
        if not hasattr(request.user, 'gym_owner_profile') or not request.user.gym_owner_profile.is_approved:
            return Response({'detail': 'Forbidden.'}, status=status.HTTP_403_FORBIDDEN)

        username = request.data.get('username', '').strip()
        gym_id   = request.user.gym_owner_profile.gym_id
        from django.contrib.auth.models import User as DjangoUser
        try:
            user = DjangoUser.objects.get(username=username)
        except DjangoUser.DoesNotExist:
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

        tp, created = TrainerProfile.objects.get_or_create(
            user=user,
            defaults={'gym_id': gym_id, 'is_accepting_bookings': True}
        )
        if not created:
            tp.gym_id = gym_id
            tp.is_accepting_bookings = True
            tp.save(update_fields=['gym_id', 'is_accepting_bookings'])

        return Response(TrainerProfileSerializer(tp).data,
                        status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
