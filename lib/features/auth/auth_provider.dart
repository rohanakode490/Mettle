import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/database/supabase_provider.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((event) => event.session?.user);
}

@riverpod
User? currentUser(Ref ref) {
  return ref.watch(authStateProvider).value;
}
