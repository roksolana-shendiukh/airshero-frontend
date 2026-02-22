enum Class {
  any(id: 0, label: 'Any'),
  economy(id: 1, label: 'Economy'),
  premiumEconomy(id: 2, label: 'Premium Economy'),
  business(id: 3, label: 'Business'),
  first(id: 4, label: 'First');

  const Class({required this.id, required this.label});

  final int id;
  final String label;

  static Class fromId(int id) =>
      Class.values.firstWhere((c) => c.id == id);

  static Class fromLabel(String label) =>
      Class.values.firstWhere((c) => c.label == label);
}