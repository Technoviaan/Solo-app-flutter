abstract class AuthEvent {}

class SendOtpEvent extends AuthEvent {
  final String countryCode;
  final String phone;

  SendOtpEvent(this.countryCode, this.phone);
}

class VerifyOtpEvent extends AuthEvent {
  final String countryCode;
  final String phone;
  final String otp;

  VerifyOtpEvent(this.countryCode, this.phone, this.otp);
}