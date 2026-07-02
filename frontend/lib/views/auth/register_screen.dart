import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socket_provider.dart';
import '../../core/constants/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _avatarUrlCtrl = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _avatarUrlCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final socketProvider = Provider.of<SocketProvider>(context, listen: false);

    // If avatar URL is empty, generate a cool Dicebear avatar
    final avatar = _avatarUrlCtrl.text.trim().isNotEmpty
        ? _avatarUrlCtrl.text.trim()
        : 'https://api.dicebear.com/7.x/adventurer/png?seed=${_usernameCtrl.text.trim()}';

    final success = await authProvider.register(
      _usernameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
      avatarUrl: avatar,
    );

    if (success && mounted) {
      // Connect socket on successful registration
      final user = authProvider.currentUser!;
      socketProvider.connectSocket(user.id, user.username);
      
      // Go back to login screen or pop (AuthProvider state redirects automatically)
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join ChatApp',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Register to start sharing real-time text and images',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 36),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Username Input
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter username';
                        }
                        if (val.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Email Input
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter email';
                        }
                        final emailRegex = RegExp(
                            r'^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$');
                        if (!emailRegex.hasMatch(val.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Password Input
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter password';
                        }
                        if (val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Avatar URL Input (Optional)
                    TextFormField(
                      controller: _avatarUrlCtrl,
                      decoration: InputDecoration(
                        labelText: 'Avatar Image URL (Optional)',
                        prefixIcon: const Icon(Icons.image_outlined),
                        helperText: 'Leave empty for an automatically generated avatar',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Register Button
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColorLight,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                        ),
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
