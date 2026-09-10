import 'dart:ui';

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

  void _toggleMode() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSignUp = !_isSignUp);
  }

  @override
  Widget build(BuildContext context) {
    final operation = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: MuseColors.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AuthBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 820;
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth < 360 ? 14 : 24,
                    wide ? 32 : 18,
                    constraints.maxWidth < 360 ? 14 : 24,
                    28,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (wide ? 60 : 34),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 980),
                        child:
                            wide
                                ? Row(
                                  children: [
                                    const Expanded(child: _WelcomePanel()),
                                    const SizedBox(width: 52),
                                    SizedBox(
                                      width: 430,
                                      child: _AuthCard(
                                        formKey: _formKey,
                                        isSignUp: _isSignUp,
                                        obscurePassword: _obscurePassword,
                                        operation: operation,
                                        displayNameController:
                                            _displayNameController,
                                        emailController: _emailController,
                                        passwordController: _passwordController,
                                        onSubmit: _submit,
                                        onToggleMode: _toggleMode,
                                        onTogglePassword:
                                            () => setState(
                                              () =>
                                                  _obscurePassword =
                                                      !_obscurePassword,
                                            ),
                                      ),
                                    ),
                                  ],
                                )
                                : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const _CompactBrand(),
                                    const SizedBox(height: 14),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 440,
                                      ),
                                      child: _AuthCard(
                                        formKey: _formKey,
                                        isSignUp: _isSignUp,
                                        obscurePassword: _obscurePassword,
                                        operation: operation,
                                        displayNameController:
                                            _displayNameController,
                                        emailController: _emailController,
                                        passwordController: _passwordController,
                                        onSubmit: _submit,
                                        onToggleMode: _toggleMode,
                                        onTogglePassword:
                                            () => setState(
                                              () =>
                                                  _obscurePassword =
                                                      !_obscurePassword,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackdrop extends StatefulWidget {
  const _AuthBackdrop();

  @override
  State<_AuthBackdrop> createState() => _AuthBackdropState();
}

class _AuthBackdropState extends State<_AuthBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _drift;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _drift = CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _drift,
            child: Image.asset(
              'assets/illustrations/journey/sky-background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              opacity: const AlwaysStoppedAnimation(.54),
            ),
            builder: (context, child) {
              return Transform.translate(
                key: const ValueKey('auth-sky-drift'),
                offset: Offset(-4 + (_drift.value * 8), -2 * _drift.value),
                child: Transform.scale(scale: 1.035, child: child),
              );
            },
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22E0F2F7),
                  Color(0xA8F5F7F2),
                  MuseColors.cream,
                  Color(0xFFF2ECFA),
                ],
                stops: [0, .42, .76, 1],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _drift,
            builder: (context, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: const Alignment(-1.08, -.74),
                    child: Transform.translate(
                      offset: Offset(12 * _drift.value, 4 * _drift.value),
                      child: const _PastelGlow(
                        color: Color(0xFFD8F1E2),
                        size: 230,
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(1.12, .82),
                    child: Transform.translate(
                      offset: Offset(-15 * _drift.value, -5 * _drift.value),
                      child: const _PastelGlow(
                        color: Color(0xFFE6D9FA),
                        size: 280,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PastelGlow extends StatelessWidget {
  const _PastelGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: .55),
        ),
      ),
    );
  }
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/illustrations/clouds/mascot-cloud.png',
          width: 116,
          height: 78,
          fit: BoxFit.contain,
          semanticLabel: 'Linh vật mây MuseMend',
        ),
        const SizedBox(height: 2),
        const _MuseMendWordmark(fontSize: 29),
      ],
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/illustrations/clouds/mascot-cloud.png',
            width: 190,
            height: 126,
            fit: BoxFit.contain,
            semanticLabel: 'Linh vật mây MuseMend',
          ),
          const SizedBox(height: 8),
          const _MuseMendWordmark(fontSize: 42),
          const SizedBox(height: 16),
          const Text(
            'Một khoảng trời riêng\ncho những ngày cần dịu lại.',
            style: TextStyle(
              color: MuseColors.ink,
              fontSize: 28,
              height: 1.25,
              fontWeight: FontWeight.w700,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ghi lại cảm xúc, hoàn thành những điều nhỏ bé và đi tiếp trên hành trình của riêng bạn.',
            style: TextStyle(
              color: MuseColors.ink.withValues(alpha: .72),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuseMendWordmark extends StatelessWidget {
  const _MuseMendWordmark({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback:
          (bounds) => const LinearGradient(
            colors: [Color(0xFF4D858D), Color(0xFF9BC27C)],
          ).createShader(bounds),
      child: Text(
        'MuseMend',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.formKey,
    required this.isSignUp,
    required this.obscurePassword,
    required this.operation,
    required this.displayNameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    required this.onToggleMode,
    required this.onTogglePassword,
  });

  final GlobalKey<FormState> formKey;
  final bool isSignUp;
  final bool obscurePassword;
  final AsyncValue<void> operation;
  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    final fieldDecoration = InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: .68),
      labelStyle: const TextStyle(color: MuseColors.mutedInk),
      prefixIconColor: MuseColors.teal,
      suffixIconColor: MuseColors.mutedInk,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: .86),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: MuseColors.leaf, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: MuseColors.coral),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: MuseColors.coral, width: 1.5),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 25, 24, 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7).withValues(alpha: .84),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: .9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18366672),
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              brightness: Brightness.light,
              inputDecorationTheme: fieldDecoration,
            ),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Column(
                    key: ValueKey(isSignUp),
                    children: [
                      Text(
                        isSignUp
                            ? 'Tạo khoảng trời của bạn'
                            : 'Chào bạn trở lại',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: MuseColors.ink,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.3,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        isSignUp
                            ? 'Bắt đầu bằng vài thông tin thật đơn giản.'
                            : 'Hôm nay mình cùng chậm lại một chút nhé.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: MuseColors.mutedInk,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child:
                            isSignUp
                                ? Column(
                                  children: [
                                    TextFormField(
                                      controller: displayNameController,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.name],
                                      style: const TextStyle(
                                        color: MuseColors.ink,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Tên hiển thị',
                                        prefixIcon: Icon(
                                          Icons.person_outline_rounded,
                                        ),
                                      ),
                                      validator: (value) {
                                        final length =
                                            value?.trim().length ?? 0;
                                        if (length < 2 || length > 60) {
                                          return 'Tên cần từ 2 đến 60 ký tự.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                )
                                : const SizedBox.shrink(),
                      ),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        style: const TextStyle(color: MuseColors.ink),
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
                        controller: passwordController,
                        obscureText: obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: [
                          isSignUp
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        autocorrect: false,
                        enableSuggestions: false,
                        style: const TextStyle(color: MuseColors.ink),
                        onFieldSubmitted:
                            (_) => operation.isLoading ? null : onSubmit(),
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip:
                                obscurePassword
                                    ? 'Hiện mật khẩu'
                                    : 'Ẩn mật khẩu',
                            onPressed: onTogglePassword,
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: MuseColors.coral.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            authErrorMessage(operation.error!),
                            style: const TextStyle(color: Color(0xFF9A473D)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: MuseColors.teal,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: MuseColors.teal.withValues(
                            alpha: .45,
                          ),
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: operation.isLoading ? null : onSubmit,
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
                                  isSignUp ? 'Tạo tài khoản' : 'Đăng nhập',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: MuseColors.teal,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: operation.isLoading ? null : onToggleMode,
                  child: Text(
                    isSignUp
                        ? 'Đã có tài khoản? Đăng nhập'
                        : 'Chưa có tài khoản? Đăng ký',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
