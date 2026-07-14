import '/backend/supabase/supabase.dart';

Future<User?> emailSignInFunc(
  String email,
  String password,
) async {
  final AuthResponse res = await SupaFlow.client.auth
      .signInWithPassword(email: email, password: password);
  return res.user;
}

Future<User?> emailCreateAccountFunc(
  String email,
  String password,
) async {
  final AuthResponse res =
      await SupaFlow.client.auth.signUp(email: email, password: password);

  // A session means the user is signed in (email confirmation disabled).
  // lastSignInAt is often null right after signUp even with a valid session.
  if (res.session != null) {
    return res.user;
  }

  // Email confirmation required — user created but not signed in yet.
  return null;
}
