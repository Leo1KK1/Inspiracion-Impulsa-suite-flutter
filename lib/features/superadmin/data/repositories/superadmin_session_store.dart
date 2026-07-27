import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/superadmin_models.dart';

abstract interface class SuperadminSessionStore {
  Future<SuperadminSession?> read();
  Future<void> write(SuperadminSession session);
  Future<void> clear();
}

class PreferencesSuperadminSessionStore implements SuperadminSessionStore {
  static const _key = 'superadmin_session';

  @override
  Future<SuperadminSession?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    try {
      return SuperadminSession.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } on Object {
      await preferences.remove(_key);
      return null;
    }
  }

  @override
  Future<void> write(SuperadminSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}
