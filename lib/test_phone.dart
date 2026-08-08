import 'package:intl_phone_number_input/intl_phone_number_input.dart';

void main() async {
  try {
    PhoneNumber number = await PhoneNumber.getRegionInfoFromPhoneNumber('+919876543210');
    print('DialCode: ${number.dialCode}');
    print('IsoCode: ${number.isoCode}');
  } catch (e) {
    print('Error: $e');
  }
}
