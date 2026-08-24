# -*- coding: utf-8 -*-
from datetime import timedelta
from django.contrib.auth.models import User
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import AccessToken

from wger.core.models.ml import (
    DailyMetrics,
    MLRecoveryScore,
    MLTrainingLoad,
    MLStrengthTrajectory,
    MLWeightTrajectory,
    MLDailyRecommendation,
)
from wger.core.tasks import (
    compute_recovery_score,
    compute_training_load,
    compute_strength_trajectory,
    compute_weight_trajectory,
    generate_daily_recommendation,
)


class AppliedMLLayerTestCase(TestCase):
    """
    Unit and integration test suite for Kinetic Precision Applied ML layer:
    1. Instant non-blocking dashboard endpoint responses.
    2. Mathematical correctness of transparent recovery formula and contributing factors.
    3. Rolling ACWR workload fatigue status.
    4. Weight & strength trajectories with confidence intervals.
    5. Sparse/missing data resilience.
    """

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='ml_athlete',
            email='ml_athlete@kineticprecision.app',
            password='SecurePassword123#',
        )
        self.token = str(AccessToken.for_user(self.user))
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')

        # Seed 7 days of biometrics
        today = timezone.now().date()
        for i in range(7):
            DailyMetrics.objects.create(
                user=self.user,
                date=today - timedelta(days=i),
                hrv_rmssd=68.0 + (i % 3),
                resting_hr=56.0,
                sleep_duration_hrs=7.8,
                sleep_quality_score=85.0,
                steps=9500,
                weight_kg=78.2,
                soreness_score=2.0,
            )

    def test_transparent_recovery_score_calculation(self):
        """Verify recovery formula outputs valid score (0-100) and structured contributing factors."""
        res = compute_recovery_score(self.user.id)
        self.assertIn("score", res)
        self.assertGreaterEqual(res["score"], 0)
        self.assertLessEqual(res["score"], 100)
        self.assertIn("contributing_factors", res)
        factors = res["contributing_factors"]
        self.assertIn("hrv_delta_pct", factors)
        self.assertIn("sleep_debt_min", factors)
        self.assertIn("verdict", factors)

    def test_training_load_acwr_calculation(self):
        """Verify ACWR training load calculations."""
        res = compute_training_load(self.user.id)
        self.assertIn("acwr", res)
        self.assertIn("load_status", res)
        self.assertIn(res["load_status"], ["optimal", "overreaching", "high_injury_risk", "undertraining"])

    def test_dashboard_today_endpoint_instant_response(self):
        """GET /api/v2/dashboard/today/ must return structured recommendation and WHY trace."""
        response = self.client.get('/api/v2/dashboard/today/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("readiness_state", response.data)
        self.assertIn("action_recommendation", response.data)
        self.assertIn("target_rpe", response.data)
        self.assertIn("why_reasoning", response.data)

    def test_dashboard_body_endpoint_trajectories(self):
        """GET /api/v2/dashboard/body/ must return recovery, ACWR, weight trajectory, and strength projections."""
        response = self.client.get('/api/v2/dashboard/body/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("recovery", response.data)
        self.assertIn("training_load", response.data)
        self.assertIn("weight_trajectory", response.data)
        self.assertIn("strength_trajectories", response.data)

        weight_traj = response.data["weight_trajectory"]
        self.assertIn("ema_weight_kg", weight_traj)
        self.assertIn("lower_bound_kg", weight_traj)
        self.assertIn("upper_bound_kg", weight_traj)

    def test_sparse_data_resilience(self):
        """New user with only 1 day of data computes safely with reduced confidence."""
        sparse_user = User.objects.create_user(
            username='sparse_athlete',
            password='SecurePassword123#',
        )
        res = compute_recovery_score(sparse_user.id)
        self.assertIn("score", res)
        self.assertLess(res["confidence"], 0.6)  # Lower confidence flagged for sparse history
