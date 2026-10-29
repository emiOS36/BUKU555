//turns sen into text eg 350000 -> RM 3500.00
String formatRM(int sen) {
  final sign = sen < 0 ? '-' : '';
  final abs = sen.abs();
  final ringgit = abs ~/ 100;
  final cents = (abs % 100).toString().padLeft(2, '0');
  final withCommas = ringgit.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '${sign}RM $withCommas.$cents';
}
