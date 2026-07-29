import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';

class ModerationService {
  ModerationService._();

  static Set<String>? _blockedUserIdsCache;

  static Future<Set<String>> getBlockedUserIds({bool forceRefresh = false}) async {
    if (!forceRefresh && _blockedUserIdsCache != null) {
      return _blockedUserIdsCache!;
    }

    if (currentUserUid.isEmpty) {
      _blockedUserIdsCache = <String>{};
      return _blockedUserIdsCache!;
    }

    try {
      final rows = await SupaFlow.client
          .from('user_blocks')
          .select('blocked_user_id')
          .eq('blocker_id', currentUserUid) as List;
      _blockedUserIdsCache = rows
          .map((e) => e['blocked_user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      _blockedUserIdsCache ??= <String>{};
    }
    return _blockedUserIdsCache!;
  }

  static Future<bool> isUserBlocked(String? userId) async {
    if (userId == null || userId.isEmpty) {
      return false;
    }
    final blocked = await getBlockedUserIds();
    return blocked.contains(userId);
  }

  static Future<void> reportListing({
    required String listingId,
    required String reason,
    String? details,
  }) async {
    if (currentUserUid.isEmpty) {
      throw StateError('login_required');
    }
    await SupaFlow.client.from('listing_reports').upsert(
      {
        'listing_id': listingId,
        'reporter_id': currentUserUid,
        'reason': reason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
      onConflict: 'listing_id,reporter_id',
    );
  }

  static Future<void> blockUser(String blockedUserId) async {
    if (currentUserUid.isEmpty) {
      throw StateError('login_required');
    }
    if (blockedUserId.isEmpty || blockedUserId == currentUserUid) {
      throw StateError('invalid_user');
    }
    await SupaFlow.client.from('user_blocks').upsert(
      {
        'blocker_id': currentUserUid,
        'blocked_user_id': blockedUserId,
      },
      onConflict: 'blocker_id,blocked_user_id',
    );
    _blockedUserIdsCache = {
      ...?_blockedUserIdsCache,
      blockedUserId,
    };
  }

  static void clearCache() {
    _blockedUserIdsCache = null;
  }
}
