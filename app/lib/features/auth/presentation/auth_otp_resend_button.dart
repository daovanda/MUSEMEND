import 'dart:async';

import 'package:flutter/material.dart';

/// A resend control with a local 60-second cooldown.
///
/// The server remains the source of truth; this timer only prevents accidental
/// repeated requests from the current screen.
class AuthOtpResendButton extends StatefulWidget {
  const AuthOtpResendButton({
    required this.enabled,
    required this.label,
    required this.countdownLabel,
    required this.onResend,
    super.key,
  });

  static const cooldown = Duration(seconds: 60);

  final bool enabled;
  final String label;
  final String Function(int seconds) countdownLabel;
  final Future<bool> Function() onResend;

  @override
  State<AuthOtpResendButton> createState() => _AuthOtpResendButtonState();
}

class _AuthOtpResendButtonState extends State<AuthOtpResendButton> {
  Timer? _timer;
  var _cooldownActive = true;
  var _isSending = false;
  var _secondsRemaining = AuthOtpResendButton.cooldown.inSeconds;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_isSending || _cooldownActive || !widget.enabled) return;
    setState(() => _isSending = true);
    final succeeded = await widget.onResend();
    if (!mounted) return;
    setState(() => _isSending = false);
    if (!succeeded) return;

    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    _cooldownActive = true;
    _secondsRemaining = AuthOtpResendButton.cooldown.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining -= 1);
        return;
      }
      timer.cancel();
      setState(() {
        _cooldownActive = false;
        _secondsRemaining = 0;
        _timer = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final canResend = widget.enabled && !_isSending && !_cooldownActive;
    final label =
        _isSending
            ? widget.label
            : _cooldownActive
            ? widget.countdownLabel(_secondsRemaining)
            : widget.label;

    return TextButton.icon(
      onPressed: canResend ? _resend : null,
      icon:
          _isSending
              ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.refresh_rounded, size: 18),
      label: Text(label),
    );
  }
}
