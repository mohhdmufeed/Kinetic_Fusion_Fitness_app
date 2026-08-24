# -*- coding: utf-8 -*-
from django.apps import AppConfig


class SocialConfig(AppConfig):
    name = 'wger.social'
    verbose_name = 'Social Feed'

    def ready(self):
        import wger.social.signals  # noqa: F401
