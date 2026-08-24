import 'dart:math';
import 'package:flutter/material.dart';

class GymQuoteCard extends StatefulWidget {
  const GymQuoteCard({super.key});

  @override
  State<GymQuoteCard> createState() => _GymQuoteCardState();
}

class _GymQuoteCardState extends State<GymQuoteCard> {
  final List<Map<String, String>> _quotes = const [
    {
      'quote': 'The body achieves what the mind believes.',
      'author': 'Napoleon Hill',
    },
    {
      'quote': 'Action is the foundational key to all success.',
      'author': 'Pablo Picasso',
    },
    {
      'quote': 'Small daily improvements over time lead to stunning results.',
      'author': 'Robin Sharma',
    },
    {
      'quote': 'The clock is ticking. Are you becoming the person you want to be?',
      'author': 'Greg Plitt',
    },
    {
      'quote': 'Discipline is choosing between what you want now and what you want most.',
      'author': 'Abraham Lincoln',
    },
    {
      'quote': 'Success starts with self-discipline.',
      'author': 'Dwayne Johnson',
    },
    {
      'quote': 'No matter how slow you go, you are still lapping everybody on the couch.',
      'author': 'Anonymous',
    },
    {
      'quote': 'Strength does not come from physical capacity. It comes from an indomitable will.',
      'author': 'Mahatma Gandhi',
    },
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = Random().nextInt(_quotes.length);
  }

  void _nextQuote() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _quotes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);
    final current = _quotes[_currentIndex];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _nextQuote,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                navyColor.withValues(alpha: 0.05),
                const Color(0xFF0284C7).withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text('💡', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text(
                        'Daily Motivation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: navyColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: navyColor),
                    onPressed: _nextQuote,
                    tooltip: 'Next Quote',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '“${current['quote']}”',
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '— ${current['author']}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
