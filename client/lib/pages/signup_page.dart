/*
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName  = TextEditingController();
  final _password  = TextEditingController();
  final _confirm   = TextEditingController();
  final _age       = TextEditingController();
  final _job       = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _password.dispose();
    _confirm.dispose();
    _age.dispose();
    _job.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const paleRoyalBlue = Color(0xFF7E9BFF);
    const palePurple    = Color(0xFFD3B8FF);
    const palePink      = Color(0xFFFFD8F1);
    const deepIndigo    = Color(0xFF4B4FA7);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // schimbăm ordinea pentru alt „mix”
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [paleRoyalBlue, palePink, palePurple],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Create your account',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 18),

                          // First / Last name
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstName,
                                  decoration: const InputDecoration(
                                    labelText: 'First name',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                    (v==null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastName,
                                  decoration: const InputDecoration(
                                    labelText: 'Last name',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                    (v==null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Age & Occupation
                          Row(
                            children: [
                              SizedBox(
                                width: 120,
                                child: TextFormField(
                                  controller: _age,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Age',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    final n = int.tryParse(v);
                                    if (n == null || n <= 0) return 'Invalid';
                                    if (n < 13) return '13+ only';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _job,
                                  decoration: const InputDecoration(
                                    labelText: 'Occupation',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                    (v==null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure1,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure1 = !_obscure1),
                                icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility),
                              ),
                            ),
                            validator: (v) =>
                              (v==null || v.length<6) ? 'Min. 6 characters' : null,
                          ),
                          const SizedBox(height: 12),

                          // Confirm password
                          TextFormField(
                            controller: _confirm,
                            obscureText: _obscure2,
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure2 = !_obscure2),
                                icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility),
                              ),
                            ),
                            validator: (v) =>
                              (v != _password.text) ? 'Passwords do not match' : null,
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: deepIndigo,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // TODO: POST /auth/signup cu:
                                  // firstName, lastName, password, age, occupation
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Creating account (demo)...')),
                                  );
                                }
                              },
                              child: const Text('Create account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
*/

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart'; // are baza: 10.0.2.2 pe Android

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  // CONTROLLERS
  final firstNameController = TextEditingController();
  final lastNameController  = TextEditingController();
  final ageController       = TextEditingController();
  final occupationController= TextEditingController();
  final emailController     = TextEditingController();
  final passwordController  = TextEditingController();
  final confirmController   = TextEditingController();

  bool _obscure1 = true, _obscure2 = true;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    occupationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  // ✅ ACUM e metodă pe State — are acces la context, mounted și controllere
  Future<void> createAccount() async {
    final uri = Uri.parse('${Api.base}/api/auth/register');

    final body = {
      'firstName': firstNameController.text.trim(),
      'lastName' : lastNameController.text.trim(),
      'age'      : int.tryParse(ageController.text.trim()) ?? 0,
      'occupation': occupationController.text.trim(),
      'email'    : emailController.text.trim(),
      'password' : passwordController.text,
    };

    try {
      final res = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));

      debugPrint('REGISTER status: ${res.statusCode}');
      debugPrint('REGISTER body  : ${res.body}');

      if (!mounted) return;
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Account created!')));
        // TODO: Navigator.pushReplacement(... LoginPage())
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Register failed: ${res.statusCode} ${res.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Create your account',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),

                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First name', border: OutlineInputBorder()),
                          validator: (v) => (v==null||v.trim().isEmpty)?'Required':null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last name', border: OutlineInputBorder()),
                          validator: (v) => (v==null||v.trim().isEmpty)?'Required':null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    Row(children: [
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age', border: OutlineInputBorder()),
                          validator: (v) =>
                              (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Invalid',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: occupationController,
                          decoration: const InputDecoration(
                            labelText: 'Occupation', border: OutlineInputBorder()),
                          validator: (v) => (v==null||v.trim().isEmpty)?'Required':null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email', border: OutlineInputBorder()),
                      validator: (v) =>
                          (v!=null && v.contains('@')) ? null : 'Invalid email',
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscure1,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure1 = !_obscure1),
                          icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (v) => (v!=null && v.length>=6) ? null : 'Min. 6 chars',
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: confirmController,
                      obscureText: _obscure2,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                          icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (v) =>
                          v == passwordController.text ? null : 'Passwords do not match',
                    ),
                    const SizedBox(height: 16),

                    FilledButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          createAccount(); // 🔔 apelează metoda de mai sus
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Create account'),
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
  }
}
