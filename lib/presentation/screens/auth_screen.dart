// lib/presentation/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_planner_app/presentation/providers/meal_planner_notifier.dart';
import 'package:meal_planner_app/presentation/screens/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _username = '';
  bool _isLogin = true;

  // NEW: A separate state to hold any temporary error, independent of the notifier.
  String? _localError;

  // --- UPDATED SUBMISSION LOGIC ---
  void _submitAuthForm(MealPlannerNotifier notifier) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    // Clear any previous error before submitting
    setState(() {
      _localError = null;
      notifier.clearError(); // Clear Notifier error
    });

    try {
      if (_isLogin) {
        // LOGIN
        await notifier.signIn(email: _email, password: _password);
      } else {
        // SIGN UP
        await notifier.signUp(
          email: _email,
          password: _password,
          username: _username,
        );
      }

      // CRITICAL CHANGE: We don't check 'isLoggedIn' here.
      // We rely on the AuthState listener in the Notifier to update the state.

      // If the Notifier is no longer loading AND there is no error,
      // we can assume the listener successfully handled navigation in the background.
    } catch (e) {
      // Catch network/other non-Firebase Auth exceptions
      setState(() {
        _localError = 'Failed to communicate with the server.';
      });
    }
  }

  // --- BUILD METHOD REMAINS THE SAME, BUT WE ADD A LISTENER ---
  @override
  Widget build(BuildContext context) {
    // We use consumer here to listen to state changes AND access the provider
    return Consumer<MealPlannerNotifier>(
      builder: (context, notifier, child) {
        // Auto-navigate if the user state changes to logged in
        if (notifier.isLoggedIn) {
          // This check ensures that if the state updates to logged in, we push immediately.
          // This handles the async nature of the Firebase listener.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          });
          // While we wait for navigation, show a minimal loading state
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If not logged in, show the Auth Form
        return Scaffold(
          backgroundColor: Colors.teal.shade50,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _isLogin ? 'Welcome Back!' : 'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Username Input (Only for Sign Up)
                        if (!_isLogin)
                          TextFormField(
                            key: const ValueKey('username'),
                            decoration: const InputDecoration(
                              labelText: 'Username',
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.length < 4) {
                                return 'Please enter at least 4 characters.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _username = value!;
                            },
                          ),

                        // Email Input
                        TextFormField(
                          key: const ValueKey('email'),
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return 'Please enter a valid email address.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _email = value!;
                          },
                        ),

                        // Password Input
                        TextFormField(
                          key: const ValueKey('password'),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.length < 7) {
                              return 'Password must be at least 7 characters long.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _password = value!;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Error Message (Display Notifier error OR local error)
                        if ((notifier.errorMessage != null ||
                                _localError != null) &&
                            !notifier.isLoading)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              notifier.errorMessage ?? _localError ?? '',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Submit Button
                        if (notifier.isLoading)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton(
                            onPressed: () => _submitAuthForm(notifier),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade500,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              _isLogin ? 'Login' : 'Sign Up',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),

                        // Switch Mode Button
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              notifier.clearError();
                              _localError = null;
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'Need an account? Sign Up'
                                : 'Already have an account? Login',
                            style: TextStyle(color: Colors.teal.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
