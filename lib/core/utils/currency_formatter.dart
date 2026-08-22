class CurrencyFormatter {
  static String format(int amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)} Lakh';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return '₹$amount';
  }

  static String formatExact(int amount) {
    final str = amount.toString();
    if (str.length <= 3) return '₹$str';
    String lastThree = str.substring(str.length - 3);
    String remaining = str.substring(0, str.length - 3);
    String formatted = '';
    while (remaining.length > 2) {
      formatted = ',${remaining.substring(remaining.length - 2)}$formatted';
      remaining = remaining.substring(0, remaining.length - 2);
    }
    return '₹$remaining$formatted,$lastThree';
  }
}
