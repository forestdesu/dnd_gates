extension PriceFormatting on int {
  String get asPrice {
    if (this <= 0) return 'Бесплатно';
    if (this % 100 == 0) return '${this ~/ 100} зол.';
    if (this % 10 == 0) return '${this ~/ 10} серебр.';
    return '$this мед.';
  }
}