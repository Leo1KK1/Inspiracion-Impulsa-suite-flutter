import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tenant_session.dart';

abstract interface class SessionRepository {
  Future<TenantSession?> restore();
  Future<void> save(TenantSession session);
  Future<void> clear();
}

class PreferencesSessionRepository implements SessionRepository {
  static const _key = 'tenant_session';

  @override
  Future<TenantSession?> restore() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    try {
      return TenantSession.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } on Object {
      await preferences.remove(_key);
      return null;
    }
  }

  @override
  Future<void> save(TenantSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}
