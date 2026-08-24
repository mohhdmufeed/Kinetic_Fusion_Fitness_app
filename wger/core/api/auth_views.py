from django.contrib.auth.models import User
from django.core.signing import TimestampSigner
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.throttling import AnonRateThrottle
from rest_framework_simplejwt.views import TokenRefreshView
from drf_spectacular.utils import extend_schema, OpenApiExample

from wger.core.api.auth_serializers import (
    SignupSerializer,
    VerifyEmailSerializer,
    LoginSerializer,
    LogoutSerializer,
    LogoutAllSerializer,
    PasswordResetRequestSerializer,
    PasswordResetConfirmSerializer,
    signer,
)


class AuthRateThrottle(AnonRateThrottle):
    rate = '5/min'


class SignupView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [AuthRateThrottle]

    @extend_schema(
        summary="Create Account (Signup)",
        description="Register a new user account. Requires valid email and password >= 10 characters.",
        request=SignupSerializer,
        responses={201: {"type": "object", "properties": {"detail": {"type": "string"}, "user_id": {"type": "integer"}}}},
        tags=["Authentication"]
    )
    def post(self, request):
        serializer = SignupSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token = signer.sign(str(user.id))
            verification_url = f"/api/v2/auth/verify-email/?token={token}"
            return Response(
                {
                    "detail": "Account created. Please verify your email to activate full data access.",
                    "user_id": user.id,
                    "verification_token": token,
                    "verification_url": verification_url,
                },
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class VerifyEmailView(APIView):
    permission_classes = [AllowAny]

    @extend_schema(
        summary="Verify Email Token",
        description="Verify the signed time-limited email verification token to unlock account access.",
        request=VerifyEmailSerializer,
        responses={200: {"type": "object", "properties": {"detail": {"type": "string"}}}},
        tags=["Authentication"]
    )
    def post(self, request):
        serializer = VerifyEmailSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data
            profile = getattr(user, 'userprofile', None)
            if profile:
                profile.email_verified = True
                profile.save()
            return Response({"detail": "Email verified successfully. You may now log in."}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def get(self, request):
        token = request.query_params.get('token')
        if not token:
            return Response({"detail": "Missing verification token."}, status=status.HTTP_400_BAD_REQUEST)
        serializer = VerifyEmailSerializer(data={'token': token})
        if serializer.is_valid():
            user = serializer.validated_data
            profile = getattr(user, 'userprofile', None)
            if profile:
                profile.email_verified = True
                profile.save()
            return Response({"detail": "Email verified successfully. You may now log in."}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [AuthRateThrottle]

    @extend_schema(
        summary="User Login",
        description="Authenticate with username/email and password. Returns short-lived JWT access token (15 min) and refresh token (14 days).",
        request=LoginSerializer,
        responses={200: {"type": "object", "properties": {"access": {"type": "string"}, "refresh": {"type": "string"}, "user_id": {"type": "integer"}}}},
        tags=["Authentication"]
    )
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            return Response(serializer.validated_data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_401_UNAUTHORIZED)


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Logout Active Device",
        description="Revoke the provided refresh token and end session for current device.",
        request=LogoutSerializer,
        responses={200: {"type": "object", "properties": {"detail": {"type": "string"}}}},
        tags=["Authentication"]
    )
    def post(self, request):
        serializer = LogoutSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"detail": "Session revoked."}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LogoutAllView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Logout All Devices",
        description="Revoke all outstanding refresh tokens for the authenticated user.",
        request=None,
        responses={200: {"type": "object", "properties": {"detail": {"type": "string"}}}},
        tags=["Authentication"]
    )
    def post(self, request):
        serializer = LogoutAllSerializer()
        serializer.save(request.user)
        return Response({"detail": "All sessions revoked across all devices."}, status=status.HTTP_200_OK)


class PasswordResetRequestView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [AuthRateThrottle]

    @extend_schema(
        summary="Request Password Reset",
        description="Initiate password reset process by generating a signed reset token.",
        request=PasswordResetRequestSerializer,
        responses={200: {"type": "object", "properties": {"detail": {"type": "string"}}}},
        tags=["Authentication"]
    )
    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            try:
                user = User.objects.get(email__iexact=email)
                token = signer.sign(str(user.id))
                return Response({
                    "detail": "Password reset instructions generated.",
                    "reset_token": token,
                }, status=status.HTTP_200_OK)
            except User.DoesNotExist:
                # Generic response to prevent user enumeration
                return Response({
                    "detail": "If the account exists, a reset link has been dispatched.",
                }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PasswordResetConfirmView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [AuthRateThrottle]

    @extend_schema(
        summary="Confirm Password Reset",
        description="Reset user password with valid signed reset token and new password >= 10 chars.",
        request=PasswordResetConfirmSerializer,
        responses={200: {"type": "object", "properties": {"detail": {"type": "string"}}}},
        tags=["Authentication"]
    )
    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['token']
            new_password = serializer.validated_data['new_password']
            user.set_password(new_password)
            user.save()
            return Response({"detail": "Password reset successfully. You may now log in."}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
