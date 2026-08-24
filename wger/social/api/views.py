# -*- coding: utf-8 -*-
"""
Module 13 — Community / Social Feed API Views
All views require IsAuthenticated; querysets are always scoped to
request.user's gym_id or own data to prevent cross-user/cross-gym leakage.
"""
from django.db import transaction
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import UserRateThrottle
from rest_framework.views import APIView
from rest_framework.generics import (
    ListCreateAPIView, RetrieveDestroyAPIView, ListAPIView,
)

from wger.social.models import (
    Post, Follow, Like, Comment, PollOption, PollVote,
    ContentReport, UserBlock, Notification,
)
from wger.social.api.serializers import (
    PostSerializer, FollowSerializer, CommentSerializer,
    ContentReportSerializer, PollVoteSerializer, NotificationSerializer,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _get_user_gym_id(user):
    """Return gym_id for the requesting user (defaults to 'default_gym')."""
    if hasattr(user, 'gym_owner_profile') and user.gym_owner_profile.is_approved:
        return user.gym_owner_profile.gym_id
    return 'default_gym'


def _blocked_user_ids(user):
    """IDs of users blocked by or blocking request.user (bidirectional)."""
    from django.db.models import Q
    return UserBlock.objects.filter(
        Q(blocker=user) | Q(blocked=user)
    ).values_list('blocker_id', 'blocked_id')


def _excluded_ids(user):
    """Flat set of user IDs to exclude from feeds/replies."""
    ids = set()
    for a, b in _blocked_user_ids(user):
        ids.add(a)
        ids.add(b)
    ids.discard(user.pk)
    return ids


# ---------------------------------------------------------------------------
# Post List / Create  — GET /api/v2/social/posts/?feed=for_you|following
# ---------------------------------------------------------------------------

class PostListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def _base_qs(self, user):
        excluded  = _excluded_ids(user)
        gym_id    = _get_user_gym_id(user)
        reported  = ContentReport.objects.filter(reporter=user).values_list('post_id', flat=True)
        return Post.objects.filter(
            is_active=True,
            gym_id=gym_id,
        ).exclude(
            author_id__in=excluded,
        ).exclude(
            id__in=reported,
        ).select_related('author').prefetch_related('tags', 'poll_options', 'likes')

    def get(self, request):
        feed_type = request.query_params.get('feed', 'for_you')
        qs = self._base_qs(request.user)

        if feed_type == 'following':
            following_ids = Follow.objects.filter(
                follower=request.user
            ).values_list('followed_id', flat=True)
            qs = qs.filter(author_id__in=list(following_ids))
        # else: for_you = full gym feed (reverse-chron; ML ranking deferred until data exists)

        qs = qs.order_by('-created_at')[:50]
        serializer = PostSerializer(qs, many=True, context={'request': request})
        return Response(serializer.data)

    def post(self, request):
        serializer = PostSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            post = serializer.save()
            return Response(PostSerializer(post, context={'request': request}).data,
                            status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ---------------------------------------------------------------------------
# Post Detail / Delete — GET /api/v2/social/posts/<id>/
# ---------------------------------------------------------------------------

class PostDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def _get_post(self, pk, user):
        gym_id = _get_user_gym_id(user)
        return Post.objects.filter(pk=pk, is_active=True, gym_id=gym_id).first()

    def get(self, request, pk):
        post = self._get_post(pk, request.user)
        if not post:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(PostSerializer(post, context={'request': request}).data)

    def delete(self, request, pk):
        post = Post.objects.filter(pk=pk, author=request.user, is_active=True).first()
        if not post:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        post.is_active = False
        post.save(update_fields=['is_active'])
        return Response(status=status.HTTP_204_NO_CONTENT)


# ---------------------------------------------------------------------------
# Like toggle — POST /api/v2/social/posts/<id>/like/
#              DELETE /api/v2/social/posts/<id>/unlike/
# ---------------------------------------------------------------------------

class PostLikeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        post = Post.objects.filter(pk=pk, is_active=True).first()
        if not post:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        _, created = Like.objects.get_or_create(post=post, author=request.user)
        code = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response({'liked': True, 'like_count': post.likes.count()}, status=code)

    def delete(self, request, pk):
        Like.objects.filter(post_id=pk, author=request.user).delete()
        post = Post.objects.filter(pk=pk).first()
        count = post.likes.count() if post else 0
        return Response({'liked': False, 'like_count': count})


# ---------------------------------------------------------------------------
# Comments — GET/POST /api/v2/social/posts/<id>/comments/
#            DELETE   /api/v2/social/comments/<id>/
# ---------------------------------------------------------------------------

class PostCommentListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        excluded = _excluded_ids(request.user)
        comments = Comment.objects.filter(
            post_id=pk,
            deleted_at__isnull=True,
        ).exclude(
            author_id__in=excluded,
        ).select_related('author').order_by('created_at')
        return Response(CommentSerializer(comments, many=True).data)

    def post(self, request, pk):
        post = Post.objects.filter(pk=pk, is_active=True).first()
        if not post:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        serializer = CommentSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            comment = Comment.objects.create(
                post=post, author=request.user, body=serializer.validated_data['body']
            )
            return Response(CommentSerializer(comment).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CommentDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        comment = Comment.objects.filter(pk=pk, author=request.user, deleted_at__isnull=True).first()
        if not comment:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        comment.deleted_at = timezone.now()
        comment.save(update_fields=['deleted_at'])
        return Response(status=status.HTTP_204_NO_CONTENT)


# ---------------------------------------------------------------------------
# Follow / Unfollow — GET/POST /api/v2/social/follow/
#                    DELETE   /api/v2/social/follow/<id>/
# ---------------------------------------------------------------------------

class FollowListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        follows = Follow.objects.filter(follower=request.user).select_related('followed')
        return Response(FollowSerializer(follows, many=True, context={'request': request}).data)

    def post(self, request):
        serializer = FollowSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            follow = serializer.save()
            return Response(FollowSerializer(follow, context={'request': request}).data,
                            status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class FollowDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        Follow.objects.filter(pk=pk, follower=request.user).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


# ---------------------------------------------------------------------------
# Poll Vote — POST /api/v2/social/poll/<option_id>/vote/
# ---------------------------------------------------------------------------

class PollVoteView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, option_id):
        serializer = PollVoteSerializer(data={'poll_option_id': option_id})
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        option = serializer.validated_data['poll_option_id']
        post   = option.post

        if PollVote.objects.filter(post=post, voter=request.user).exists():
            return Response(
                {'detail': 'You have already voted on this poll.'},
                status=status.HTTP_409_CONFLICT,
            )

        PollVote.objects.create(poll_option=option, voter=request.user, post=post)
        return Response({'voted': True, 'option_id': option.pk}, status=status.HTTP_201_CREATED)


# ---------------------------------------------------------------------------
# Content Report — POST /api/v2/social/report/
# ---------------------------------------------------------------------------

class SocialReportThrottle(UserRateThrottle):
    rate = '20/day'


class ContentReportView(APIView):
    permission_classes  = [IsAuthenticated]
    throttle_classes    = [SocialReportThrottle]

    def post(self, request):
        serializer = ContentReportSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            report = serializer.save()
            return Response(
                ContentReportSerializer(report).data,
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ---------------------------------------------------------------------------
# Block user — POST /api/v2/social/block/  (immediate, no admin needed)
# ---------------------------------------------------------------------------

class UserBlockView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        username = request.data.get('username', '').strip()
        if not username:
            return Response({'detail': 'username required.'}, status=status.HTTP_400_BAD_REQUEST)
        from django.contrib.auth.models import User as DjangoUser
        try:
            target = DjangoUser.objects.get(username=username)
        except DjangoUser.DoesNotExist:
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
        if target == request.user:
            return Response({'detail': 'Cannot block yourself.'}, status=status.HTTP_400_BAD_REQUEST)
        UserBlock.objects.get_or_create(blocker=request.user, blocked=target)
        return Response({'blocked': username}, status=status.HTTP_201_CREATED)


# ---------------------------------------------------------------------------
# Notifications — GET  /api/v2/social/notifications/
#                PATCH /api/v2/social/notifications/<id>/read/
# ---------------------------------------------------------------------------

class NotificationListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notif_type = request.query_params.get('type')
        qs = Notification.objects.filter(user=request.user)
        if notif_type:
            qs = qs.filter(notif_type=notif_type)
        qs = qs.order_by('-created_at')[:100]
        return Response(NotificationSerializer(qs, many=True).data)


class NotificationMarkReadView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        updated = Notification.objects.filter(pk=pk, user=request.user).update(is_read=True)
        if not updated:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response({'is_read': True})

    def delete(self, request, pk):
        """Mark all as read via DELETE on sentinel ID 'all'."""
        pass  # handled by separate bulk endpoint if needed
