import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';
import '../services/barcode_nutrition_service.dart';

/// Modal bottom sheet providing camera viewfinder and barcode input for instant nutrition lookup
class BarcodeScannerSheet extends ConsumerStatefulWidget {
  const BarcodeScannerSheet({super.key});

  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BarcodeScannerSheet(),
    );
  }

  @override
  ConsumerState<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends ConsumerState<BarcodeScannerSheet> {
  final TextEditingController _manualBarcodeCtrl = TextEditingController();
  bool _isLoading = false;
  bool _permissionDenied = false;
  String? _errorMessage;
  Ingredient? _resolvedIngredient;
  double _portionGrams = 100.0;
  final TextEditingController _portionCtrl = TextEditingController(text: '100');

  @override
  void dispose() {
    _manualBarcodeCtrl.dispose();
    _portionCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeScanned(String barcode) async {
    final cleanCode = barcode.trim();
    if (cleanCode.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final db = ref.read(databaseProvider);
    final service = BarcodeNutritionService(database: db);
    final result = await service.lookupBarcode(cleanCode);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.status == BarcodeLookupStatus.success && result.ingredient != null) {
      setState(() {
        _resolvedIngredient = result.ingredient;
      });
    } else if (result.status == BarcodeLookupStatus.offlineUncached) {
      setState(() {
        _errorMessage = 'Offline: Barcode not found in local cache. Please search manually.';
      });
    } else if (result.status == BarcodeLookupStatus.notFound) {
      setState(() {
        _errorMessage = 'Product not found for barcode $cleanCode. Please enter manually.';
      });
    } else {
      setState(() {
        _errorMessage = result.message ?? 'Failed to look up barcode.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _resolvedIngredient != null ? _buildPortionStep() : _buildScannerStep(),
    );
  }

  Widget _buildScannerStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: AppColors.accent, size: 24),
                SizedBox(width: 8),
                Text(
                  'Scan Food Barcode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_permissionDenied) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.camera_alt_outlined, color: AppColors.warning, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Camera permission denied. Enter barcode numbers below or search manually.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          // Stylized Viewfinder Area
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded, color: Colors.white.withOpacity(0.5), size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'Align barcode within frame',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                    ),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Manual barcode entry field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _manualBarcodeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter barcode (e.g. 737628064502)',
                  prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: _handleBarcodeScanned,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _handleBarcodeScanned(_manualBarcodeCtrl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Lookup'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortionStep() {
    final ing = _resolvedIngredient!;
    final factor = _portionGrams / 100.0;
    final cal = (ing.energy * factor).toInt();
    final prot = (ing.protein * factor).toStringAsFixed(1);
    final carbs = (ing.carbs * factor).toStringAsFixed(1);
    final fat = (ing.fat * factor).toStringAsFixed(1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                ing.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _macroMetric('$cal', 'kcal'),
              _macroMetric('${prot}g', 'Protein'),
              _macroMetric('${carbs}g', 'Carbs'),
              _macroMetric('${fat}g', 'Fat'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _portionCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Portion size',
            suffixText: 'grams',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (v) {
            setState(() {
              _portionGrams = double.tryParse(v) ?? 100.0;
            });
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'id': ing.id,
                'amount': _portionGrams,
                'name': ing.name,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add to Food Diary', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _macroMetric(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
      ],
    );
  }
}
