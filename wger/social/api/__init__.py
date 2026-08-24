# -*- coding: utf-8 -*-
from django.apps import apps


def get_installed_apps():
    return [
        'wger.social.apps.SocialConfig',
    ]
