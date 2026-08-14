import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_api.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {

  AuthBloc() : super(AuthInitial()) {

    /// SEND OTP
    on<SendOtpEvent>((event, emit) async {

      emit(AuthLoading());

      try {

        await AuthApi.sendOtp(
          event.countryCode,
          event.phone,
        );

        emit(OtpSent());

      } catch (e) {
        emit(AuthError("Failed to send OTP"));
      }
    });

    /// VERIFY OTP
    on<VerifyOtpEvent>((event, emit) async {

      emit(AuthLoading());

      try {

        final data = await AuthApi.verifyOtp(
          event.countryCode,
          event.phone,
          event.otp,
        );

        /// EXTRACT DATA
        final token = data["token"];
        final onboarding = data["onboarding"];
        final user = data["user"];
        final subscription = user["subscription"];

        /// SAVE DATA IN PARALLEL
        await Future.wait([
          TokenStorage.saveToken(token),
          TokenStorage.saveNameCompleted(onboarding["nameCompleted"]),
          TokenStorage.saveEmailCompleted(onboarding["emailCompleted"]),
          TokenStorage.saveSubscriptionStatus(subscription["status"]),
          TokenStorage.saveCredits(subscription["credits"]["remaining"]),
          TokenStorage.saveMaxContacts(subscription["limits"]?["maxContacts"] ?? 5),
          TokenStorage.saveMaxCheckins(subscription["limits"]?["maxCheckins"] ?? 5),
          TokenStorage.saveLanguage(user["language"] ?? "en"),
        ]);

        emit(
          AuthVerified(
            nameCompleted: onboarding["nameCompleted"],
            emailCompleted: onboarding["emailCompleted"],
          ),
        );

      } catch (e) {
        // [BAN_GUARD] Previously always emitted a generic "OTP
        // verification failed" here, which swallowed AuthApi.verifyOtp's
        // real message — so a banned user just saw the same error as a
        // wrong OTP, with no idea why. Now the actual message (including
        // the "banned by admin" one) reaches the UI.
        final message = e.toString().replaceFirst("Exception: ", "");
        emit(AuthError(message.isNotEmpty ? message : "OTP verification failed"));
      }
    });
  }
}