import "package:intl/intl.dart";

class CurrencyInfo{
  Map<String, List<dynamic>> currencyFormat = {
    "KRW": [NumberFormat.currency(symbol: "₩", decimalDigits: 0), 0],
    "YEN": [NumberFormat.currency(symbol: "¥", decimalDigits: 0), 0],
    "EURO": [NumberFormat.currency(symbol: "€", decimalDigits: 0), 0],
    "POUND": [NumberFormat.currency(symbol: "£", decimalDigits: 0), 0],
    "YUAN": [NumberFormat.currency(symbol: "¥", decimalDigits: 1), 1],
    "USD": [NumberFormat.currency(symbol: "\$", decimalDigits: 2), 2],
    "CAD": [NumberFormat.currency(symbol: "CAD", name: "CAD", decimalDigits: 2), 2],
  };

  currencyList(){
    return currencyFormat.keys;
  }

  getCurrencyText(String currency, num amount){
    return currencyFormat[currency][0].format(amount);
  }

  getCurrencyDecimalPlaces(String currency){
    return currencyFormat[currency][1];
  }
}