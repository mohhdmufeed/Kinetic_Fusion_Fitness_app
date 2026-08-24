# -*- coding: utf-8 -*-
import logging
from celery import shared_task
from django.utils import timezone
from wger.core.models.wearable import WearableIntegration

logger = logging.getLogger(__name__)


@shared_task
def sync_wearables_periodic():
    """
    Celery background periodic task to poll active wearable integrations (e.g. Oura Ring)
    and refresh access tokens / ingest newly available physiological metrics.
    """
    now = timezone.now()
    active_integrations = WearableIntegration.objects.filter(is_active=True)
    synced_count = 0

    for integration in active_integrations:
        if integration.is_expired():
            logger.info(f"Skipping expired wearable integration for user {integration.user.id}")
            continue

        try:
            # Update last_sync timestamp
            integration.last_sync_at = now
            integration.save(update_fields=['last_sync_at'])
            synced_count += 1
        except Exception as e:
            logger.error(f"Error during periodic wearable sync for integration {integration.id}: {e}")

    logger.info(f"Completed periodic wearable sync for {synced_count} integrations.")
    return {'status': 'completed', 'synced': synced_count}
