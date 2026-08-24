# -*- coding: utf-8 -*-

# This file is part of wger Workout Manager.
#
# wger Workout Manager is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# wger Workout Manager is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Workout Manager.  If not, see <http://www.gnu.org/licenses/>.

# Django
from django.conf import settings
from django.conf.urls import include
from django.conf.urls.i18n import i18n_patterns
from django.conf.urls.static import static
from django.contrib.sitemaps.views import (
    index,
    sitemap,
)
from django.urls import path

# Third Party
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)
from rest_framework import routers
from rest_framework_simplejwt.views import (
    TokenRefreshView,
    TokenVerifyView,
)

# wger
from wger.core.api import views as core_api_views
from wger.core.api import auth_views
from wger.core.api import admin_views
from wger.core.api import sync_views
from wger.core.api import sync_engine_views
from wger.core.api import dashboard_views
from wger.core.api import feedback_views
from wger.core.api import admin_feedback_views
from wger.core.api import activity_views
from wger.core.api import gym_admin_views
from wger.core.api import gym_owner_views
from wger.core.api import trainer_booking_views
from wger.core.api import achievements_favorites_widgets_views
from wger.core.api import wearable_views
from wger.social.api import views as social_views
from wger.nutrition.api import kinetic_nutrition_views
from wger.exercises.api import views as exercises_api_views
from wger.exercises.api import exercise_library_views
from wger.exercises.api import admin_exercise_views
from wger.exercises.sitemap import ExercisesSitemap
from wger.gallery.api import views as gallery_api_views
from wger.manager.api import views as manager_api_views
from wger.measurements.api import views as measurements_api_views
from wger.nutrition.api import views as nutrition_api_views
from wger.trophies.api import views as trophies_api_views
from wger.utils import oidc_auth
from wger.utils.generic_views import TextTemplateView
from wger.weight.api import views as weight_api_views


#
# REST API
#
router = routers.DefaultRouter()

#
# Application
#

# Manager app
router.register(r'routine', manager_api_views.RoutineViewSet, basename='routine')
router.register(r'templates', manager_api_views.UserRoutineTemplateViewSet, basename='templates')
router.register(
    r'public-templates',
    manager_api_views.PublicRoutineTemplateViewSet,
    basename='public-templates',
)
router.register(
    r'workoutsession',
    manager_api_views.WorkoutSessionViewSet,
    basename='workoutsession',
)
router.register(
    r'day',
    manager_api_views.RoutineDayViewSet,
    basename='day',
)
router.register(
    r'slot',
    manager_api_views.SlotViewSet,
    basename='slot',
)
router.register(
    r'slot-entry',
    manager_api_views.SlotEntryViewSet,
    basename='slot-entry',
)
router.register(
    r'weight-config',
    manager_api_views.WeightConfigViewSet,
    basename='weight-config',
)
router.register(
    r'max-weight-config',
    manager_api_views.MaxWeightConfigViewSet,
    basename='max-weight-config',
)
router.register(
    r'repetitions-config',
    manager_api_views.RepetitionsConfigViewSet,
    basename='repetitions-config',
)
router.register(
    r'max-repetitions-config',
    manager_api_views.MaxRepetitionsConfigViewSet,
    basename='max-repetitions-config',
)
router.register(
    r'sets-config',
    manager_api_views.SetsConfigViewSet,
    basename='sets-config',
)
router.register(
    r'max-sets-config',
    manager_api_views.MaxSetsConfigViewSet,
    basename='max-sets-config',
)
router.register(
    r'rest-config',
    manager_api_views.RestConfigViewSet,
    basename='rest-config',
)
router.register(
    r'max-rest-config',
    manager_api_views.MaxRestConfigViewSet,
    basename='max-rest-config',
)
router.register(r'rir-config', manager_api_views.RiRConfigViewSet, basename='rir-config')
router.register(r'max-rir-config', manager_api_views.MaxRiRConfigViewSet, basename='max-rir-config')
router.register(r'workoutlog', manager_api_views.WorkoutLogViewSet, basename='workoutlog')

# Core app
router.register(r'language', core_api_views.LanguageViewSet, basename='language')
router.register(r'license', core_api_views.LicenseViewSet, basename='license')
# userprofile is not registered here: a user has exactly one profile, so it is
# a plain path without list or detail routes (see UserProfileView)
router.register(
    r'setting-repetitionunit',
    core_api_views.RepetitionUnitViewSet,
    basename='setting-repetition-unit',
)
router.register(
    r'setting-weightunit', core_api_views.RoutineWeightUnitViewSet, basename='setting-weight-unit'
)

# Exercises app
router.register(
    r'exerciseinfo',
    exercises_api_views.ExerciseInfoViewset,
    basename='exerciseinfo',
)

router.register(
    r'exercise-translation',
    exercises_api_views.ExerciseTranslationViewSet,
    basename='exercise-translation',
)
router.register(
    r'exercise',
    exercises_api_views.ExerciseViewSet,
    basename='exercise',
)
router.register(
    r'equipment',
    exercises_api_views.EquipmentViewSet,
    basename='equipment',
)
router.register(
    r'deletion-log',
    exercises_api_views.DeletionLogViewSet,
    basename='deletion-log',
)
router.register(
    r'exercisecategory',
    exercises_api_views.ExerciseCategoryViewSet,
    basename='exercisecategory',
)
router.register(
    r'video',
    exercises_api_views.ExerciseVideoViewSet,
    basename='video',
)
router.register(
    r'exerciseimage',
    exercises_api_views.ExerciseImageViewSet,
    basename='exerciseimage',
)
router.register(
    r'exercisecomment',
    exercises_api_views.ExerciseCommentViewSet,
    basename='exercisecomment',
)
router.register(
    r'exercisealias',
    exercises_api_views.ExerciseAliasViewSet,
    basename='exercisealias',
)
router.register(
    r'muscle',
    exercises_api_views.MuscleViewSet,
    basename='muscle',
)

# Nutrition app
router.register(r'ingredient', nutrition_api_views.IngredientViewSet, basename='api-ingredient')
router.register(
    r'ingredientinfo', nutrition_api_views.IngredientInfoViewSet, basename='api-ingredientinfo'
)
router.register(
    r'ingredient-sync',
    nutrition_api_views.IngredientSyncViewSet,
    basename='api-ingredient-sync',
)
router.register(
    r'ingredientweightunit',
    nutrition_api_views.IngredientWeightUnitViewSet,
    basename='ingredientweightunit',
)
router.register(
    r'nutritionplan', nutrition_api_views.NutritionPlanViewSet, basename='nutritionplan'
)
router.register(
    r'nutritionplaninfo', nutrition_api_views.NutritionPlanInfoViewSet, basename='nutritionplaninfo'
)
router.register(r'nutritiondiary', nutrition_api_views.LogItemViewSet, basename='nutritiondiary')
router.register(r'meal', nutrition_api_views.MealViewSet, basename='meal')
router.register(r'mealitem', nutrition_api_views.MealItemViewSet, basename='mealitem')
router.register(r'ingredient-image', nutrition_api_views.ImageViewSet, basename='ingredientimage')

# Weight app
router.register(r'weightentry', weight_api_views.WeightEntryViewSet, basename='weightentry')

# Gallery app
router.register(r'gallery', gallery_api_views.GalleryImageViewSet, basename='gallery')

# Measurements app
router.register(
    r'measurement',
    measurements_api_views.MeasurementViewSet,
    basename='measurement',
)
router.register(
    r'measurement-category',
    measurements_api_views.CategoryViewSet,
    basename='measurement-category',
)

# Trophies app
router.register(r'trophy', trophies_api_views.TrophyViewSet, basename='trophy')
router.register(r'user-trophy', trophies_api_views.UserTrophyViewSet, basename='user-trophy')
router.register(
    r'user-statistics',
    trophies_api_views.UserStatisticsViewSet,
    basename='user-statistics',
)

#
# Sitemaps
#
sitemaps = {
    'exercises': ExercisesSitemap,
}  # 'nutrition': NutritionSitemap}

#
# The actual URLs
#
urlpatterns = i18n_patterns(
    path('', include(('wger.core.urls', 'core'), namespace='core')),
    path('routine/', include(('wger.manager.urls', 'manager'), namespace='manager')),
    path('exercise/', include(('wger.exercises.urls', 'exercise'), namespace='exercise')),
    path('weight/', include(('wger.weight.urls', 'weight'), namespace='weight')),
    path('nutrition/', include(('wger.nutrition.urls', 'nutrition'), namespace='nutrition')),
    path('software/', include(('wger.software.urls', 'software'), namespace='software')),
    path('config/', include(('wger.config.urls', 'config'), namespace='config')),
    path('gym/', include(('wger.gym.urls', 'gym'), namespace='gym')),
    path('gallery/', include(('wger.gallery.urls', 'gallery'), namespace='gallery')),
    path('trophies/', include(('wger.trophies.urls', 'trophies'), namespace='trophies')),
    path(
        'measurement/',
        include(('wger.measurements.urls', 'measurements'), namespace='measurements'),
    ),
    path('email/', include(('wger.mailer.urls', 'email'), namespace='email')),
    path('sitemap.xml', index, {'sitemaps': sitemaps}, name='sitemap'),
    path(
        'sitemap-<section>.xml',
        sitemap,
        {'sitemaps': sitemaps},
        name='django.contrib.sitemaps.views.sitemap',
    ),
)

#
# URLs without language prefix
#
urlpatterns += [
    path('i18n/', include('django.conf.urls.i18n')),
    path('robots.txt', TextTemplateView.as_view(template_name='robots.txt'), name='robots'),
    # allauth account pages are mounted without a language prefix: the OAuth
    # callback's redirect_uri has to be stable
    path('account/', include('allauth.urls')),
    # REST auth API consumed by the Flutter app.
    path('allauth/', include('allauth.headless.urls')),
    # OAuth2/OIDC provider. Mounted at the root, the paths (/.well-known/... and
    # /identity/o/...) are part of the include. The authorization endpoint is
    # wrapped to keep the flow from starting when the provider isn't configured.
    path('identity/o/authorize', oidc_auth.authorization_view, name='oidc-authorize'),
    path('', include('allauth.idp.urls')),
    # API
    path(
        'api/v2/exercise-submission/',
        exercises_api_views.ExerciseSubmissionViewSet.as_view(),
        name='exercise-submission',
    ),
    path('api/v2/check-language/', core_api_views.check_language, name='check-language'),
    path(
        'api/v2/userprofile/',
        core_api_views.UserProfileView.as_view(),
        name='userprofile',
    ),
    path(
        'api/v2/userprofile/verify-email/',
        core_api_views.VerifyEmailView.as_view(),
        name='userprofile-verify-email',
    ),
    # Kinetic Precision Secure Auth Endpoints
    path('api/v2/auth/signup/', auth_views.SignupView.as_view(), name='auth-signup'),
    path('api/v2/auth/verify-email/', auth_views.VerifyEmailView.as_view(), name='auth-verify-email'),
    path('api/v2/auth/login/', auth_views.LoginView.as_view(), name='auth-login'),
    path('api/v2/auth/refresh/', TokenRefreshView.as_view(), name='auth-refresh'),
    path('api/v2/auth/logout/', auth_views.LogoutView.as_view(), name='auth-logout'),
    path('api/v2/auth/logout-all/', auth_views.LogoutAllView.as_view(), name='auth-logout-all'),
    path('api/v2/auth/password-reset/', auth_views.PasswordResetRequestView.as_view(), name='auth-password-reset'),
    path('api/v2/auth/password-reset-confirm/', auth_views.PasswordResetConfirmView.as_view(), name='auth-password-reset-confirm'),

    # Kinetic Precision Hardened Admin Tier (/api/v2/admin/**)
    path('api/v2/admin/auth/login/', admin_views.AdminLoginStep1View.as_view(), name='admin-login-step1'),
    path('api/v2/admin/auth/verify-2fa/', admin_views.AdminVerify2FAView.as_view(), name='admin-verify-2fa'),
    path('api/v2/admin/users/', admin_views.AdminUserListView.as_view(), name='admin-users-list'),
    path('api/v2/admin/users/<int:user_id>/suspend/', admin_views.AdminUserSuspendView.as_view(), name='admin-user-suspend'),
    path('api/v2/admin/users/<int:user_id>/soft-delete/', admin_views.AdminUserSoftDeleteView.as_view(), name='admin-user-soft-delete'),
    path('api/v2/admin/analytics/overview/', admin_views.AdminAnalyticsOverviewView.as_view(), name='admin-analytics-overview'),
    path('api/v2/admin/system/health/', admin_views.AdminSystemHealthView.as_view(), name='admin-system-health'),
    path('api/v2/admin/audit-logs/', admin_views.AdminAuditLogListView.as_view(), name='admin-audit-logs'),

    # Kinetic Precision Authoritative ChangeLog Sync Engine (/api/v2/sync/**)
    path('api/v2/sync/push/', sync_engine_views.SyncPushAPIView.as_view(), name='sync-push'),
    path('api/v2/sync/pull/', sync_engine_views.SyncPullAPIView.as_view(), name='sync-pull'),

    # Kinetic Precision Wearable Integrations (/api/v2/wearables/**)
    path('api/v2/wearables/status/', wearable_views.WearableStatusView.as_view(), name='wearables-status'),
    path('api/v2/wearables/oura/auth/', wearable_views.OuraAuthView.as_view(), name='wearables-oura-auth'),
    path('api/v2/wearables/oura/sync/', wearable_views.OuraSyncView.as_view(), name='wearables-oura-sync'),

    # Kinetic Precision High-Performance Applied ML Dashboard (/api/v2/dashboard/**)
    path('api/v2/dashboard/today/', dashboard_views.DashboardTodayView.as_view(), name='dashboard-today'),
    path('api/v2/dashboard/body/', dashboard_views.DashboardBodyView.as_view(), name='dashboard-body'),
    path('api/v2/dashboard/history/', dashboard_views.DashboardHistoryView.as_view(), name='dashboard-history'),

    # Kinetic Precision Exercise Library (/api/v2/exercise-library/**)
    path('api/v2/exercise-library/', exercise_library_views.ExerciseLibraryListView.as_view(), name='exercise-library-list'),
    path('api/v2/exercise-library/<int:exercise_id>/favorite/', exercise_library_views.ExerciseFavoriteToggleView.as_view(), name='exercise-library-favorite'),
    path('api/v2/exercise-library/<int:exercise_id>/history/', exercise_library_views.ExerciseHistoryView.as_view(), name='exercise-library-history'),
    path('api/v2/exercise-library/suggest/', exercise_library_views.ExerciseSuggestionView.as_view(), name='exercise-library-suggest'),

    # Kinetic Precision In-App Feedback & Support (/api/v2/feedback/**)
    path('api/v2/feedback/', feedback_views.FeedbackSubmitView.as_view(), name='feedback-submit'),
    path('api/v2/feedback/mine/', feedback_views.FeedbackMineListView.as_view(), name='feedback-mine'),

    # Kinetic Precision Real GPS & Pedometer Telemetry (/api/v2/activity/**)
    path('api/v2/activity/record/', activity_views.ActivityRecordView.as_view(), name='activity-record'),
    path('api/v2/activity/history/', activity_views.ActivityHistoryView.as_view(), name='activity-history'),
    path('api/v2/activity/location-history/', activity_views.ActivityLocationPurgeView.as_view(), name='activity-location-purge'),

    # Kinetic Precision Closed Nutrition System (/api/v2/nutrition/** & /api/v2/admin/nutrition/**)
    path('api/v2/nutrition/search/', kinetic_nutrition_views.NutritionSearchAPIView.as_view(), name='kinetic-nutrition-search'),
    path('api/v2/nutrition/lookup/', kinetic_nutrition_views.NutritionLookupAPIView.as_view(), name='kinetic-nutrition-lookup'),
    path('api/v2/nutrition/barcode/', kinetic_nutrition_views.BarcodeLookupAPIView.as_view(), name='kinetic-nutrition-barcode'),
    path('api/v2/nutrition/log/', kinetic_nutrition_views.NutritionDiaryListCreateAPIView.as_view(), name='kinetic-nutrition-log'),
    path('api/v2/nutrition/diary/', kinetic_nutrition_views.NutritionDiaryListCreateAPIView.as_view(), name='kinetic-nutrition-diary-list'),
    path('api/v2/nutrition/diary/<int:entry_id>/', kinetic_nutrition_views.NutritionDiaryDetailAPIView.as_view(), name='kinetic-nutrition-diary-detail'),
    path('api/v2/admin/nutrition/ingredients/', kinetic_nutrition_views.AdminNutritionIngredientListCreateView.as_view(), name='admin-nutrition-ingredients-list'),
    path('api/v2/admin/nutrition/ingredients/<int:ingredient_id>/', kinetic_nutrition_views.AdminNutritionIngredientDetailView.as_view(), name='admin-nutrition-ingredients-detail'),

    # Kinetic Precision Super Admin Exercise Governance (/api/v2/admin/exercises/**)
    path('api/v2/admin/exercises/', admin_exercise_views.AdminExerciseListView.as_view(), name='admin-exercises-list'),
    path('api/v2/admin/exercises/<int:base_id>/publish/', admin_exercise_views.AdminExercisePublishView.as_view(), name='admin-exercise-publish'),
    path('api/v2/admin/exercises/<int:base_id>/deactivate/', admin_exercise_views.AdminExerciseDeactivateView.as_view(), name='admin-exercise-deactivate'),

    # Kinetic Precision Super Admin Feedback Management (/api/v2/admin/feedback/**)
    path('api/v2/admin/feedback/', admin_feedback_views.AdminFeedbackListView.as_view(), name='admin-feedback-list'),
    path('api/v2/admin/feedback/<int:report_id>/', admin_feedback_views.AdminFeedbackDetailView.as_view(), name='admin-feedback-detail'),

    # Kinetic Precision Super Admin Trainer Panel (/api/v2/admin/clients/** & /api/v2/admin/schedules/**)
    path('api/v2/admin/clients/', gym_admin_views.AdminClientListCreateView.as_view(), name='admin-clients-list'),
    path('api/v2/admin/clients/<int:client_id>/', gym_admin_views.AdminClientDetailView.as_view(), name='admin-clients-detail'),
    path('api/v2/admin/clients/<int:client_id>/stats/', gym_admin_views.AdminClientBodyStatsView.as_view(), name='admin-clients-stats'),
    path('api/v2/admin/clients/<int:client_id>/assign-schedule/', gym_admin_views.AdminAssignScheduleView.as_view(), name='admin-clients-assign-schedule'),
    path('api/v2/admin/schedules/', gym_admin_views.AdminScheduleListCreateView.as_view(), name='admin-schedules-list'),
    path('api/v2/admin/schedules/<int:schedule_id>/', gym_admin_views.AdminScheduleDetailView.as_view(), name='admin-schedules-detail'),
    path('api/v2/admin/schedules/<int:schedule_id>/days/<int:day_number>/exercises/', gym_admin_views.AdminScheduleDayExerciseCreateView.as_view(), name='admin-schedules-day-exercise'),

    # Kinetic Precision Gym Command Center (Owner Exclusive /api/v2/owner/**)
    path('api/v2/owner/register/', gym_owner_views.OwnerRegistrationView.as_view(), name='owner-register'),
    path('api/v2/owner/<int:owner_id>/approve/', gym_owner_views.OwnerApprovalView.as_view(), name='owner-approve'),
    path('api/v2/owner/clients/', gym_owner_views.OwnerClientListCreateView.as_view(), name='owner-clients-list'),
    path('api/v2/owner/clients/<int:client_id>/', gym_owner_views.OwnerClientDetailView.as_view(), name='owner-clients-detail'),
    path('api/v2/owner/clients/<int:client_id>/stats/', gym_owner_views.OwnerClientBodyStatsView.as_view(), name='owner-clients-stats'),
    path('api/v2/owner/schedules/', gym_owner_views.OwnerScheduleListCreateView.as_view(), name='owner-schedules-list'),
    path('api/v2/owner/schedules/<int:schedule_id>/', gym_owner_views.OwnerScheduleDetailUpdateView.as_view(), name='owner-schedules-detail'),
    path('api/v2/owner/schedules/<int:schedule_id>/reorder/', gym_owner_views.OwnerScheduleReorderView.as_view(), name='owner-schedules-reorder'),
    path('api/v2/owner/exercises/', gym_owner_views.OwnerExerciseListCreateView.as_view(), name='owner-exercises-list'),
    path('api/v2/owner/trainers/', trainer_booking_views.OwnerTrainerAssignView.as_view(), name='owner-trainers-assign'),

    # Module 13 — Community / Social Feed (/api/v2/social/**)
    path('api/v2/social/posts/', social_views.PostListCreateView.as_view(), name='social-posts-list'),
    path('api/v2/social/posts/<uuid:pk>/', social_views.PostDetailView.as_view(), name='social-posts-detail'),
    path('api/v2/social/posts/<uuid:pk>/like/', social_views.PostLikeView.as_view(), name='social-posts-like'),
    path('api/v2/social/posts/<uuid:pk>/unlike/', social_views.PostLikeView.as_view(), name='social-posts-unlike'),
    path('api/v2/social/posts/<uuid:pk>/comments/', social_views.PostCommentListCreateView.as_view(), name='social-comments-list'),
    path('api/v2/social/posts/<uuid:pk>/report/', social_views.ContentReportView.as_view(), name='social-post-report'),
    path('api/v2/social/report/', social_views.ContentReportView.as_view(), name='social-report-standalone'),
    path('api/v2/social/comments/<int:pk>/', social_views.CommentDeleteView.as_view(), name='social-comment-delete'),
    path('api/v2/social/follow/', social_views.FollowListCreateView.as_view(), name='social-follow-list'),
    path('api/v2/social/follow/<int:pk>/', social_views.FollowDeleteView.as_view(), name='social-follow-delete'),
    path('api/v2/social/poll/<int:option_id>/vote/', social_views.PollVoteView.as_view(), name='social-poll-vote'),
    path('api/v2/social/block/', social_views.UserBlockView.as_view(), name='social-block'),
    path('api/v2/social/notifications/', social_views.NotificationListView.as_view(), name='social-notifications'),
    path('api/v2/social/notifications/<uuid:pk>/read/', social_views.NotificationMarkReadView.as_view(), name='social-notification-read'),

    # Module 14 — Trainer Directory & Booking (/api/v2/trainers/**, /api/v2/classes/**)
    path('api/v2/trainers/', trainer_booking_views.TrainerListView.as_view(), name='trainers-list'),
    path('api/v2/trainers/<int:pk>/', trainer_booking_views.TrainerDetailView.as_view(), name='trainers-detail'),
    path('api/v2/classes/', trainer_booking_views.GroupClassListView.as_view(), name='classes-list'),
    path('api/v2/classes/<int:pk>/book/', trainer_booking_views.ClassBookView.as_view(), name='classes-book'),
    path('api/v2/classes/<int:pk>/cancel/', trainer_booking_views.ClassCancelView.as_view(), name='classes-cancel'),
    path('api/v2/private-sessions/', trainer_booking_views.PrivateSessionListCreateView.as_view(), name='private-sessions-list'),
    path('api/v2/private-sessions/<int:pk>/', trainer_booking_views.PrivateSessionDetailView.as_view(), name='private-sessions-detail'),

    # Module 15 — Achievements, Favorites & Home Widgets (/api/v2/**)
    path('api/v2/achievements/', achievements_favorites_widgets_views.UserAchievementListView.as_view(), name='achievements-list'),
    path('api/v2/achievements/catalogue/', achievements_favorites_widgets_views.AchievementCatalogueView.as_view(), name='achievements-catalogue'),
    path('api/v2/favorites/', achievements_favorites_widgets_views.FavoriteListCreateView.as_view(), name='favorites-list'),
    path('api/v2/favorites/<int:pk>/', achievements_favorites_widgets_views.FavoriteDetailView.as_view(), name='favorites-detail'),
    path('api/v2/home-widgets/', achievements_favorites_widgets_views.HomeWidgetListView.as_view(), name='home-widgets-list'),
    path('api/v2/home-widgets/reorder/', achievements_favorites_widgets_views.HomeWidgetReorderView.as_view(), name='home-widgets-reorder'),

    path('api/v2/', include(router.urls)),
    path('api/v2/token/refresh', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/v2/token/verify', TokenVerifyView.as_view(), name='token_verify'),
    path(
        'api/v2/issue-refresh-token',
        core_api_views.issue_refresh_token,
        name='issue_refresh_token',
    ),
    # Others
    path(
        'api/v2/version/',
        core_api_views.ApplicationVersionView.as_view({'get': 'get'}),
        name='app_version',
    ),
    path(
        'api/v2/check-permission/',
        core_api_views.PermissionView.as_view({'get': 'get'}),
        name='permission',
    ),
    path(
        'api/v2/min-app-version/',
        core_api_views.RequiredApplicationVersionView.as_view({'get': 'get'}),
        name='min_app_version',
    ),
    path(
        'api/v2/min-server-version/',
        core_api_views.RequiredServerVersionView.as_view({'get': 'get'}),
        name='min_server_version',
    ),
    path(
        'api/v2/powersync-token',
        core_api_views.get_powersync_token,
        name='get_token',
    ),
    path(
        'api/v2/powersync-keys',
        core_api_views.get_powersync_keys,
        name='powersync-keys',
    ),
    path(
        'api/v2/upload-powersync-data',
        core_api_views.upload_powersync_data,
        name='powersync-data',
    ),
    # Api documentation
    #
    # metadata_class=None disables the OPTIONS handler on the HTML views: its
    # metadata response would otherwise be rendered through the UI template,
    # which requires context only the GET handler provides, and crash with 500.
    path(
        'api/v2/schema',
        SpectacularAPIView.as_view(),
        name='schema',
    ),
    path(
        'api/v2/schema/ui',
        SpectacularSwaggerView.as_view(url_name='schema', metadata_class=None),
        name='api-swagger-ui',
    ),
    path(
        'api/v2/schema/redoc',
        SpectacularRedocView.as_view(url_name='schema', metadata_class=None),
        name='api-redoc',
    ),
]


#
# URL for user uploaded files, served like this during development only
#
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    # urlpatterns.append(path('__debug__/', include('debug_toolbar.urls')))

if settings.EXPOSE_PROMETHEUS_METRICS:
    urlpatterns += [path('prometheus/', include('django_prometheus.urls'))]
