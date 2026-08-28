import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stream of Supabase auth state changes (sign in, sign out, token refresh, initial session).
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Current authenticated Supabase user, or null if unauthenticated / session still resolving.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider).valueOrNull;
  return authState?.session?.user ?? Supabase.instance.client.auth.currentUser;
});

/// Current active Supabase session, or null if unauthenticated.
final authSessionProvider = Provider<Session?>((ref) {
  final authState = ref.watch(authStateChangesProvider).valueOrNull;
  return authState?.session ?? Supabase.instance.client.auth.currentSession;
});
