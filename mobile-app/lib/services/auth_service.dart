import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService with ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<String?> signUp(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await supabase.auth.signUp(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return null; // No error
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'An unexpected error occurred';
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return null; // No error
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'An unexpected error occurred';
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    notifyListeners();
  }

  User? get currentUser => supabase.auth.currentUser;
}
