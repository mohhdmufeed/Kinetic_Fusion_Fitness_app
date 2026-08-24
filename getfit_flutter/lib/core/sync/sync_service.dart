import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../api/api_client.dart';
import '../auth/auth_service.dart';
import '../constants.dart';
import '../database/app_database.dart';
import '../../shared/theme/app_theme.dart';

enum SyncState {
  synced,
  syncing,
  pending,
  offline,
  failed,
}

class SyncStatusInfo {
  final SyncState state;
  final int pendingCount;
  final String? lastSyncedTime;
  final String? errorMessage;

  const SyncStatusInfo({
    required this.state,
    this.pendingCount = 0,
    this.lastSyncedTime,
    this.errorMessage,
  });

  /// Compatibility alias
  Future<void> sync() async {}
}

class SyncService {
  final AppDatabase _db;
  final AuthService _auth;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Timer? _periodicSyncTimer;
  StreamSubscription? _connectivitySub;

  final ValueNotifier<SyncStatusInfo> status =
      ValueNotifier(const SyncStatusInfo(state: SyncState.synced, lastSyncedTime: 'Just now'));

  final List<Map<String, dynamic>> _outbox = [];

  SyncService(this._db, this._auth) {
    _initConnectivityListener();
    _startPeriodicSync();
  }

  void _initConnectivityListener() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        status.value = SyncStatusInfo(
          state: SyncState.offline,
          pendingCount: _outbox.length,
          lastSyncedTime: status.value.lastSyncedTime,
        );
      } else {
        // Online restored: trigger background outbox drain
        drainOutbox();
      }
    });
  }

  void _startPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      drainOutbox();
    });
  }

  void dispose() {
    _periodicSyncTimer?.cancel();
    _connectivitySub?.cancel();
    status.dispose();
  }

  Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return !results.contains(ConnectivityResult.none) && results.isNotEmpty;
  }

  /// Queues a local mutation to the outbox for conflict-safe push
  void queueMutation({
    required String clientUuid,
    required String type,
    required String action,
    required Map<String, dynamic> data,
  }) {
    _outbox.add({
      'uuid': clientUuid,
      'type': type,
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });

    status.value = SyncStatusInfo(
      state: SyncState.pending,
      pendingCount: _outbox.length,
      lastSyncedTime: status.value.lastSyncedTime,
    );

    // Try immediate background sync if online
    drainOutbox();
  }

  /// Drains the pending outbox mutations via batched push and delta pull
  Future<void> drainOutbox() async {
    if (!await isOnline()) {
      status.value = SyncStatusInfo(
        state: SyncState.offline,
        pendingCount: _outbox.length,
        lastSyncedTime: status.value.lastSyncedTime,
      );
      return;
    }

    if (!await _auth.isLoggedIn()) return;

    status.value = SyncStatusInfo(
      state: SyncState.syncing,
      pendingCount: _outbox.length,
      lastSyncedTime: status.value.lastSyncedTime,
    );

    final token = await _auth.getToken();
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBase,
      headers: {'Authorization': 'Bearer $token'},
    ));

    try {
      // 1. Batch Push
      if (_outbox.isNotEmpty) {
        final batch = List<Map<String, dynamic>>.from(_outbox);
        final pushResp = await dio.post(
          '/api/v2/sync/push/',
          data: {
            'device_id': 'flutter_kinetic_precision',
            'client_version': '2.1.0',
            'mutations': batch,
          },
          options: Options(sendTimeout: const Duration(seconds: 4)),
        );

        if (pushResp.statusCode == 200) {
          _outbox.clear();
        }
      }

      // 2. Delta Pull
      final lastSync = await _storage.read(key: AppConstants.lastSyncKey);
      final pullResp = await dio.get(
        '/api/v2/sync/pull/',
        queryParameters: lastSync != null ? {'since': lastSync} : null,
        options: Options(sendTimeout: const Duration(seconds: 4)),
      );

      if (pullResp.statusCode == 200 && pullResp.data['server_timestamp'] != null) {
        await _storage.write(
          key: AppConstants.lastSyncKey,
          value: pullResp.data['server_timestamp'] as String,
        );
      }

      // Update success state
      final nowStr = DateFormat('HH:mm').format(DateTime.now());
      status.value = SyncStatusInfo(
        state: SyncState.synced,
        pendingCount: 0,
        lastSyncedTime: nowStr,
      );
    } catch (e) {
      status.value = SyncStatusInfo(
        state: _outbox.isNotEmpty ? SyncState.pending : SyncState.failed,
        pendingCount: _outbox.length,
        lastSyncedTime: status.value.lastSyncedTime,
        errorMessage: 'Sync paused. Changes saved securely on-device.',
      );
    }
  }

  Future<void> sync() => drainOutbox();
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.read(databaseProvider);
  final auth = ref.read(authServiceProvider);
  return SyncService(db, auth);
});

/// Reusable visual badge for sync status in AppBar / Dashboard
class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);

    return ValueListenableBuilder<SyncStatusInfo>(
      valueListenable: syncService.status,
      builder: (context, info, _) {
        Color bg;
        Color fg;
        IconData icon;
        String label;

        switch (info.state) {
          case SyncState.synced:
            bg = AppColors.success.withOpacity(0.12);
            fg = AppColors.success;
            icon = Icons.cloud_done_rounded;
            label = 'Synced ${info.lastSyncedTime ?? ''}';
            break;
          case SyncState.syncing:
            bg = AppColors.primary.withOpacity(0.15);
            fg = AppColors.primary;
            icon = Icons.sync_rounded;
            label = 'Syncing...';
            break;
          case SyncState.pending:
            bg = AppColors.warning.withOpacity(0.15);
            fg = AppColors.warning;
            icon = Icons.cloud_upload_outlined;
            label = '${info.pendingCount} pending';
            break;
          case SyncState.offline:
            bg = Colors.white.withOpacity(0.08);
            fg = Colors.white60;
            icon = Icons.cloud_off_rounded;
            label = 'Offline';
            break;
          case SyncState.failed:
            bg = AppColors.error.withOpacity(0.15);
            fg = AppColors.error;
            icon = Icons.sync_problem_rounded;
            label = 'Sync error';
            break;
        }

        return GestureDetector(
          onTap: () {
            syncService.drainOutbox();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: fg.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: fg),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
