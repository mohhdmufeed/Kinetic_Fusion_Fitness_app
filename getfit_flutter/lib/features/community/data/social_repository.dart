import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';

// ─── Data Models ────────────────────────────────────────────────────────────

class SocialPost {
  final String id;
  final String authorUsername;
  final String postType; // text, photo, video, poll
  final String caption;
  final List<String> mediaUrls;
  final String? workoutSessionId;
  final String visibility;
  final List<String> tags;
  final List<PollOption> pollOptions;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final DateTime createdAt;

  SocialPost({
    required this.id,
    required this.authorUsername,
    required this.postType,
    required this.caption,
    this.mediaUrls = const [],
    this.workoutSessionId,
    required this.visibility,
    this.tags = const [],
    this.pollOptions = const [],
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory SocialPost.fromJson(Map<String, dynamic> j) => SocialPost(
        id: j['id'] as String? ?? '',
        authorUsername: (j['author'] as Map<String, dynamic>?)?['username'] as String? ?? '',
        postType: j['post_type'] as String? ?? 'text',
        caption: j['caption'] as String? ?? '',
        mediaUrls: List<String>.from((j['media_urls'] as List?)?.map((e) => e.toString()) ?? []),
        workoutSessionId: j['workout_session_id'] as String?,
        visibility: j['visibility'] as String? ?? 'gym_only',
        tags: List<String>.from((j['tags'] as List?)?.map((t) => (t as Map)['tag'].toString()) ?? []),
        pollOptions: ((j['poll_options'] as List?) ?? [])
            .map((o) => PollOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        likeCount: j['like_count'] as int? ?? 0,
        commentCount: j['comment_count'] as int? ?? 0,
        isLiked: j['is_liked'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  SocialPost copyWith({int? likeCount, bool? isLiked}) => SocialPost(
        id: id,
        authorUsername: authorUsername,
        postType: postType,
        caption: caption,
        mediaUrls: mediaUrls,
        workoutSessionId: workoutSessionId,
        visibility: visibility,
        tags: tags,
        pollOptions: pollOptions,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount,
        isLiked: isLiked ?? this.isLiked,
        createdAt: createdAt,
      );
}

class PollOption {
  final int id;
  final String text;
  final int voteCount;

  PollOption({required this.id, required this.text, required this.voteCount});

  factory PollOption.fromJson(Map<String, dynamic> j) => PollOption(
        id: j['id'] as int? ?? 0,
        text: j['text'] as String? ?? '',
        voteCount: j['vote_count'] as int? ?? 0,
      );
}

// ─── Repository ─────────────────────────────────────────────────────────────

class SocialRepository {
  final Dio _dio;

  SocialRepository(this._dio);

  /// Fetch feed. [feedType] = 'for_you' | 'following'
  Future<List<SocialPost>> fetchFeed(String feedType) async {
    try {
      final resp = await _dio.get('/social/posts/', queryParameters: {'feed': feedType});
      final list = resp.data as List? ?? [];
      return list.map((j) => SocialPost.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException {
      return [];
    }
  }

  /// Create a post.
  Future<SocialPost?> createPost({
    required String postType,
    required String caption,
    String visibility = 'gym_only',
    List<String> tags = const [],
    List<String> pollOptions = const [],
  }) async {
    try {
      final data = {
        'post_type': postType,
        'caption': caption,
        'visibility': visibility,
        'tag_list': tags,
        if (pollOptions.isNotEmpty) 'poll_options_input': pollOptions,
      };
      final resp = await _dio.post('/social/posts/', data: data);
      return SocialPost.fromJson(resp.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  /// Toggle like on a post.
  Future<bool> likePost(String postId, bool currentlyLiked) async {
    try {
      if (currentlyLiked) {
        await _dio.delete('/social/posts/$postId/like/');
        return false;
      } else {
        await _dio.post('/social/posts/$postId/like/');
        return true;
      }
    } on DioException {
      return currentlyLiked; // Optimistic rollback
    }
  }

  /// Vote on a poll option.
  Future<bool> votePoll(int optionId) async {
    try {
      await _dio.post('/social/poll/$optionId/vote/');
      return true;
    } on DioException {
      return false;
    }
  }

  /// Report a post.
  Future<bool> reportPost(String postId, String reason) async {
    try {
      await _dio.post('/social/posts/$postId/report/', data: {
        'post': postId,
        'reason': reason,
      });
      return true;
    } on DioException {
      return false;
    }
  }

  /// Follow a user.
  Future<bool> followUser(String username) async {
    try {
      await _dio.post('/social/follow/', data: {'followed_username': username});
      return true;
    } on DioException {
      return false;
    }
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

enum FeedType { forYou, following }

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  final auth = ref.watch(authServiceProvider);
  return SocialRepository(auth.dioClient);
});

class FeedNotifier extends StateNotifier<AsyncValue<List<SocialPost>>> {
  FeedNotifier(this._repo, this._feedType) : super(const AsyncValue.loading()) {
    load();
  }

  final SocialRepository _repo;
  final FeedType _feedType;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final posts = await _repo.fetchFeed(
          _feedType == FeedType.forYou ? 'for_you' : 'following');
      state = AsyncValue.data(posts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleLike(String postId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final idx = current.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final post = current[idx];
    final newLiked = !post.isLiked;
    final newCount = newLiked ? post.likeCount + 1 : post.likeCount - 1;
    // Optimistic update
    final updated = [...current];
    updated[idx] = post.copyWith(isLiked: newLiked, likeCount: newCount);
    state = AsyncValue.data(updated);
    // Fire API
    await _repo.likePost(postId, post.isLiked);
  }

  Future<void> createPost({
    required String postType,
    required String caption,
    List<String> tags = const [],
    List<String> pollOptions = const [],
  }) async {
    final newPost = await _repo.createPost(
      postType: postType,
      caption: caption,
      tags: tags,
      pollOptions: pollOptions,
    );
    if (newPost != null) {
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([newPost, ...current]);
    }
  }
}

final forYouFeedProvider =
    StateNotifierProvider.autoDispose<FeedNotifier, AsyncValue<List<SocialPost>>>((ref) {
  final repo = ref.watch(socialRepositoryProvider);
  return FeedNotifier(repo, FeedType.forYou);
});

final followingFeedProvider =
    StateNotifierProvider.autoDispose<FeedNotifier, AsyncValue<List<SocialPost>>>((ref) {
  final repo = ref.watch(socialRepositoryProvider);
  return FeedNotifier(repo, FeedType.following);
});
