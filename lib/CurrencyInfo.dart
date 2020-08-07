import "package:intl/intl.dart";

class CurrencyInfo{
  Map<String, List<dynamic>> currencyFormat = {
    "KRW": [NumberFormat.currency(symbol: "₩", decimalDigits: 0), 0],
    "USD": [NumberFormat.currency(symbol: "\$", decimalDigits: 2), 2],
  };

  getCurrencyText(String currency, num amount){
    return currencyFormat[currency][0].format(amount);
  }

  getCurrencyDecimalPlaces(String currency){
    return currencyFormat[currency][1];
  }
}