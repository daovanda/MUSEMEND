import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/domain/auth_callback_token.dart';
import 'package:musemend/features/auth/presentation/auth_input_decoration_theme.dart';
import 'package:musemend/features/auth/presentation/auth_otp_resend_button.dart';
import 'package:musemend/features/auth/presentation/auth_web_notice.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

class EmailConfirmationScreen extends ConsumerStatefulWidget {
  const EmailConfirmationScreen({
    this.callbackUri,
    this.initialEmail,
    super.key,
  });

  final Uri? callbackUri;
  final String? initialEmail;

  @override
  ConsumerState<EmailConfirmationScreen> createState() =>
      _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState
    extends ConsumerState<EmailConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  var _isVerifying = false;
  var _hasOtpError = false;
  var _resendFailed = false;
  bool? _tokenVerified;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail?.trim() ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify(AuthCallbackToken token) async {
    setState(() => _isVerifying = true);
    final verified = await ref
        .read(authControllerProvider.notifier)
        .verifyEmailConfirmation(tokenHash: token.hash);
    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _tokenVerified = verified;
    });
    if (verified) context.replace('/email-confirmed');
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isVerifying = true;
      _hasOtpError = false;
      _resendFailed = false;
    });
    final verified = await ref
        .read(authControllerProvider.notifier)
        .verifyEmailOtp(email: _emailController.text, otp: _otpController.text);
    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _tokenVerified = verified;
      _hasOtpError = !verified;
    });
    if (verified && !ref.read(publicAuthPortalModeProvider)) {
      context.go('/onboarding');
    }
  }

  Future<bool> _resendOtp() async {
    if (!(_emailFieldKey.currentState?.validate() ?? false)) return false;
    setState(() {
      _resendFailed = false;
      _hasOtpError = false;
    });
    final resent = await ref
        .read(authControllerProvider.notifier)
        .resendEmailConfirmationOtp(email: _emailController.text);
    if (!mounted) return false;
    setState(() => _resendFailed = !resent);
    return resent;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final publicPortal = ref.watch(publicAuthPortalModeProvider);
    if (!publicPortal) return _buildOtpForm(context, strings);
    if (_tokenVerified == true) {
      return AuthWebNotice(
        title: strings.authEmailConfirmedTitle,
        body: strings.authEmailConfirmedBody,
        icon: Icons.mark_email_read_outlined,
      );
    }
    if (_tokenVerified == false) {
      if (publicPortal) return _buildOtpForm(context, strings);
      return AuthWebNotice(
        title: strings.authLinkInvalidTitle,
        body: strings.authLinkInvalidBody,
        icon: Icons.link_off_rounded,
      );
    }

    final callback = AuthCallbackToken.fromUri(widget.callbackUri ?? Uri.base);
    if (callback?.type == AuthCallbackType.email) {
      return AuthWebNotice(
        title: strings.authConfirmEmailTitle,
        body: strings.authConfirmEmailPrompt,
        icon: Icons.mark_email_read_outlined,
        actionLabel: strings.authConfirmEmailAction,
        onAction: () => _verify(callback!),
        isLoading: _isVerifying,
      );
    }

    final session = ref.watch(authSessionProvider);
    return session.when(
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
        return AuthWebNotice(
          title: strings.authEmailConfirmedTitle,
          body: strings.authEmailConfirmedBody,
          icon: Icons.mark_email_read_outlined,
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
                child: CircularProgressIndicator(color: MuseColors.teal),
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
                            strings.authConfirmEmailTitle,
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
                            strings.authEmailOtpPrompt,
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
                                (_) => _isVerifying ? null : _verifyOtp(),
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
                            onPressed: _isVerifying ? null : _verifyOtp,
                            child:
                                _isVerifying
                                    ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(strings.authConfirmEmailAction),
                          ),
                          AuthOtpResendButton(
                            enabled: !_isVerifying,
                            label: strings.authResendCode,
                            countdownLabel: strings.authResendCodeCountdown,
                            onResend: _resendOtp,
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
}
