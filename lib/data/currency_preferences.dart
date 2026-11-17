import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_currency.dart';

class CurrencyPreferences {
  CurrencyPreferences._();

  static final CurrencyPreferences instance = CurrencyPreferences._();

  static const _currencyKey = 'currency_code';

  final _preferences = SharedPreferencesAsync();

  final ValueNotifier<AppCurrency> current = ValueNotifier(AppCurrency.myr);

  Future<void> load() async {
    final savedCode = await _preferences.getString(_currencyKey);
    current.value = AppCurrency.fromCode(savedCode);
  }

  Future<void> save(AppCurrency currency) async {
    await _preferences.setString(_currencyKey, currency.code);
    current.value = currency;
  }
}
