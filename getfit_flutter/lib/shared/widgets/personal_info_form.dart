import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/unit_converter.dart';

class PersonalInfoData {
  DateTime? birthDate;
  String sex; // 'male', 'female', 'unspecified'
  int? heightCm;
  double? weightKg;
  String weightUnit; // 'kg', 'lbs'

  PersonalInfoData({
    this.birthDate,
    this.sex = 'unspecified',
    this.heightCm,
    this.weightKg,
    this.weightUnit = 'kg',
  });
}

class PersonalInfoForm extends StatefulWidget {
  final PersonalInfoData initialData;
  final GlobalKey<FormState> formKey;
  final ValueChanged<PersonalInfoData> onChanged;

  const PersonalInfoForm({
    super.key,
    required this.initialData,
    required this.formKey,
    required this.onChanged,
  });

  @override
  State<PersonalInfoForm> createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends State<PersonalInfoForm> {
  late DateTime? _birthDate;
  late String _sex;
  late String _weightUnit;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _birthDate = widget.initialData.birthDate;
    _sex = widget.initialData.sex;
    _weightUnit = widget.initialData.weightUnit;

    _heightController = TextEditingController(
      text: widget.initialData.heightCm != null
          ? widget.initialData.heightCm.toString()
          : '',
    );

    double? initialWeight = widget.initialData.weightKg;
    if (initialWeight != null) {
      if (_weightUnit == 'lbs') {
        initialWeight = UnitConverter.kgToLbs(initialWeight);
      }
      _weightController = TextEditingController(
        text: UnitConverter.formatWeight(initialWeight),
      );
    } else {
      _weightController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final height = int.tryParse(_heightController.text.trim());
    final rawWeight = double.tryParse(_weightController.text.trim());
    double? weightInKg;
    if (rawWeight != null) {
      weightInKg = _weightUnit == 'lbs'
          ? UnitConverter.lbsToKg(rawWeight)
          : rawWeight;
    }

    widget.onChanged(
      PersonalInfoData(
        birthDate: _birthDate,
        sex: _sex,
        heightCm: height,
        weightKg: weightInKg,
        weightUnit: _weightUnit,
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 120, 1, 1);
    final initial = _birthDate ?? DateTime(now.year - 25, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? initial : now,
      firstDate: firstDate,
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF26496C),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
      _notifyChange();
    }
  }

  void _handleUnitToggle(String newUnit) {
    if (_weightUnit == newUnit) return;

    final currentVal = double.tryParse(_weightController.text.trim());
    if (currentVal != null) {
      double converted;
      if (newUnit == 'lbs') {
        converted = UnitConverter.kgToLbs(currentVal);
      } else {
        converted = UnitConverter.lbsToKg(currentVal);
      }
      _weightController.text = UnitConverter.formatWeight(converted);
    }

    setState(() {
      _weightUnit = newUnit;
    });
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. DATE OF BIRTH
          const Text(
            'Date of Birth',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDateOfBirth,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : const Color(0xFFD1D5DB),
                ),
                borderRadius: BorderRadius.circular(8),
                color: isDark ? Colors.grey.shade900 : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: const Color(0xFF26496C),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _birthDate != null
                          ? DateFormat('d MMM yyyy').format(_birthDate!)
                          : 'Select your date of birth',
                      style: TextStyle(
                        fontSize: 15,
                        color: _birthDate != null
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey.shade500,
                        fontWeight: _birthDate != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. SEX / GENDER
          const Text(
            'Sex',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'male',
                  label: Text('Male'),
                  icon: Icon(Icons.male, size: 18),
                ),
                ButtonSegment<String>(
                  value: 'female',
                  label: Text('Female'),
                  icon: Icon(Icons.female, size: 18),
                ),
                ButtonSegment<String>(
                  value: 'unspecified',
                  label: Text('Prefer not to say'),
                ),
              ],
              selected: {_sex},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _sex = newSelection.first;
                });
                _notifyChange();
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF26496C);
                  }
                  return isDark ? Colors.grey.shade900 : Colors.white;
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return isDark ? Colors.white70 : Colors.black87;
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. HEIGHT
          const Text(
            'Height',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _notifyChange(),
            decoration: InputDecoration(
              hintText: 'e.g. 175',
              prefixIcon: const Icon(Icons.height, size: 20),
              suffixText: 'cm',
              suffixStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF26496C),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null; // allow if optional
              final val = int.tryParse(v.trim());
              if (val == null || val < 50 || val > 250) {
                return 'Enter a valid height between 50 and 250 cm';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // 4. WEIGHT
          const Text(
            'Weight',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _notifyChange(),
            decoration: InputDecoration(
              hintText: _weightUnit == 'kg' ? 'e.g. 72.5' : 'e.g. 160.0',
              prefixIcon: const Icon(Icons.monitor_weight_outlined, size: 20),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _unitPill('kg', _weightUnit == 'kg'),
                    const SizedBox(width: 4),
                    _unitPill('lbs', _weightUnit == 'lbs'),
                  ],
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final val = double.tryParse(v.trim());
              if (val == null) return 'Enter a valid number';
              if (_weightUnit == 'kg' && (val < 20 || val > 400)) {
                return 'Enter weight between 20 and 400 kg';
              }
              if (_weightUnit == 'lbs' && (val < 44 || val > 880)) {
                return 'Enter weight between 44 and 880 lbs';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _unitPill(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _handleUnitToggle(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF26496C) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
