# -*- coding: utf-8 -*-
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth.models import User
from wger.social.models import Like, Comment, Follow, Notification, NotificationType


def _create_notification(user, notif_type, title, body, entity_type='', entity_id=''):
    """Helper to create an in-app notification. Fails silently to not block writes."""
    try:
        Notification.objects.create(
            user=user,
            notif_type=notif_type,
            title=title,
            body=body,
            entity_type=entity_type,
            entity_id=str(entity_id),
        )
    except Exception:
        pass


@receiver(post_save, sender=Like)
def notify_on_like(sender, instance, created, **kwargs):
    if created and instance.author != instance.post.author:
        _create_notification(
            user=instance.post.author,
            notif_type=NotificationType.SOCIAL,
            title='New Like',
            body=f'{instance.author.username} liked your post.',
            entity_type='Post',
            entity_id=str(instance.post_id),
        )


@receiver(post_save, sender=Comment)
def notify_on_comment(sender, instance, created, **kwargs):
    if created and instance.author != instance.post.author:
        _create_notification(
            user=instance.post.author,
            notif_type=NotificationType.SOCIAL,
            title='New Comment',
            body=f'{instance.author.username} commented on your post.',
            entity_type='Post',
            entity_id=str(instance.post_id),
        )


@receiver(post_save, sender=Follow)
def notify_on_follow(sender, instance, created, **kwargs):
    if created:
        _create_notification(
            user=instance.followed,
            notif_type=NotificationType.SOCIAL,
            title='New Follower',
            body=f'{instance.follower.username} started following you.',
            entity_type='Follow',
            entity_id=str(instance.pk),
        )
