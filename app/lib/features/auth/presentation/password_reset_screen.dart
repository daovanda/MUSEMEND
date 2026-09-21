import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/app/theme/muse_theme.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/presentation/auth_error_message.dart';
import 'package:musemend/features/auth/presentation/auth_input_decoration_theme.dart';
import 'package:musemend/features/auth/presentation/auth_otp_resend_button.dart';
import 'package:musemend/features/auth/presentation/auth_web_notice.dart';
import 'package:musemend/features/auth/domain/auth_callback_token.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({this.callbackUri, this.initialEmail, super.key});

  final Uri? callbackUri;
  final String? initialEmail;

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  var _obscurePassword = true;
  var _obscureConfirmation = true;
  var _completed = false;
  var _isVerifyingRecovery = false;
  var _hasOtpError = false;
  var _resendFailed = false;
  bool? _recoveryTokenVerified;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail?.trim() ?? '';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recoveryTokenVerified != true) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = ref.read(authControllerProvider.notifier);
    final updated = await controller.updatePassword(
      password: _passwordController.text,
    );
    if (!mounted || !updated) return;

    await controller.signOut();
    if (!mounted) return;
    if (ref.read(publicAuthPortalModeProvider)) {
      setState(() => _completed = true);
      return;
    }
    context.go('/sign-in?reset=success');
  }

  Future<void> _verifyRecovery(AuthCallbackToken token) async {
    setState(() => _isVerifyingRecovery = true);
    final verified = await ref
        .read(authControllerProvider.notifier)
        .verifyPasswordRecovery(tokenHash: token.hash);
    if (!mounted) return;
    setState(() {
      _isVerifyingRecovery = false;
      _recoveryTokenVerified = verified;
    });
    if (verified) context.replace('/reset-password');
  }

  Future<void> _verifyRecoveryOtp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isVerifyingRecovery = true;
      _hasOtpError = false;
      _resendFailed = false;
    });
    final verified = await ref
        .read(authControllerProvider.notifier)
        .verifyPasswordRecoveryOtp(
          email: _emailController.text,
          otp: _otpController.text,
        );
    if (!mounted) return;
    setState(() {
      _isVerifyingRecovery = false;
      _recoveryTokenVerified = verified;
      _hasOtpError = !verified;
    });
  }

  Future<bool> _resendRecoveryOtp() async {
    if (!(_emailFieldKey.currentState?.validate() ?? false)) return false;
    setState(() {
      _resendFailed = false;
      _hasOtpError = false;
    });
    final resent = await ref
        .read(authControllerProvider.notifier)
        .resendPasswordRecoveryOtp(email: _emailController.text);
    if (!mounted) return false;
    setState(() => _resendFailed = !resent);
    return resent;
  }

  void _returnToSignIn() {
    FocusManager.instance.primaryFocus?.unfocus();
    context.go('/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final operation = ref.watch(authControllerProvider);
    final publicPortal = ref.watch(publicAuthPortalModeProvider);
    if (!publicPortal && _recoveryTokenVerified != true) {
      return Theme(
        data: buildMuseTheme(),
        child: _buildOtpForm(context, strings),
      );
    }
    final callback = AuthCallbackToken.fromUri(widget.callbackUri ?? Uri.base);
    if (callback?.type == AuthCallbackType.recovery &&
        _recoveryTokenVerified == null) {
      return AuthWebNotice(
        title: strings.authResetPasswordTitle,
        body: strings.authCreateNewPasswordSubtitle,
        icon: Icons.lock_reset_rounded,
        actionLabel: strings.authUpdatePassword,
        onAction: () => _verifyRecovery(callback!),
        isLoading: _isVerifyingRecovery,
      );
    }
    if (callback?.type == AuthCallbackType.recovery &&
        _recoveryTokenVerified == false) {
      if (publicPortal) return _buildOtpForm(context, strings);
      return AuthWebNotice(
        title: strings.authLinkInvalidTitle,
        body: strings.authLinkInvalidBody,
        icon: Icons.link_off_rounded,
      );
    }
    return Theme(
      data: buildMuseTheme(),
      child:
          _completed && publicPortal
              ? AuthWebNotice(
                title: strings.authPasswordResetSuccessTitle,
                body: strings.authPasswordResetSuccess,
                icon: Icons.lock_reset_rounded,
              )
              : _recoveryTokenVerified == true
              ? _buildForm(context, strings, operation, publicPortal)
              : ref
                  .watch(authSessionProvider)
                  .when(
                    data: (value) {
                      if (value == null) {
                        return publicPortal
                            ? _buildOtpForm(context, strings)
                            : AuthWebNotice(
                              title: strings.authLinkInvalidTitle,
                              body: strings.authLinkInvalidBody,
                              icon: Icons.link_off_rounded,
                            );
                      }
                      return _buildForm(
                        context,
                        strings,
                        operation,
                        publicPortal,
                      );
                    },
                    error:
                        (_, _) => AuthWebNotice(
                          title: strings.authLinkInvalidTitle,
                          body: strings.authLinkInvalidBody,
                          icon: Icons.link_off_rounded,
                        ),
                    loading:
                        () => Scaffold(
                          backgroundColor: MuseColors.cream,
                          body: MusePageBackground(
                            accent: MuseColors.mint,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: MuseColors.teal,
                              ),
                            ),
                          ),
                        ),
                  ),
    );
  }

  Widget _buildOtpForm(BuildContext context, AppLocalizations strings) {
    return Scaffold(
      backgroundColor: MuseColors.cream,
      body: MusePageBackground(
        accent: MuseColors.mint,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: MuseGlassCard(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                  child: Theme(
                    data: buildAuthFormTheme(Theme.of(context)),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: MuseBrandMark(width: 82, height: 58),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            strings.authResetPasswordTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: MuseColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.authRecoveryOtpPrompt,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 22),
                          TextFormField(
                            key: _emailFieldKey,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: strings.email,
                              prefixIcon: const Icon(
                                Icons.alternate_email_rounded,
                              ),
                            ),
                            validator:
                                (value) =>
                                    RegExp(
                                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                        ).hasMatch(value?.trim() ?? '')
                                        ? null
                                        : strings.authEmailInvalid,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            maxLength: 6,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            decoration: InputDecoration(
                              labelText: strings.authOtpCode,
                              prefixIcon: const Icon(Icons.password_rounded),
                              counterText: '',
                            ),
                            validator:
                                (value) =>
                                    RegExp(
                                          r'^\d{6}$',
                                        ).hasMatch(value?.trim() ?? '')
                                        ? null
                                        : strings.authOtpInvalid,
                            onFieldSubmitted:
                                (_) =>
                                    _isVerifyingRecovery
                                        ? null
                                        : _verifyRecoveryOtp(),
                          ),
                          if (_hasOtpError) ...[
                            const SizedBox(height: 12),
                            Text(
                              strings.authOtpInvalid,
                              style: const TextStyle(color: Color(0xFF9A473D)),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed:
                                _isVerifyingRecovery
                                    ? null
                                    : _verifyRecoveryOtp,
                            child:
                                _isVerifyingRecovery
                                    ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(strings.authVerifyOtp),
                          ),
                          AuthOtpResendButton(
                            enabled: !_isVerifyingRecovery,
                            label: strings.authResendCode,
                            countdownLabel: strings.authResendCodeCountdown,
                            onResend: _resendRecoveryOtp,
                          ),
                          if (_resendFailed) ...[
                            const SizedBox(height: 4),
                            Text(
                              strings.authResendCodeFailed,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF9A473D)),
                            ),
                          ],
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

  Widget _buildForm(
    BuildContext context,
    AppLocalizations strings,
    AsyncValue<void> operation,
    bool publicPortal,
  ) {
    return Scaffold(
      backgroundColor: MuseColors.cream,
      body: MusePageBackground(
        accent: MuseColors.mint,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: MuseGlassCard(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                  child: Theme(
                    data: buildAuthFormTheme(Theme.of(context)),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: MuseBrandMark(width: 82, height: 58),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            strings.authResetPasswordTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: MuseColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.authCreateNewPasswordSubtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 22),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: strings.authNewPassword,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip:
                                    _obscurePassword
                                        ? strings.authShowPassword
                                        : strings.authHidePassword,
                                onPressed:
                                    () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value?.length ?? 0) < 8) {
                                return strings.authPasswordMinLength;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmationController,
                            obscureText: _obscureConfirmation,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted:
                                (_) => operation.isLoading ? null : _submit(),
                            decoration: InputDecoration(
                              labelText: strings.authConfirmPassword,
                              prefixIcon: const Icon(Icons.lock_reset_rounded),
                              suffixIcon: IconButton(
                                tooltip:
                                    _obscureConfirmation
                                        ? strings.authShowPassword
                                        : strings.authHidePassword,
                                onPressed:
                                    () => setState(
                                      () =>
                                          _obscureConfirmation =
                                              !_obscureConfirmation,
                                    ),
                                icon: Icon(
                                  _obscureConfirmation
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return strings.authPasswordMismatch;
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
                                authErrorMessage(strings, operation.error!),
                                style: const TextStyle(
                                  color: Color(0xFF9A473D),
                                ),
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
                                    : Text(strings.authUpdatePassword),
                          ),
                          if (!publicPortal) ...[
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed:
                                  operation.isLoading ? null : _returnToSignIn,
                              child: Text(strings.authBackToSignIn),
                            ),
                          ],
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
