#  This file is part of wger Workout Manager <https://github.com/wger-project>.
#  Copyright (C) 2013 - 2021 wger Team
#
#  wger Workout Manager is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  wger Workout Manager is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Local
from .cache import UserCache
from .language import Language
from .license import License
from .profile import UserProfile
from .rep_unit import RepetitionUnit
from .weight_unit import WeightUnit
from .admin import AdminProfile, AdminAuditLog
from .sync import SyncLog
from .ml import (
    DailyMetrics,
    MLRecoveryScore,
    MLTrainingLoad,
    MLStrengthTrajectory,
    MLWeightTrajectory,
    MLDailyRecommendation,
)
from .feedback import FeedbackReport
from .activity import ActivityLog
from .gym_admin import (
    ProgramSchedule,
    ProgramDay,
    ProgramExercise,
    ClientMembership,
    BodyStatEntry,
)
from .gym_owner import GymOwnerProfile
from .trainer_booking_achievements import (
    # Module 14 — Trainer Directory & Booking
    TrainerProfile,
    GroupClass,
    PrivateSession,
    Booking,
    BookingStatus,
    SessionType,
    SessionStatus,
    ClassStatus,
    # Module 15 — Achievements, Favorites & Home Widgets
    Achievement,
    UserAchievement,
    Favorite,
    FavoriteEntityType,
    HomeWidget,
    WidgetType,
    AchievementRuleType,
)
from .wearable import WearableIntegration
