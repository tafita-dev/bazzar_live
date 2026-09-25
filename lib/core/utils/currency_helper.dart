String formatPrice(dynamic amount) {
  if (amount == null) return '0 Ar';
  final num val = num.tryParse(amount.toString()) ?? 0;
  
  final String str = val.toInt().toString();
  final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  final String formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]} ');
  return '$formatted MGA';
}
