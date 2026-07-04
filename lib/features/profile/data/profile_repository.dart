import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._db);
  final AppDatabase _db;

  Future<Profile?> fetch(String id) async {
    final db = await _db.database;
    final rows = await db.query('profiles', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return Profile.fromMap(row);
  }

  Future<void> update(Profile profile) async {
    final db = await _db.database;
    final data = profile.toMap()
      ..['updated_at'] = DateTime.now().toIso8601String();
    await db.update('profiles', data, where: 'id = ?', whereArgs: [profile.id]);
  }

  Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final url = 'data:image/jpeg;base64,${_bytesToBase64(bytes)}';
      final db = await _db.database;
      await db.update(
        'profiles',
        {'avatar_url': url, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return url;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory('${appDir.path}/avatars');
    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await file.copy('${avatarsDir.path}/$fileName');
    final localPath = savedFile.path;
    final db = await _db.database;
    await db.update(
      'profiles',
      {'avatar_url': localPath, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return localPath;
  }

  Future<String> uploadKycDoc({
    required String userId,
    required File file,
    required String kind,
  }) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      return 'data:image/jpeg;base64,${_bytesToBase64(bytes)}';
    }
    final appDir = await getApplicationDocumentsDirectory();
    final kycDir = Directory('${appDir.path}/kyc_docs');
    if (!await kycDir.exists()) {
      await kycDir.create(recursive: true);
    }
    final fileName = '${kind}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await file.copy('${kycDir.path}/$fileName');
    return savedFile.path;
  }

  static String _bytesToBase64(Uint8List bytes) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    String result = '';
    for (var i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      result += chars[(b0 >> 2) & 0x3F];
      result += chars[((b0 << 4) | (b1 >> 4)) & 0x3F];
      result += i + 1 < bytes.length
          ? chars[((b1 << 2) | (b2 >> 6)) & 0x3F]
          : '=';
      result += i + 2 < bytes.length ? chars[b2 & 0x3F] : '=';
    }
    return result;
  }

  Future<void> submitKyc(
    String userId,
    String idPath,
    String residencePath,
  ) async {
    final db = await _db.database;
    await db.update(
      'profiles',
      {
        'id_doc_path': idPath,
        'residence_doc_path': residencePath,
        'verification_status': 'en_attente',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> submitCni(String userId, String idPath) async {
    final db = await _db.database;
    await db.update(
      'profiles',
      {
        'id_doc_path': idPath,
        'verification_status': 'en_attente',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> simulateVerifyKyc(String userId) async {
    final db = await _db.database;
    await db.update(
      'profiles',
      {
        'verification_status': 'verifie',
        'verified_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(databaseProvider));
});

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authStateProvider);
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  return ref.watch(profileRepositoryProvider).fetch(uid);
});
