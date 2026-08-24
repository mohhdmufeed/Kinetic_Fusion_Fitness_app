# -*- coding: utf-8 -*-
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class DailyMetrics(models.Model):
    """
    Ingested daily biometric time-series data for ML pipeline feature extraction.
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='daily_metrics')
    date = models.DateField(db_index=True)
    hrv_rmssd = models.FloatField(null=True, blank=True, help_text="Root mean square of successive RR interval differences (ms)")
    resting_hr = models.FloatField(null=True, blank=True, help_text="Resting heart rate (bpm)")
    sleep_duration_hrs = models.FloatField(null=True, blank=True, help_text="Total sleep duration in hours")
    sleep_quality_score = models.FloatField(null=True, blank=True, help_text="Subjective/device sleep score (0-100)")
    steps = models.IntegerField(null=True, blank=True, help_text="Daily step count")
    weight_kg = models.FloatField(null=True, blank=True, help_text="Morning body weight in kilograms")
    soreness_score = models.FloatField(null=True, blank=True, help_text="Subjective muscle soreness (1-10)")
    raw_payload = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date']
        unique_together = ('user', 'date')
        verbose_name = 'Daily Metrics'
        verbose_name_plural = 'Daily Metrics'

    def __str__(self):
        return f"DailyMetrics({self.user.username} @ {self.date})"


class MLRecoveryScore(models.Model):
    """
    Pre-computed transparent statistical recovery score with full contributing factors explanation.
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='recovery_scores')
    date = models.DateField(db_index=True)
    score = models.IntegerField(help_text="Recovery score (0-100)")
    confidence = models.FloatField(default=1.0, help_text="Confidence based on data completeness (0.0 - 1.0)")
    contributing_factors = models.JSONField(
        default=dict,
        help_text="Structured factors explaining score: hrv_delta_pct, sleep_debt_min, load_yesterday, verdict"
    )
    recovery_model_version = models.CharField(max_length=32, default="v1.2-stat-transparent")
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-date']
        unique_together = ('user', 'date')
        verbose_name = 'ML Recovery Score'
        verbose_name_plural = 'ML Recovery Scores'

    def __str__(self):
        return f"MLRecoveryScore({self.user.username} @ {self.date}: {self.score}% [{self.recovery_model_version}])"


class MLTrainingLoad(models.Model):
    """
    Pre-computed rolling Acute:Chronic Workload Ratio (ACWR) and fatigue balance.
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='training_loads')
    date = models.DateField(db_index=True)
    acute_load_7d = models.FloatField(default=0.0, help_text="7-day rolling volume/RPE fatigue load")
    chronic_load_28d = models.FloatField(default=0.0, help_text="28-day rolling volume/RPE fitness load")
    acwr = models.FloatField(default=1.0, help_text="Acute:Chronic Workload Ratio")
    load_status = models.CharField(
        max_length=32,
        default="optimal",
        help_text="optimal (0.8-1.3), overreaching (1.3-1.5), high_injury_risk (>1.5), undertraining (<0.8)"
    )
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-date']
        unique_together = ('user', 'date')
        verbose_name = 'ML Training Load'
        verbose_name_plural = 'ML Training Loads'

    def __str__(self):
        return f"MLTrainingLoad({self.user.username} @ {self.date}: ACWR={self.acwr:.2f} [{self.load_status}])"


class MLStrengthTrajectory(models.Model):
    """
    Robust regression on working-set estimated 1RM per compound exercise with forward projections.
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='strength_trajectories')
    exercise_name = models.CharField(max_length=128, db_index=True)
    current_e1rm_kg = models.FloatField(help_text="Current Estimated 1RM in kg")
    projected_e1rm_4w_kg = models.FloatField(help_text="Projected Estimated 1RM in 4 weeks")
    rate_of_change_kg_per_week = models.FloatField(help_text="Rate of progression (kg/week)")
    weeks_to_next_benchmark = models.FloatField(null=True, blank=True, help_text="Estimated weeks to target benchmark")
    confidence = models.FloatField(default=0.85)
    trajectory_json = models.JSONField(default=dict, help_text="Historical and projected points for chart rendering")
    model_version = models.CharField(max_length=32, default="v1.0-theil-sen-robust")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['exercise_name']
        unique_together = ('user', 'exercise_name')
        verbose_name = 'ML Strength Trajectory'
        verbose_name_plural = 'ML Strength Trajectories'

    def __str__(self):
        return f"MLStrengthTrajectory({self.user.username} - {self.exercise_name}: {self.current_e1rm_kg}kg -> {self.projected_e1rm_4w_kg}kg)"


class MLWeightTrajectory(models.Model):
    """
    Exponential moving average (EMA) trend and linear slope with 95% confidence interval bands.
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='weight_trajectories')
    date = models.DateField(db_index=True)
    current_weight_kg = models.FloatField()
    ema_weight_kg = models.FloatField(help_text="Smoothed exponential moving average weight")
    slope_kg_per_week = models.FloatField(help_text="Weekly rate of weight change (kg/week)")
    lower_bound_kg = models.FloatField(help_text="Lower 95% confidence bound")
    upper_bound_kg = models.FloatField(help_text="Upper 95% confidence bound")
    trajectory_json = models.JSONField(default=dict, help_text="Series data for confidence-band chart rendering")
    model_version = models.CharField(max_length=32, default="v1.0-ema-kalman-hybrid")
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-date']
        unique_together = ('user', 'date')
        verbose_name = 'ML Weight Trajectory'
        verbose_name_plural = 'ML Weight Trajectories'

    def __str__(self):
        return f"MLWeightTrajectory({self.user.username} @ {self.date}: EMA={self.ema_weight_kg:.1f}kg, Slope={self.slope_kg_per_week:.2f}kg/wk)"


class MLDailyRecommendation(models.Model):
    """
    Daily high-performance training prescription combining recovery, load, and progression models.
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='daily_recommendations')
    date = models.DateField(db_index=True)
    readiness_state = models.CharField(max_length=32, default="Optimal Readiness")
    action_recommendation = models.CharField(max_length=64, default="Train as Prescribed")
    target_rpe = models.FloatField(default=8.0)
    volume_adjustment_pct = models.IntegerField(default=0, help_text="e.g. +0%, -20%, +10%")
    why_reasoning_json = models.JSONField(
        default=dict,
        help_text="Comprehensive structured reasoning backing the daily recommendation"
    )
    model_version = models.CharField(max_length=32, default="v1.3-composite-heuristic")
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-date']
        unique_together = ('user', 'date')
        verbose_name = 'ML Daily Recommendation'
        verbose_name_plural = 'ML Daily Recommendations'

    def __str__(self):
        return f"MLDailyRecommendation({self.user.username} @ {self.date}: {self.action_recommendation})"
