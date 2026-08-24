import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../notifications/screens/notifications_sheet.dart';
import '../data/social_repository.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreatePostSheet(
        onPost: (type, caption, tags, pollOptions) {
          final notifier = _tabController.index == 0
              ? ref.read(forYouFeedProvider.notifier)
              : ref.read(followingFeedProvider.notifier);
          notifier.createPost(
            postType: type.toLowerCase().replaceAll(' ', '_'),
            caption: caption,
            tags: tags,
            pollOptions: pollOptions,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final forYouFeed = ref.watch(forYouFeedProvider);
    final followingFeed = ref.watch(followingFeedProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top App Bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Community',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _showCreatePostSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Post',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => NotificationsSheet.show(context),
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white70, size: 22),
                  ),
                  InkWell(
                    onTap: () => context.go('/profile'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: const CircleAvatar(
                        radius: 17,
                        backgroundColor: Color(0xFF1E293B),
                        child: Icon(Icons.person_rounded,
                            color: AppColors.primary, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Sub-tabs ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [Tab(text: 'For you'), Tab(text: 'Following')],
              ),
            ),
            const SizedBox(height: 8),
            // ── Feed ────────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFeedAsync(forYouFeed, FeedType.forYou),
                  _buildFeedAsync(followingFeed, FeedType.following),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedAsync(
      AsyncValue<List<SocialPost>> asyncPosts, FeedType feedType) {
    return asyncPosts.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => _buildErrorState(feedType),
      data: (posts) {
        if (posts.isEmpty) return _buildEmptyState();
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: const Color(0xFF131A26),
          onRefresh: () async {
            if (feedType == FeedType.forYou) {
              ref.read(forYouFeedProvider.notifier).load();
            } else {
              ref.read(followingFeedProvider.notifier).load();
            }
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, idx) =>
                _PostCard(post: posts[idx], feedType: feedType),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 56, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text('No posts yet',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Be the first to share something!',
                style: TextStyle(color: Colors.white30, fontSize: 13)),
          ],
        ),
      );

  Widget _buildErrorState(FeedType feedType) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('Could not load feed',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (feedType == FeedType.forYou) {
                  ref.read(forYouFeedProvider.notifier).load();
                } else {
                  ref.read(followingFeedProvider.notifier).load();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}

// ─── Post Card ──────────────────────────────────────────────────────────────

class _PostCard extends ConsumerWidget {
  final SocialPost post;
  final FeedType feedType;

  const _PostCard({required this.post, required this.feedType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF141517),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF222326)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.primary.withOpacity(0.18),
                child: Text(
                  post.authorUsername.isNotEmpty
                      ? post.authorUsername[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorUsername,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text(
                      _timeAgo(post.createdAt),
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Type chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2434),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post.postType.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Caption
          if (post.caption.isNotEmpty)
            Text(post.caption,
                style:
                    const TextStyle(color: Colors.white, fontSize: 14, height: 1.35)),
          // Poll options (real data)
          if (post.postType == 'poll' && post.pollOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...post.pollOptions.map(
              (opt) => _PollOptionRow(option: opt, post: post, feedType: feedType),
            ),
          ],
          const SizedBox(height: 14),
          // Action row
          Row(
            children: [
              // Like button — optimistic update via notifier
              InkWell(
                onTap: () {
                  if (feedType == FeedType.forYou) {
                    ref.read(forYouFeedProvider.notifier).toggleLike(post.id);
                  } else {
                    ref.read(followingFeedProvider.notifier).toggleLike(post.id);
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      post.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: post.isLiked ? Colors.pinkAccent : Colors.white60,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.likeCount}',
                      style: TextStyle(
                          color: post.isLiked ? Colors.pinkAccent : Colors.white60,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      color: Colors.white60, size: 18),
                  const SizedBox(width: 6),
                  Text('${post.commentCount}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.share_rounded, color: Colors.white38, size: 18),
            ],
          ),
        ],
      ),
    ),
  );
}

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _PollOptionRow extends ConsumerWidget {
  final PollOption option;
  final SocialPost post;
  final FeedType feedType;

  const _PollOptionRow(
      {required this.option, required this.post, required this.feedType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalVotes = post.pollOptions.fold(0, (s, o) => s + o.voteCount);
    final pct = totalVotes > 0 ? option.voteCount / totalVotes : 0.0;
    return GestureDetector(
      onTap: () {
        final repo = ref.read(socialRepositoryProvider);
        repo.votePoll(option.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF182230),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF28364A)),
        ),
        child: Row(
          children: [
            Text(option.text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Create Post Sheet ───────────────────────────────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  final void Function(
      String type, String caption, List<String> tags, List<String> pollOptions) onPost;

  const _CreatePostSheet({required this.onPost});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _pollOptController = TextEditingController();
  String _selectedType = 'text';
  final List<String> _pollOptions = [];

  final _types = [
    ('text', 'Text', Icons.text_fields_rounded),
    ('photo', 'Photo', Icons.image_rounded),
    ('video', 'Video', Icons.videocam_rounded),
    ('poll', 'Poll', Icons.poll_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F141C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF263345), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Create a post',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white60)),
            ],
          ),
          const SizedBox(height: 12),
          // Type selector
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final (type, label, icon) = _types[idx];
                final isSel = type == _selectedType;
                return ChoiceChip(
                  avatar: Icon(icon, size: 14),
                  label: Text(label),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  backgroundColor: const Color(0xFF161E2A),
                  labelStyle: TextStyle(
                      color: isSel ? Colors.black : Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                  onSelected: (_) => setState(() => _selectedType = type),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _textController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Share your progress, workout tip, or question...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF141B26),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF243346)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF243346)),
              ),
            ),
          ),
          // Poll options input
          if (_selectedType == 'poll') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pollOptController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add poll option...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF141B26),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFF243346))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFF243346))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    final opt = _pollOptController.text.trim();
                    if (opt.isNotEmpty) {
                      setState(() {
                        _pollOptions.add(opt);
                        _pollOptController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add_circle_rounded,
                      color: AppColors.primary),
                ),
              ],
            ),
            if (_pollOptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _pollOptions
                    .map((o) => Chip(
                          label: Text(o,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11)),
                          backgroundColor: const Color(0xFF1A2434),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () =>
                              setState(() => _pollOptions.remove(o)),
                        ))
                    .toList(),
              ),
            ],
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final caption = _textController.text.trim();
                if (caption.isEmpty) return;
                widget.onPost(
                    _selectedType, caption, [], List.from(_pollOptions));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Post published!'),
                      backgroundColor: AppColors.primary),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Publish Post',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
