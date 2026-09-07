import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/presentation/auth_error_message.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isSignUp = false;
  var _obscurePassword = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    final succeeded =
        _isSignUp
            ? await controller.signUp(
              displayName: _displayNameController.text,
              email: _emailController.text,
              password: _passwordController.text,
            )
            : await controller.signIn(
              email: _emailController.text,
              password: _passwordController.text,
            );
    if (!mounted || !succeeded || !_isSignUp) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã tạo tài khoản. Hãy kiểm tra email nếu cần xác nhận.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final operation = ref.watch(authControllerProvider);
    return Scaffold(
      body: MusePageBackground(
        accent: MuseColors.sky,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: MuseGlassCard(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [MuseColors.teal, MuseColors.leaf],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22366672),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text('☁️', style: TextStyle(fontSize: 43)),
                      ),
                      const SizedBox(height: 16),
                      ShaderMask(
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              colors: [MuseColors.teal, MuseColors.leaf],
                            ).createShader(bounds),
                        child: const Text(
                          'MuseMend',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isSignUp
                            ? 'Bắt đầu một khoảng dịu dàng'
                            : 'Chào bạn trở lại',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Một khoảng nhỏ để lắng nghe và chữa lành mỗi ngày.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 22),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_isSignUp) ...[
                              TextFormField(
                                controller: _displayNameController,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                decoration: const InputDecoration(
                                  labelText: 'Tên hiển thị',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                                validator: (value) {
                                  final length = value?.trim().length ?? 0;
                                  if (length < 2 || length > 60) {
                                    return 'Tên cần từ 2 đến 60 ký tự.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (!RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(email)) {
                                  return 'Email chưa đúng định dạng.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted:
                                  (_) => operation.isLoading ? null : _submit(),
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _obscurePassword =
                                                !_obscurePassword,
                                      ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if ((value?.length ?? 0) < 8) {
                                  return 'Mật khẩu cần ít nhất 8 ký tự.';
                                }
                                return null;
                              },
                            ),
                            if (operation.hasError) ...[
                              const SizedBox(height: 12),
                              Text(
                                authErrorMessage(operation.error!),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: operation.isLoading ? null : _submit,
                              child:
                                  operation.isLoading
                                      ? const SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : Text(
                                        _isSignUp
                                            ? 'Tạo tài khoản'
                                            : 'Đăng nhập',
                                      ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed:
                            operation.isLoading
                                ? null
                                : () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(
                          _isSignUp
                              ? 'Đã có tài khoản? Đăng nhập'
                              : 'Chưa có tài khoản? Đăng ký',
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
    );
  }
}
