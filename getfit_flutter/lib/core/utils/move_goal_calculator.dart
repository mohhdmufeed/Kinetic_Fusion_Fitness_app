class ProfessionPreset {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String workIntensity; // 'low', 'medium', 'high'
  final double typicalWorkHours;

  const ProfessionPreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.workIntensity,
    required this.typicalWorkHours,
  });
}

class ActivityData {
  String activityLevel; // 'light', 'moderate', 'high', 'custom'
  String profession;
  double workHours;
  String workIntensity; // 'low', 'medium', 'high'
  double sportHours; // hours per week
  String sportIntensity; // 'low', 'medium', 'high'
  double freetimeHours;
  String freetimeIntensity; // 'low', 'medium', 'high'
  double sleepHours;
  int calculatedMoveGoal;

  ActivityData({
    this.activityLevel = 'moderate',
    this.profession = '',
    this.workHours = 8.0,
    this.workIntensity = 'low',
    this.sportHours = 3.0,
    this.sportIntensity = 'medium',
    this.freetimeHours = 5.0,
    this.freetimeIntensity = 'low',
    this.sleepHours = 8.0,
    this.calculatedMoveGoal = 400,
  });
}

class MoveGoalCalculator {
  static const List<ProfessionPreset> professions = [
    ProfessionPreset(
      id: 'desk',
      title: 'IT / Software / Desk Job',
      subtitle: 'Office work, sitting for most of the shift',
      icon: '💻',
      workIntensity: 'low',
      typicalWorkHours: 8.0,
    ),
    ProfessionPreset(
      id: 'teacher',
      title: 'Teacher / Educator',
      subtitle: 'Classroom teaching, standing & walking',
      icon: '📚',
      workIntensity: 'medium',
      typicalWorkHours: 8.0,
    ),
    ProfessionPreset(
      id: 'retail',
      title: 'Retail / Customer Service',
      subtitle: 'On your feet, moving around store',
      icon: '🛍️',
      workIntensity: 'medium',
      typicalWorkHours: 8.0,
    ),
    ProfessionPreset(
      id: 'healthcare',
      title: 'Nurse / Healthcare / Doctor',
      subtitle: 'High pacing, rounds & patient care',
      icon: '🩺',
      workIntensity: 'high',
      typicalWorkHours: 9.0,
    ),
    ProfessionPreset(
      id: 'trades',
      title: 'Delivery / Electrician / Trades',
      subtitle: 'Active driving, lifting, installing',
      icon: '🚚',
      workIntensity: 'medium',
      typicalWorkHours: 8.5,
    ),
    ProfessionPreset(
      id: 'construction',
      title: 'Construction / Warehouse / Labor',
      subtitle: 'Heavy lifting, physical exertion',
      icon: '🏗️',
      workIntensity: 'high',
      typicalWorkHours: 8.0,
    ),
    ProfessionPreset(
      id: 'hospitality',
      title: 'Chef / Server / Barista',
      subtitle: 'Fast-paced kitchen/floor movement',
      icon: '☕',
      workIntensity: 'medium',
      typicalWorkHours: 8.0,
    ),
    ProfessionPreset(
      id: 'athlete',
      title: 'Athlete / Fitness Trainer',
      subtitle: 'Continuous athletic training & coaching',
      icon: '🏋️',
      workIntensity: 'high',
      typicalWorkHours: 6.0,
    ),
    ProfessionPreset(
      id: 'student',
      title: 'Student',
      subtitle: 'Classes, study sessions & campus walking',
      icon: '🎓',
      workIntensity: 'low',
      typicalWorkHours: 6.0,
    ),
    ProfessionPreset(
      id: 'other',
      title: 'Other (I\'ll set this myself)',
      subtitle: 'Custom schedule & manual intensity adjustment',
      icon: '⚙️',
      workIntensity: 'low',
      typicalWorkHours: 8.0,
    ),
  ];

  /// Calculates Basal Metabolic Rate (BMR) using Mifflin-St Jeor equation
  static double calculateBmr({
    required double weightKg,
    required int heightCm,
    required DateTime? birthDate,
    required String sex,
  }) {
    int age = 25; // standard default if DOB unknown
    if (birthDate != null) {
      final now = DateTime.now();
      age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      if (age < 13) age = 13;
      if (age > 100) age = 100;
    }

    // Mifflin-St Jeor: 10*W + 6.25*H - 5*Age (+5 for male, -161 for female, -78 for unspecified)
    double bmr = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age);
    if (sex.toLowerCase() == 'male') {
      bmr += 5;
    } else if (sex.toLowerCase() == 'female') {
      bmr -= 161;
    } else {
      bmr -= 78; // neutral midpoint
    }

    return bmr > 800 ? bmr : 800;
  }

  /// Intensity factor multiplier per hour
  static double _intensityFactor(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'high':
        return 1.8;
      case 'medium':
        return 1.4;
      case 'low':
      default:
        return 1.15;
    }
  }

  /// Calculates daily move goal active calories isolated from BMR
  static int calculateMoveGoal({
    required double weightKg,
    required int heightCm,
    required DateTime? birthDate,
    required String sex,
    required ActivityData activity,
  }) {
    final bmr = calculateBmr(
      weightKg: weightKg,
      heightCm: heightCm,
      birthDate: birthDate,
      sex: sex,
    );

    // Hourly base metabolic expenditure
    final hourlyBase = bmr / 24.0;

    // Work active contribution
    final workMultiplier = _intensityFactor(activity.workIntensity);
    final workActiveBurn = activity.workHours * (hourlyBase * (workMultiplier - 1.0));

    // Sport active contribution (sport hours is weekly, so divide by 7)
    final sportDailyHours = activity.sportHours / 7.0;
    final sportMultiplier = activity.sportIntensity.toLowerCase() == 'high'
        ? 4.5
        : (activity.sportIntensity.toLowerCase() == 'medium' ? 3.2 : 2.0);
    final sportActiveBurn = sportDailyHours * (hourlyBase * (sportMultiplier - 1.0));

    // Freetime active contribution
    final freetimeMultiplier = _intensityFactor(activity.freetimeIntensity);
    final freetimeActiveBurn = activity.freetimeHours * (hourlyBase * (freetimeMultiplier - 1.0));

    // Total active calorie burn (Move Goal)
    double totalActive = workActiveBurn + sportActiveBurn + freetimeActiveBurn;

    // Minimum sensible active calories
    if (totalActive < 150) totalActive = 150;
    if (totalActive > 1500) totalActive = 1500;

    return (totalActive / 10).round() * 10; // round to nearest 10
  }

  /// Returns presets for Quick-Pick activity levels
  static ActivityData getQuickPickPreset(String level) {
    switch (level.toLowerCase()) {
      case 'light':
        return ActivityData(
          activityLevel: 'light',
          workHours: 8.0,
          workIntensity: 'low',
          sportHours: 1.5,
          sportIntensity: 'low',
          freetimeHours: 5.0,
          freetimeIntensity: 'low',
          sleepHours: 8.0,
        );
      case 'high':
        return ActivityData(
          activityLevel: 'high',
          workHours: 8.0,
          workIntensity: 'high',
          sportHours: 5.5,
          sportIntensity: 'high',
          freetimeHours: 4.0,
          freetimeIntensity: 'medium',
          sleepHours: 8.0,
        );
      case 'moderate':
      default:
        return ActivityData(
          activityLevel: 'moderate',
          workHours: 8.0,
          workIntensity: 'medium',
          sportHours: 3.5,
          sportIntensity: 'medium',
          freetimeHours: 5.0,
          freetimeIntensity: 'low',
          sleepHours: 8.0,
        );
    }
  }

  /// Returns estimated calorie range string for a quick-pick level
  static String getQuickPickEstimate({
    required String level,
    required double weightKg,
    required int heightCm,
    required DateTime? birthDate,
    required String sex,
  }) {
    final preset = getQuickPickPreset(level);
    final goal = calculateMoveGoal(
      weightKg: weightKg,
      heightCm: heightCm,
      birthDate: birthDate,
      sex: sex,
      activity: preset,
    );

    final min = ((goal - 50) / 10).round() * 10;
    final max = ((goal + 60) / 10).round() * 10;
    return '~$min–$max kcal/day';
  }
}
