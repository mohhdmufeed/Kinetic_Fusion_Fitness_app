import 'package:flutter/material.dart';
import '../../core/utils/move_goal_calculator.dart';
import '../theme/app_theme.dart';

class ActivityLevelPicker extends StatefulWidget {
  final ActivityData initialData;
  final double weightKg;
  final int heightCm;
  final DateTime? birthDate;
  final String sex;
  final ValueChanged<ActivityData> onChanged;

  const ActivityLevelPicker({
    super.key,
    required this.initialData,
    this.weightKg = 70.0,
    this.heightCm = 175,
    this.birthDate,
    this.sex = 'unspecified',
    required this.onChanged,
  });

  @override
  State<ActivityLevelPicker> createState() => _ActivityLevelPickerState();
}

class _ActivityLevelPickerState extends State<ActivityLevelPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ActivityData _currentData;
  bool _showAdvanced = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialData.profession.isNotEmpty ? 1 : 0,
    );
    _currentData = widget.initialData;
    _recalculateGoal();
  }

  @override
  void didUpdateWidget(covariant ActivityLevelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weightKg != widget.weightKg ||
        oldWidget.heightCm != widget.heightCm ||
        oldWidget.birthDate != widget.birthDate ||
        oldWidget.sex != widget.sex) {
      _recalculateGoal();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _recalculateGoal() {
    final goal = MoveGoalCalculator.calculateMoveGoal(
      weightKg: widget.weightKg,
      heightCm: widget.heightCm,
      birthDate: widget.birthDate,
      sex: widget.sex,
      activity: _currentData,
    );
    setState(() {
      _currentData.calculatedMoveGoal = goal;
    });
    widget.onChanged(_currentData);
  }

  void _selectQuickPick(String level) {
    final preset = MoveGoalCalculator.getQuickPickPreset(level);
    setState(() {
      _currentData.activityLevel = level;
      _currentData.workHours = preset.workHours;
      _currentData.workIntensity = preset.workIntensity;
      _currentData.sportHours = preset.sportHours;
      _currentData.sportIntensity = preset.sportIntensity;
      _currentData.freetimeHours = preset.freetimeHours;
      _currentData.freetimeIntensity = preset.freetimeIntensity;
      _currentData.sleepHours = preset.sleepHours;
    });
    _recalculateGoal();
  }

  void _selectProfession(ProfessionPreset p) {
    setState(() {
      _currentData.profession = p.title;
      _currentData.workIntensity = p.workIntensity;
      _currentData.workHours = p.typicalWorkHours;
      _currentData.activityLevel = 'custom';
    });
    _recalculateGoal();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const navyColor = Color(0xFF26496C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Bar Selector
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(4),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: navyColor,
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? Colors.white60 : Colors.black87,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'By Activity Level'),
              Tab(text: 'By Profession'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab Bar Views
        SizedBox(
          height: 290,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildQuickPickTab(isDark, navyColor),
              _buildProfessionTab(isDark, navyColor),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Summary Card
        _buildMoveGoalSummaryCard(isDark, navyColor),

        const SizedBox(height: 12),

        // Advanced accordion toggle
        InkWell(
          onTap: () {
            setState(() => _showAdvanced = !_showAdvanced);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showAdvanced ? Icons.expand_less : Icons.tune_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _showAdvanced ? 'Hide manual adjustments' : 'Advanced: Adjust hours & intensities manually',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_showAdvanced) ...[
          const SizedBox(height: 12),
          _buildAdvancedSection(isDark),
        ],
      ],
    );
  }

  Widget _buildQuickPickTab(bool isDark, Color navyColor) {
    return Column(
      children: [
        _quickPickCard(
          level: 'light',
          title: 'Lightly Active',
          subtitle: 'Desk job, light walking, 1–2 gym sessions/wk',
          icon: Icons.directions_walk_rounded,
          isDark: isDark,
          navyColor: navyColor,
        ),
        const SizedBox(height: 10),
        _quickPickCard(
          level: 'moderate',
          title: 'Moderately Active',
          subtitle: 'Active daily movement, 3–4 workout sessions/wk',
          icon: Icons.fitness_center_rounded,
          isDark: isDark,
          navyColor: navyColor,
        ),
        const SizedBox(height: 10),
        _quickPickCard(
          level: 'high',
          title: 'Highly Active',
          subtitle: 'Physical work, heavy lifting, 5+ workouts/wk',
          icon: Icons.local_fire_department_rounded,
          isDark: isDark,
          navyColor: navyColor,
        ),
      ],
    );
  }

  Widget _quickPickCard({
    required String level,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required Color navyColor,
  }) {
    final isSelected = _currentData.activityLevel == level;
    final estimate = MoveGoalCalculator.getQuickPickEstimate(
      level: level,
      weightKg: widget.weightKg,
      heightCm: widget.heightCm,
      birthDate: widget.birthDate,
      sex: widget.sex,
    );

    return InkWell(
      onTap: () => _selectQuickPick(level),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? navyColor.withValues(alpha: 0.08)
              : (isDark ? Colors.grey.shade900 : Colors.white),
          border: Border.all(
            color: isSelected ? navyColor : (isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB)),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? navyColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? navyColor : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? navyColor : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          estimate,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? navyColor : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionTab(bool isDark, Color navyColor) {
    final filtered = MoveGoalCalculator.professions.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search bar
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search profession (e.g. IT, Teacher, Nurse)...',
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, idx) {
              final p = filtered[idx];
              final isSelected = _currentData.profession == p.title;

              return InkWell(
                onTap: () => _selectProfession(p),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? navyColor.withValues(alpha: 0.08)
                        : (isDark ? Colors.grey.shade900 : Colors.white),
                    border: Border.all(
                      color: isSelected ? navyColor : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(p.icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? navyColor : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                            Text(
                              p.subtitle,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: navyColor, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoveGoalSummaryCard(bool isDark, Color navyColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [navyColor, const Color(0xFF1b3550)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Move Goal Target',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '~${_currentData.calculatedMoveGoal} kcal / day',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Raw Hours & Intensities',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 14),

          // Work hours & intensity
          _sliderRow(
            label: 'Work: ${_currentData.workHours.toStringAsFixed(1)} hrs/day',
            value: _currentData.workHours,
            min: 0,
            max: 16,
            onChanged: (v) {
              setState(() => _currentData.workHours = v);
              _recalculateGoal();
            },
          ),
          _intensitySelector(
            current: _currentData.workIntensity,
            onChanged: (v) {
              setState(() => _currentData.workIntensity = v);
              _recalculateGoal();
            },
          ),
          const Divider(height: 24),

          // Sport hours/week & intensity
          _sliderRow(
            label: 'Exercise / Sport: ${_currentData.sportHours.toStringAsFixed(1)} hrs/week',
            value: _currentData.sportHours,
            min: 0,
            max: 20,
            onChanged: (v) {
              setState(() => _currentData.sportHours = v);
              _recalculateGoal();
            },
          ),
          _intensitySelector(
            current: _currentData.sportIntensity,
            onChanged: (v) {
              setState(() => _currentData.sportIntensity = v);
              _recalculateGoal();
            },
          ),
          const Divider(height: 24),

          // Sleep hours
          _sliderRow(
            label: 'Sleep: ${_currentData.sleepHours.toStringAsFixed(1)} hrs/day',
            value: _currentData.sleepHours,
            min: 4,
            max: 12,
            onChanged: (v) {
              setState(() => _currentData.sleepHours = v);
              _recalculateGoal();
            },
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) * 2).toInt(),
          activeColor: const Color(0xFF26496C),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _intensitySelector({
    required String current,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: ['low', 'medium', 'high'].map((lvl) {
        final isSel = current.toLowerCase() == lvl;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: Text(
                lvl[0].toUpperCase() + lvl.substring(1),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSel ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSel,
              selectedColor: const Color(0xFF26496C),
              onSelected: (_) => onChanged(lvl),
            ),
          ),
        );
      }).toList(),
    );
  }
}
