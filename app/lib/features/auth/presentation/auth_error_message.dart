import 'package:musemend/features/auth/domain/auth_failure.dart';

String authErrorMessage(Object error) {
  if (error is! AuthFailure) {
    return 'Không thể kết nối lúc này. Vui lòng thử lại.';
  }
  return switch (error.code) {
    AuthFailureCode.invalidCredentials => 'Email hoặc mật khẩu chưa đúng.',
    AuthFailureCode.emailAlreadyRegistered => 'Email này đã được đăng ký.',
    AuthFailureCode.emailNotConfirmed =>
      'Vui lòng xác nhận email trước khi đăng nhập.',
    AuthFailureCode.weakPassword => 'Mật khẩu chưa đáp ứng yêu cầu bảo mật.',
    AuthFailureCode.unknown => 'Không thể kết nối lúc này. Vui lòng thử lại.',
  };
}
