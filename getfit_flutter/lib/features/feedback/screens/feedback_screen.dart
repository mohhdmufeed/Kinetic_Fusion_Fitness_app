import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  String _category = 'suggestion';
  int _rating = 5;
  final _messageCtrl = TextEditingController();
  bool _submitted = false;

  final List<Map<String, dynamic>> _categories = const [
    {'id': 'suggestion', 'label': '💡 Feature Suggestion', 'color': Color(0xFF0284C7)},
    {'id': 'bug', 'label': '🐞 Report a Bug', 'color': Color(0xFFDC2626)},
    {'id': 'exercise', 'label': '🏋️ Request Exercise/Routine', 'color': Color(0xFF059669)},
    {'id': 'other', 'label': '💬 General Feedback', 'color': Color(0xFF8B5CF6)},
  ];

  Future<void> _submitFeedback() async {
    final msg = _messageCtrl.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback message')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    await db.insertFeedback(
      FeedbackEntriesCompanion(
        category: drift.Value(_category),
        message: drift.Value(msg),
        rating: drift.Value(_rating),
        createdAt: drift.Value(DateTime.now()),
        pendingSync: const drift.Value(true),
      ),
    );

    if (mounted) {
      setState(() => _submitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback & Support'),
        backgroundColor: navyColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _submitted
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💌', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    const Text(
                      'Thank You For Your Feedback!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navyColor),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your input helps make GetFit better for athletes worldwide.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Return to Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'How can we improve GetFit for you?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Let us know about bug reports, feature requests, or workout ideas.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),

                // Category Selector
                const Text('Feedback Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final isSel = _category == c['id'];
                    return ChoiceChip(
                      label: Text(
                        c['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: c['color'] as Color,
                      onSelected: (_) => setState(() => _category = c['id'] as String),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Satisfaction Rating
                const Text('App Satisfaction Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (idx) {
                    final star = idx + 1;
                    return IconButton(
                      icon: Icon(
                        star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setState(() => _rating = star),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // Message Text Field
                TextField(
                  controller: _messageCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Your Message / Details *',
                    hintText: 'Describe what happened or what you’d like to see added...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Submit Feedback',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
