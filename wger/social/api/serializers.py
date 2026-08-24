# -*- coding: utf-8 -*-
"""
Module 13 — Social Feed API Serializers
"""
from rest_framework import serializers
from django.contrib.auth.models import User
from wger.social.models import (
    Post, PostTag, Follow, Like, Comment,
    PollOption, PollVote, ContentReport, Notification, UserBlock,
)


class PostAuthorSerializer(serializers.ModelSerializer):
    class Meta:
        model  = User
        fields = ('id', 'username')  # Never expose email, PII


class PollOptionSerializer(serializers.ModelSerializer):
    vote_count = serializers.SerializerMethodField()

    class Meta:
        model  = PollOption
        fields = ('id', 'text', 'position', 'vote_count')

    def get_vote_count(self, obj):
        return obj.votes.count()


class CommentSerializer(serializers.ModelSerializer):
    author = PostAuthorSerializer(read_only=True)
    body   = serializers.CharField(max_length=1000)

    class Meta:
        model  = Comment
        fields = ('id', 'author', 'body', 'created_at', 'deleted_at')
        read_only_fields = ('id', 'author', 'created_at', 'deleted_at')

    def validate_body(self, value):
        if not value.strip():
            raise serializers.ValidationError('Comment body cannot be empty.')
        return value


class PostTagSerializer(serializers.ModelSerializer):
    class Meta:
        model  = PostTag
        fields = ('tag',)


class PostSerializer(serializers.ModelSerializer):
    author      = PostAuthorSerializer(read_only=True)
    tags        = PostTagSerializer(many=True, read_only=True)
    tag_list    = serializers.ListField(
        child=serializers.ChoiceField(choices=['general', 'workout_sharing', 'class_invite', 'trainer_intro']),
        write_only=True, required=False, default=list,
    )
    poll_options = PollOptionSerializer(many=True, read_only=True)
    poll_options_input = serializers.ListField(
        child=serializers.CharField(max_length=200),
        write_only=True, required=False, default=list,
    )
    like_count    = serializers.SerializerMethodField()
    comment_count = serializers.SerializerMethodField()
    is_liked      = serializers.SerializerMethodField()
    # workout_session_id is stored but NEVER exposes health metrics
    # — only exercise names are surfaced by the client

    class Meta:
        model  = Post
        fields = (
            'id', 'author', 'post_type', 'caption', 'media_urls',
            'workout_session_id', 'visibility', 'tags', 'tag_list',
            'poll_options', 'poll_options_input',
            'like_count', 'comment_count', 'is_liked',
            'created_at', 'updated_at',
        )
        read_only_fields = ('id', 'author', 'created_at', 'updated_at')

    def get_like_count(self, obj):
        return obj.likes.count()

    def get_comment_count(self, obj):
        return obj.comments.filter(deleted_at__isnull=True).count()

    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likes.filter(author=request.user).exists()
        return False

    def validate(self, data):
        post_type = data.get('post_type')
        poll_options = data.get('poll_options_input', [])
        if post_type == 'poll' and len(poll_options) < 2:
            raise serializers.ValidationError('Poll posts require at least 2 options.')
        if post_type != 'poll' and poll_options:
            raise serializers.ValidationError('poll_options_input is only valid for poll posts.')
        return data

    def create(self, validated_data):
        tag_list    = validated_data.pop('tag_list', [])
        poll_opts   = validated_data.pop('poll_options_input', [])
        request     = self.context['request']

        # Scope to gym_id from gym owner profile or default
        gym_id = 'default_gym'
        if hasattr(request.user, 'gym_owner_profile') and request.user.gym_owner_profile.is_approved:
            gym_id = request.user.gym_owner_profile.gym_id

        validated_data['author']  = request.user
        validated_data['gym_id']  = gym_id
        post = Post.objects.create(**validated_data)

        # Tags — enum validated, safe to bulk create
        for tag in set(tag_list):
            PostTag.objects.create(post=post, tag=tag)

        # Poll options
        for idx, text in enumerate(poll_opts):
            PollOption.objects.create(post=post, text=text, position=idx)

        return post


class FollowSerializer(serializers.ModelSerializer):
    followed_username = serializers.CharField(write_only=True)
    followed = PostAuthorSerializer(read_only=True)

    class Meta:
        model  = Follow
        fields = ('id', 'followed', 'followed_username', 'created_at')
        read_only_fields = ('id', 'followed', 'created_at')

    def validate_followed_username(self, value):
        try:
            return User.objects.get(username=value)
        except User.DoesNotExist:
            raise serializers.ValidationError(f'User "{value}" not found.')

    def validate(self, data):
        request = self.context['request']
        followed_user = data.get('followed_username')
        if followed_user == request.user:
            raise serializers.ValidationError('You cannot follow yourself.')
        if Follow.objects.filter(follower=request.user, followed=followed_user).exists():
            raise serializers.ValidationError('You are already following this user.')
        return data

    def create(self, validated_data):
        followed_user = validated_data.pop('followed_username')
        return Follow.objects.create(
            follower=self.context['request'].user,
            followed=followed_user,
        )


class ContentReportSerializer(serializers.ModelSerializer):
    class Meta:
        model  = ContentReport
        fields = ('id', 'post', 'comment', 'reason', 'status', 'created_at')
        read_only_fields = ('id', 'status', 'created_at')

    def validate(self, data):
        post    = data.get('post')
        comment = data.get('comment')
        if not post and not comment:
            raise serializers.ValidationError('Must report either a post or a comment.')
        if post and comment:
            raise serializers.ValidationError('Cannot report both post and comment in one request.')
        return data

    def create(self, validated_data):
        validated_data['reporter'] = self.context['request'].user
        # unique_together (reporter, post) prevents duplicate queue entries
        obj, _ = ContentReport.objects.get_or_create(
            reporter=validated_data['reporter'],
            post=validated_data.get('post'),
            defaults={'comment': validated_data.get('comment'), 'reason': validated_data['reason']},
        )
        return obj


class PollVoteSerializer(serializers.Serializer):
    poll_option_id = serializers.IntegerField()

    def validate_poll_option_id(self, value):
        try:
            return PollOption.objects.get(pk=value)
        except PollOption.DoesNotExist:
            raise serializers.ValidationError('Poll option not found.')


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Notification
        fields = ('id', 'notif_type', 'title', 'body', 'entity_type', 'entity_id', 'is_read', 'created_at')
        read_only_fields = ('id', 'notif_type', 'title', 'body', 'entity_type', 'entity_id', 'created_at')
