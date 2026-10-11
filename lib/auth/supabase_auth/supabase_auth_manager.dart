import 'package:flutter/material.dart';

import '/auth/auth_manager.dart';
import '/backend/supabase/supabase.dart';
import '/dbdd/dbdd_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/moderation_service.dart';
import 'email_auth.dart';

import 'supabase_user_provider.dart';

export '/auth/base_auth_user_provider.dart';

class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  @override
  Future signOut() async {
    ModerationService.clearCache();
    try {
      await SupaFlow.client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out from Supabase: $e');
    } finally {
      currentUser = EkbkyrgyzdarSupabaseUser(null);
    }
  }

  @override
  Future deleteUser(BuildContext context) async {
    try {
      if (!loggedIn) {
        debugPrint('Error: delete user attempted with no logged in user!');
        return;
      }
      await currentUser?.delete();
      await signOut();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FFLocalizations.of(context).getText('dltacnt06'),
          ),
        ),
      );
      context.goNamed(DbddWidget.routeName);
    } on AuthException catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e) {
      debugPrint('Error during user deletion: $e');
      await signOut();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FFLocalizations.of(context).getText('dltacnt07'),
          ),
        ),
      );
    }
  }

  @override
  Future updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      if (!loggedIn) {
        print('Error: update email attempted with no logged in user!');
        return;
      }
      await currentUser?.updateEmail(email);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email change confirmation email sent')),
    );
  }

  Future updatePassword({
    required String newPassword,
    required BuildContext context,
  }) async {
    try {
      if (!loggedIn) {
        print('Error: update password attempted with no logged in user!');
        return;
      }
      await currentUser?.updatePassword(newPassword);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated successfully')),
    );
  }

  @override
  Future resetPassword({
    required String email,
    required BuildContext context,
    String? redirectTo,
  }) async {
    try {
      await SupaFlow.client.auth
          .resetPasswordForEmail(email, redirectTo: redirectTo);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
      return null;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset email sent')),
    );
  }

  @override
  Future<BaseAuthUser?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) =>
      _signInOrCreateAccount(
        context,
        () => emailSignInFunc(email, password),
      );

  @override
  Future<BaseAuthUser?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) =>
      _signInOrCreateAccount(
        context,
        () => emailCreateAccountFunc(email, password),
      );

  /// Tries to sign in or create an account using Supabase Auth.
  /// Returns the User object if sign in was successful.
  Future<BaseAuthUser?> _signInOrCreateAccount(
    BuildContext context,
    Future<User?> Function() signInFunc,
  ) async {
    try {
      final user = await signInFunc();
      if (user == null) {
        _showAuthError(context, 'autherrgen');
        return null;
      }
      final authUser = EkbkyrgyzdarSupabaseUser(user);

      // Update currentUser here in case user info needs to be used immediately
      // after a user is signed in. This should be handled by the user stream,
      // but adding here too in case of a race condition where the user stream
      // doesn't assign the currentUser in time.
      currentUser = authUser;
      AppStateNotifier.instance.update(authUser);
      return authUser;
    } on AuthException catch (e) {
      _showAuthError(context, _authErrorKey(e));
      return null;
    } catch (e) {
      debugPrint('Auth request failed: $e');
      _showAuthError(context, 'autherrnet');
      return null;
    }
  }

  /// Ключ перевода для ошибки Supabase Auth, чтобы пользователь не видел
  /// английский текст сервера.
  String _authErrorKey(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials')) {
      return 'autherrcred';
    }
    if (msg.contains('already registered') ||
        msg.contains('already been registered') ||
        msg.contains('already exists')) {
      return 'autherrtaken';
    }
    if (msg.contains('rate limit') ||
        msg.contains('too many') ||
        e.statusCode == '429') {
      return 'autherrrate';
    }
    if (msg.contains('password') && msg.contains('characters')) {
      return 'authpwd8';
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection')) {
      return 'autherrnet';
    }
    return 'autherrgen';
  }

  void _showAuthError(BuildContext context, String key) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(FFLocalizations.of(context).getText(key)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
