class BadgeModel {
  const BadgeModel({this.id, this.name, this.iconUrl});

  final String? id;
  final String? name;
  final String? iconUrl;

  factory BadgeModel.fromJson(Map<String, dynamic>? json) {
    final Map<String, dynamic> data = json ?? <String, dynamic>{};

    return BadgeModel(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      iconUrl: data['icon_url']?.toString() ?? '',
    );
  }
}
