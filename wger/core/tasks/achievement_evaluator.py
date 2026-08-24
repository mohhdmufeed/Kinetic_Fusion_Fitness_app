# -*- coding: utf-8 -*-
"""
Module 15 — Achievement Evaluation Celery Task
Runs after every successful sync push and nightly via celery beat.
Achievements are ONLY written here — never by client requests.
"""
from celery import shared_task
from django.contrib.auth.models import User
from django.utils import timezone


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def evaluate_achievements(self, user_id: int, triggered_date: str = None):
    """
    Evaluate all active Achievement rules for a given user and unlock any
    newly-qualifying achievements.  Idempotent — calling twice never creates
    duplicates (unique_together on UserAchievement).
    """
    from wger.core.models import (
        Achievement, UserAchievement, AchievementRuleType,
    )
    from wger.social.models import Notification, NotificationType

    try:
        user = User.objects.get(pk=user_id)
    except User.DoesNotExist:
        return

    date = timezone.now().date()

    already_unlocked = set(
        UserAchievement.objects.filter(user=user).values_list('achievement_id', flat=True)
    )

    for achievement in Achievement.objects.filter(is_active=True).exclude(pk__in=already_unlocked):
        if _evaluate_rule(user, achievement):
            try:
                UserAchievement.objects.create(user=user, achievement=achievement)
                Notification.objects.create(
                    user=user,
                    notif_type=NotificationType.ACHIEVEMENT,
                    title='Achievement Unlocked!',
                    body=f'You earned: {achievement.title}',
                    entity_type='Achievement',
                    entity_id=str(achievement.pk),
                )
            except Exception:
                # unique_together constraint prevents duplicate — safe to ignore
                pass


def _evaluate_rule(user, achievement) -> bool:
    """
    Return True iff the user satisfies the achievement's rule.
    Add new rule_type branches here as new achievement types are introduced.
    """
    from wger.core.models import AchievementRuleType
    from django.db.models import Count

    rule = achievement.rule_type
    threshold = achievement.threshold

    if rule == AchievementRuleType.WORKOUT_COUNT:
        from wger.manager.models import WorkoutSession
        count = WorkoutSession.objects.filter(user=user).count()
        return count >= threshold

    elif rule == AchievementRuleType.STREAK_DAYS:
        # Check that the user has logged workouts on consecutive days >= threshold
        from wger.manager.models import WorkoutSession
        from datetime import timedelta
        dates = list(
            WorkoutSession.objects.filter(user=user)
            .order_by('-date')
            .values_list('date', flat=True)
            .distinct()
        )
        if not dates:
            return False
        streak = 1
        for i in range(1, len(dates)):
            if (dates[i - 1] - dates[i]).days == 1:
                streak += 1
                if streak >= threshold:
                    return True
            else:
                streak = 1
        return streak >= threshold

    elif rule == AchievementRuleType.CLASS_ATTENDED:
        from wger.core.models import Booking, BookingStatus
        count = Booking.objects.filter(user=user, status=BookingStatus.BOOKED).count()
        return count >= threshold

    elif rule == AchievementRuleType.NUTRITION_STREAK:
        # Check nutrition diary entries on consecutive days
        from wger.nutrition.models import LogItem
        from datetime import timedelta
        dates = list(
            LogItem.objects.filter(plan__user=user)
            .order_by('-datetime__date')
            .values_list('datetime__date', flat=True)
            .distinct()
        )
        if not dates:
            return False
        streak = 1
        for i in range(1, len(dates)):
            if (dates[i - 1] - dates[i]).days == 1:
                streak += 1
                if streak >= threshold:
                    return True
            else:
                streak = 1
        return streak >= threshold

    elif rule == AchievementRuleType.BENCHMARK_HIT:
        # Placeholder: check if user has a PRs logged
        from wger.manager.models import WorkoutLog
        count = WorkoutLog.objects.filter(user=user).count()
        return count >= threshold

    # Unknown rule type — don't unlock
    return False
