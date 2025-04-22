class TrafficSign {
  final String code;
  final String name;
  final String description;
  final String imageUrl;
  final SignType type;

  const TrafficSign({
    required this.code,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.type,
  });
}

enum SignType {
  prohibitory,
  warning,
  mandatory,
  information,
  direction,
  temporary
}
