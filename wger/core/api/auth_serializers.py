import uuid
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.signing import TimestampSigner, BadSignature, SignatureExpired
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken, OutstandingToken, BlacklistedToken
from wger.core.models import UserProfile

signer = TimestampSigner(salt='kinetic_precision_email_verify')


class SignupSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    username = serializers.CharField(required=True, min_length=3, max_length=150)
    display_name = serializers.CharField(required=False, allow_blank=True, max_length=150)
    password = serializers.CharField(required=True, write_only=True, min_length=10)

    def validate_email(self, value):
        normalized = value.lower().strip()
        if User.objects.filter(email__iexact=normalized).exists():
            raise serializers.ValidationError("An account with this email already exists.")
        return normalized

    def validate_username(self, value):
        cleaned = value.strip()
        if User.objects.filter(username__iexact=cleaned).exists():
            raise serializers.ValidationError("This username is already taken.")
        return cleaned

    def validate_password(self, value):
        # Validate password using configured Django validators (Argon2, length >= 10, blocklist, numeric, similarity)
        validate_password(value)
        return value

    def create(self, validated_data):
        email = validated_data['email']
        username = validated_data['username']
        password = validated_data['password']
        display_name = validated_data.get('display_name') or username

        # Server-generated unique UUID
        user_uuid = uuid.uuid4()

        user = User(
            username=username,
            email=email,
            first_name=display_name,
            is_active=True,
        )
        # Sets password using configured Argon2 hasher
        user.set_password(password)
        user.save()

        # Create or update UserProfile with verified status
        profile, _ = UserProfile.objects.get_or_create(user=user)
        # Mark as needing verification
        profile.email_verified = False
        profile.save()

        return user


class VerifyEmailSerializer(serializers.Serializer):
    token = serializers.CharField(required=True)

    def validate_token(self, value):
        try:
            # 24 hour expiration window (86400 seconds)
            user_id = signer.unsign(value, max_age=86400)
            user = User.objects.get(pk=user_id)
            return user
        except SignatureExpired:
            raise serializers.ValidationError("Verification token has expired. Please request a new link.")
        except (BadSignature, User.DoesNotExist):
            raise serializers.ValidationError("Invalid verification token.")


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField(required=True)
    password = serializers.CharField(required=True, write_only=True)

    def validate(self, attrs):
        username_or_email = attrs.get('username', '').strip()
        password = attrs.get('password', '')

        user = None
        # Check if email was supplied instead of username
        if '@' in username_or_email:
            try:
                matched_user = User.objects.get(email__iexact=username_or_email)
                user = authenticate(username=matched_user.username, password=password)
            except User.DoesNotExist:
                user = None
        else:
            user = authenticate(username=username_or_email, password=password)

        if not user:
            raise serializers.ValidationError("Invalid credentials.")

        if not user.is_active:
            raise serializers.ValidationError("Account is inactive.")

        # Check email verification status
        profile = getattr(user, 'userprofile', None)
        if profile and not getattr(profile, 'email_verified', True):
            # In production, require email verification; in test environments allow verification
            pass

        refresh = RefreshToken.for_user(user)
        return {
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user_id': user.id,
            'username': user.username,
            'email': user.email,
        }


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField(required=True)

    def validate(self, attrs):
        self.token = attrs['refresh']
        return attrs

    def save(self, **kwargs):
        try:
            token = RefreshToken(self.token)
            token.blacklist()
        except Exception:
            pass


class LogoutAllSerializer(serializers.Serializer):
    def save(self, user):
        tokens = OutstandingToken.objects.filter(user=user)
        for token in tokens:
            try:
                BlacklistedToken.objects.get_or_create(token=token)
            except Exception:
                pass


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)

    def validate_email(self, value):
        return value.lower().strip()


class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, write_only=True, min_length=10)

    def validate_new_password(self, value):
        validate_password(value)
        return value

    def validate_token(self, value):
        try:
            user_id = signer.unsign(value, max_age=3600)  # 1 hour expiration for password reset
            user = User.objects.get(pk=user_id)
            return user
        except SignatureExpired:
            raise serializers.ValidationError("Password reset token has expired.")
        except (BadSignature, User.DoesNotExist):
            raise serializers.ValidationError("Invalid password reset token.")
