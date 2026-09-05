import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [MuseColors.sky, MuseColors.cream, MuseColors.lavender],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '☁️',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 58),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isSignUp
                                ? 'Bắt đầu cùng MuseMend'
                                : 'Chào bạn trở lại',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Một khoảng nhỏ để lắng nghe và chữa lành mỗi ngày.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _displayNameController,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              decoration: const InputDecoration(
                                labelText: 'Tên hiển thị',
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
                              suffixIcon: IconButton(
                                onPressed:
                                    () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
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
                                      ),
                                    )
                                    : Text(
                                      _isSignUp ? 'Tạo tài khoản' : 'Đăng nhập',
                                    ),
                          ),
                          TextButton(
                            onPressed:
                                operation.isLoading
                                    ? null
                                    : () =>
                                        setState(() => _isSignUp = !_isSignUp),
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
        ),
      ),
    );
  }
}
