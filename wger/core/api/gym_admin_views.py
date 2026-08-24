# -*- coding: utf-8 -*-
from datetime import timedelta
from django.contrib.auth.models import User
from django.db.models import Q
from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema, OpenApiParameter

from wger.core.models.admin import AdminAuditLog
from wger.core.models.gym_admin import (
    ProgramSchedule,
    ProgramDay,
    ProgramExercise,
    ClientMembership,
    BodyStatEntry,
)
from wger.core.models.ml import DailyMetrics
from wger.exercises.models import Exercise
from wger.manager.models import Routine, Day
from wger.core.api.admin_permissions import IsSuperAdmin


def get_client_ip(request):
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        return x_forwarded_for.split(',')[0].strip()
    return request.META.get('REMOTE_ADDR', '127.0.0.1')


class AdminClientListCreateView(APIView):
    """
    Searchable and sortable client membership management table for Gym Owner / Trainer.
    days_remaining is computed live against real time.
    """
    permission_classes = [IsSuperAdmin]

    @extend_schema(
        summary="Admin Client List",
        description="Searchable and sortable member list with live computed days_remaining.",
        parameters=[
            OpenApiParameter("q", type=str, description="Search by client name, email, or phone"),
            OpenApiParameter("status", type=str, description="Filter: active | expiring | lapsed"),
        ],
        tags=["Super Admin Gym Management"]
    )
    def get(self, request):
        query = request.query_params.get('q', '').strip()
        status_filter = request.query_params.get('status', '').strip().lower()

        memberships = ClientMembership.objects.select_related('user', 'assigned_trainer', 'active_program')

        if query:
            memberships = memberships.filter(
                Q(user__username__icontains=query) |
                Q(user__first_name__icontains=query) |
                Q(user__last_name__icontains=query) |
                Q(user__email__icontains=query) |
                Q(phone_number__icontains=query)
            )

        results = []
        for m in memberships:
            days_rem = m.days_remaining
            alert_status = 'active'
            if days_rem < 0:
                alert_status = 'lapsed'
            elif days_rem <= 7:
                alert_status = 'expiring'

            if status_filter and alert_status != status_filter:
                continue

            results.append({
                "id": m.user.id,
                "membership_id": m.id,
                "username": m.user.username,
                "full_name": m.user.get_full_name() or m.user.username,
                "email": m.user.email,
                "phone_number": m.phone_number,
                "membership_start_date": m.membership_start_date.isoformat(),
                "membership_end_date": m.membership_end_date.isoformat(),
                "membership_duration_days": m.membership_duration_days,
                "days_remaining": days_rem,
                "alert_status": alert_status,
                "assigned_trainer": m.assigned_trainer.get_full_name() if m.assigned_trainer else None,
                "active_program": m.active_program.name if m.active_program else None,
                "notes": m.notes,
            })

        return Response({
            "count": len(results),
            "results": results,
        }, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Create Client & Membership",
        description="Creates an athlete user account and client membership record.",
        tags=["Super Admin Gym Management"]
    )
    def post(self, request):
        admin_user = request.user
        username = request.data.get('username')
        email = request.data.get('email')
        password = request.data.get('password', 'KineticAthlete123#')
        first_name = request.data.get('first_name', '')
        last_name = request.data.get('last_name', '')
        phone = request.data.get('phone_number', '')
        start_date_str = request.data.get('membership_start_date')
        end_date_str = request.data.get('membership_end_date')
        duration_days = int(request.data.get('duration_days', 30))
        notes = request.data.get('notes', '')

        if not username or not email:
            return Response({"detail": "Username and email are required."}, status=status.HTTP_400_BAD_REQUEST)

        start_date = parse_date(start_date_str) if start_date_str else timezone.now().date()
        end_date = parse_date(end_date_str) if end_date_str else start_date + timedelta(days=duration_days)

        user, created = User.objects.get_or_create(
            username=username,
            defaults={
                'email': email,
                'first_name': first_name,
                'last_name': last_name,
            }
        )
        if created:
            user.set_password(password)
            user.save()

        membership, _ = ClientMembership.objects.update_or_create(
            user=user,
            defaults={
                'phone_number': phone,
                'membership_start_date': start_date,
                'membership_end_date': end_date,
                'assigned_trainer': admin_user,
                'notes': notes,
            }
        )

        AdminAuditLog.objects.create(
            actor=admin_user,
            action_type='create',
            target_model='ClientMembership',
            target_id=str(membership.id),
            details={
                'client_username': user.username,
                'membership_end_date': end_date.isoformat(),
                'days_remaining': membership.days_remaining,
            },
            ip_address=get_client_ip(request),
        )

        return Response({
            "status": "success",
            "client_id": user.id,
            "username": user.username,
            "days_remaining": membership.days_remaining,
        }, status=status.HTTP_201_CREATED)


class AdminClientDetailView(APIView):
    """
    Two-pane detail view for managing a specific gym client:
    Pane 1: Client profile & membership dates
    Pane 2: Currently assigned program schedule & description
    Bottom: Body stats measurement history
    """
    permission_classes = [IsSuperAdmin]

    @extend_schema(
        summary="Admin Client Two-Pane Detail",
        description="Returns client profile, membership, active program, and full body stats timeline.",
        tags=["Super Admin Gym Management"]
    )
    def get(self, request, client_id):
        try:
            user = User.objects.get(pk=client_id)
            membership, _ = ClientMembership.objects.get_or_create(
                user=user,
                defaults={
                    'membership_start_date': timezone.now().date(),
                    'membership_end_date': timezone.now().date() + timedelta(days=30),
                }
            )
        except User.DoesNotExist:
            return Response({"detail": "Client not found."}, status=status.HTTP_404_NOT_FOUND)

        # Active Program Breakdown
        program_data = None
        if membership.active_program:
            prog = membership.active_program
            days_list = []
            for d in prog.days.prefetch_related('exercises').all():
                ex_list = [
                    {
                        "id": ex.id,
                        "exercise_name": ex.exercise_name,
                        "target_muscle": ex.target_muscle,
                        "sets": ex.sets,
                        "reps": ex.reps,
                        "technique": ex.technique,
                    }
                    for ex in d.exercises.all()
                ]
                days_list.append({
                    "day_number": d.day_number,
                    "label": d.label,
                    "exercises": ex_list,
                })
            program_data = {
                "id": prog.id,
                "name": prog.name,
                "version": prog.version,
                "description": prog.description,
                "days": days_list,
            }

        # Body Stats History
        stats_qs = BodyStatEntry.objects.filter(client=user).order_by('-recorded_date', '-created_at')
        stats_history = [
            {
                "id": s.id,
                "recorded_date": s.recorded_date.isoformat(),
                "recorded_by_type": s.recorded_by_type,
                "height_cm": s.height_cm,
                "weight_kg": s.weight_kg,
                "shoulder_cm": s.shoulder_cm,
                "chest_cm": s.chest_cm,
                "arm_cm": s.arm_cm,
                "waist_cm": s.waist_cm,
                "hip_cm": s.hip_cm,
                "thigh_cm": s.thigh_cm,
                "calf_cm": s.calf_cm,
                "note": s.note,
            }
            for s in stats_qs
        ]

        return Response({
            "client": {
                "id": user.id,
                "username": user.username,
                "full_name": user.get_full_name() or user.username,
                "email": user.email,
                "phone_number": membership.phone_number,
                "membership_start_date": membership.membership_start_date.isoformat(),
                "membership_end_date": membership.membership_end_date.isoformat(),
                "membership_duration_days": membership.membership_duration_days,
                "days_remaining": membership.days_remaining,
                "notes": membership.notes,
            },
            "active_program": program_data,
            "body_stats_history": stats_history,
        }, status=status.HTTP_200_OK)

    def put(self, request, client_id):
        admin_user = request.user
        try:
            user = User.objects.get(pk=client_id)
            membership = ClientMembership.objects.get(user=user)
        except (User.DoesNotExist, ClientMembership.DoesNotExist):
            return Response({"detail": "Client not found."}, status=status.HTTP_404_NOT_FOUND)

        old_end = membership.membership_end_date.isoformat()
        if 'phone_number' in request.data:
            membership.phone_number = request.data['phone_number']
        if 'membership_start_date' in request.data:
            membership.membership_start_date = parse_date(request.data['membership_start_date'])
        if 'membership_end_date' in request.data:
            membership.membership_end_date = parse_date(request.data['membership_end_date'])
        if 'notes' in request.data:
            membership.notes = request.data['notes']
        membership.save()

        AdminAuditLog.objects.create(
            actor=admin_user,
            action_type='update',
            target_model='ClientMembership',
            target_id=str(membership.id),
            details={
                'client_username': user.username,
                'old_end_date': old_end,
                'new_end_date': membership.membership_end_date.isoformat(),
                'days_remaining': membership.days_remaining,
            },
            ip_address=get_client_ip(request),
        )

        return Response({
            "status": "success",
            "days_remaining": membership.days_remaining,
            "membership_end_date": membership.membership_end_date.isoformat(),
        }, status=status.HTTP_200_OK)

    def delete(self, request, client_id):
        admin_user = request.user
        try:
            user = User.objects.get(pk=client_id)
        except User.DoesNotExist:
            return Response({"detail": "Client not found."}, status=status.HTTP_404_NOT_FOUND)

        username = user.username
        user.is_active = False
        user.save()

        AdminAuditLog.objects.create(
            actor=admin_user,
            action_type='deactivate',
            target_model='User',
            target_id=str(user.id),
            details={'username': username, 'status': 'deactivated'},
            ip_address=get_client_ip(request),
        )

        return Response({"status": "success", "message": f"Client {username} deactivated."}, status=status.HTTP_200_OK)


class AdminClientBodyStatsView(APIView):
    """
    Append-only body stats recording for in-person trainer sessions.
    Automatically syncs weight_kg to DailyMetrics so it appears in the athlete's progress charts.
    """
    permission_classes = [IsSuperAdmin]

    @extend_schema(
        summary="Record In-Person Body Stats",
        description="Records append-only body circumference measurements and weight.",
        tags=["Super Admin Gym Management"]
    )
    def post(self, request, client_id):
        admin_user = request.user
        try:
            client = User.objects.get(pk=client_id)
        except User.DoesNotExist:
            return Response({"detail": "Client not found."}, status=status.HTTP_404_NOT_FOUND)

        date_str = request.data.get('recorded_date')
        rec_date = parse_date(date_str) if date_str else timezone.now().date()

        stat = BodyStatEntry.objects.create(
            client=client,
            recorded_date=rec_date,
            recorded_by_type='admin',
            recorded_by_user=admin_user,
            height_cm=request.data.get('height_cm'),
            weight_kg=request.data.get('weight_kg'),
            shoulder_cm=request.data.get('shoulder_cm'),
            chest_cm=request.data.get('chest_cm'),
            arm_cm=request.data.get('arm_cm'),
            waist_cm=request.data.get('waist_cm'),
            hip_cm=request.data.get('hip_cm'),
            thigh_cm=request.data.get('thigh_cm'),
            calf_cm=request.data.get('calf_cm'),
            note=request.data.get('note', ''),
        )

        # Sync weight into DailyMetrics
        if stat.weight_kg:
            daily, _ = DailyMetrics.objects.get_or_create(user=client, date=rec_date)
            daily.weight_kg = stat.weight_kg
            daily.save()

        AdminAuditLog.objects.create(
            actor=admin_user,
            action_type='create',
            target_model='BodyStatEntry',
            target_id=str(stat.id),
            details={
                'client': client.username,
                'weight_kg': stat.weight_kg,
                'waist_cm': stat.waist_cm,
                'note': stat.note,
            },
            ip_address=get_client_ip(request),
        )

        return Response({
            "status": "success",
            "stat_id": stat.id,
            "recorded_date": stat.recorded_date.isoformat(),
            "weight_kg": stat.weight_kg,
            "waist_cm": stat.waist_cm,
        }, status=status.HTTP_201_CREATED)


class AdminScheduleListCreateView(APIView):
    """
    List & Create versioned multi-day program schedules.
    """
    permission_classes = [IsSuperAdmin]

    @extend_schema(
        summary="Admin Workout Schedules List",
        description="Returns all versioned multi-day workout schedules authored by trainers.",
        tags=["Super Admin Gym Management"]
    )
    def get(self, request):
        schedules = ProgramSchedule.objects.prefetch_related('days__exercises').all()
        results = [
            {
                "id": s.id,
                "name": s.name,
                "version": s.version,
                "description": s.description,
                "days_count": s.days.count(),
                "created_by": s.created_by.get_full_name() if s.created_by else 'Admin',
                "enrolled_count": s.enrolled_clients.count(),
            }
            for s in schedules
        ]
        return Response({"count": len(results), "results": results}, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Create Workout Schedule",
        description="Creates a new versioned multi-day program schedule.",
        tags=["Super Admin Gym Management"]
    )
    def post(self, request):
        admin_user = request.user
        name = request.data.get('name')
        description = request.data.get('description', '')
        days_data = request.data.get('days', [])

        if not name:
            return Response({"detail": "Program name is required."}, status=status.HTTP_400_BAD_REQUEST)

        schedule = ProgramSchedule.objects.create(
            name=name,
            description=description,
            created_by=admin_user,
            version=1,
        )

        for d_info in days_data:
            day_num = d_info.get('day_number', 1)
            label = d_info.get('label', f'Day {day_num}')
            p_day = ProgramDay.objects.create(schedule=schedule, day_number=day_num, label=label)

            for ex_info in d_info.get('exercises', []):
                ex_id = ex_info.get('exercise_id')
                if ex_id:
                    ex_obj = Exercise.objects.filter(pk=ex_id).first()
                    if ex_obj:
                        ProgramExercise.objects.create(
                            program_day=p_day,
                            exercise=ex_obj,
                            sets=int(ex_info.get('sets', 3)),
                            reps=str(ex_info.get('reps', '8-12')),
                            technique=ex_info.get('technique', 'normal'),
                            order=int(ex_info.get('order', 0)),
                        )

        AdminAuditLog.objects.create(
            actor=admin_user,
            action_type='create',
            target_model='ProgramSchedule',
            target_id=str(schedule.id),
            details={'name': schedule.name, 'version': schedule.version},
            ip_address=get_client_ip(request),
        )

        return Response({
            "status": "success",
            "schedule_id": schedule.id,
            "name": schedule.name,
            "version": schedule.version,
        }, status=status.HTTP_201_CREATED)


class AdminScheduleDetailView(APIView):
    """
    Detailed Day 1..N card breakdown for a specific program schedule.
    """
    permission_classes = [IsSuperAdmin]

    def get(self, request, schedule_id):
        try:
            s = ProgramSchedule.objects.get(pk=schedule_id)
        except ProgramSchedule.DoesNotExist:
            return Response({"detail": "Program schedule not found."}, status=status.HTTP_404_NOT_FOUND)

        days_list = []
        for d in s.days.prefetch_related('exercises__exercise').all():
            ex_list = [
                {
                    "id": ex.id,
                    "exercise_id": ex.exercise.id,
                    "exercise_name": ex.exercise_name,
                    "target_muscle": ex.target_muscle,
                    "sets": ex.sets,
                    "reps": ex.reps,
                    "technique": ex.technique,
                    "order": ex.order,
                }
                for ex in d.exercises.all()
            ]
            days_list.append({
                "day_id": d.id,
                "day_number": d.day_number,
                "label": d.label,
                "exercises": ex_list,
            })

        return Response({
            "id": s.id,
            "name": s.name,
            "version": s.version,
            "description": s.description,
            "days": days_list,
        }, status=status.HTTP_200_OK)


class AdminScheduleDayExerciseCreateView(APIView):
    """
    Adds an exercise to a program day, strictly selecting from the shared Module 6 Exercise Library.
    """
    permission_classes = [IsSuperAdmin]

    def post(self, request, schedule_id, day_number):
        try:
            s = ProgramSchedule.objects.get(pk=schedule_id)
            p_day, _ = ProgramDay.objects.get_or_create(
                schedule=s,
                day_number=int(day_number),
                defaults={'label': f'Day {day_number}'}
            )
        except ProgramSchedule.DoesNotExist:
            return Response({"detail": "Schedule not found."}, status=status.HTTP_404_NOT_FOUND)

        exercise_id = request.data.get('exercise_id')
        try:
            ex_obj = Exercise.objects.get(pk=exercise_id)
        except Exercise.DoesNotExist:
            return Response({"detail": "Exercise not found in library."}, status=status.HTTP_400_BAD_REQUEST)

        sets = int(request.data.get('sets', 3))
        reps = str(request.data.get('reps', '8-12'))
        technique = request.data.get('technique', 'normal')

        p_ex = ProgramExercise.objects.create(
            program_day=p_day,
            exercise=ex_obj,
            sets=sets,
            reps=reps,
            technique=technique,
            order=p_day.exercises.count(),
        )

        return Response({
            "status": "success",
            "exercise_id": p_ex.id,
            "exercise_name": p_ex.exercise_name,
            "target_muscle": p_ex.target_muscle,
            "sets": p_ex.sets,
            "reps": p_ex.reps,
            "technique": p_ex.technique,
        }, status=status.HTTP_201_CREATED)


class AdminAssignScheduleView(APIView):
    """
    Assigns a ProgramSchedule to a client, triggers mobile sync to their Train tab,
    and records an immutable audit log.
    """
    permission_classes = [IsSuperAdmin]

    @extend_schema(
        summary="Assign Program Schedule to Client",
        description="Assigns a versioned program schedule to an athlete and syncs into their active routine.",
        tags=["Super Admin Gym Management"]
    )
    def post(self, request, client_id):
        admin_user = request.user
        schedule_id = request.data.get('schedule_id')

        try:
            client = User.objects.get(pk=client_id)
            membership, _ = ClientMembership.objects.get_or_create(user=client)
            schedule = ProgramSchedule.objects.get(pk=schedule_id)
        except (User.DoesNotExist, ProgramSchedule.DoesNotExist):
            return Response({"detail": "Client or schedule not found."}, status=status.HTTP_404_NOT_FOUND)

        # Assign to membership
        membership.active_program = schedule
        membership.save()

        # Mirror program into Client's active Routine for the Train tab
        routine, _ = Routine.objects.get_or_create(
            user=client,
            name=f"{schedule.name} (Assigned)",
        )

        # Clear old routine days to mirror cleanly
        Day.objects.filter(routine=routine).delete()

        # Copy days
        for p_day in schedule.days.all():
            Day.objects.create(
                routine=routine,
                description=p_day.label,
                day=[p_day.day_number] if p_day.day_number <= 7 else [1],
            )

        AdminAuditLog.objects.create(
            actor=admin_user,
            action_type='assign_schedule',
            target_model='ClientMembership',
            target_id=str(membership.id),
            details={
                'client': client.username,
                'program_name': schedule.name,
                'version': schedule.version,
            },
            ip_address=get_client_ip(request),
        )

        return Response({
            "status": "success",
            "message": f"Assigned {schedule.name} (v{schedule.version}) to {client.username}.",
            "client_id": client.id,
            "schedule_id": schedule.id,
            "routine_id": routine.id,
        }, status=status.HTTP_200_OK)
