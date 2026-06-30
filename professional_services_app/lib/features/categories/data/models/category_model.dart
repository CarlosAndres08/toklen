class CategoryModel {
  const CategoryModel({
    this.id,
    this.name,
    this.description,
  });

  final String? id;
  final String? name;
  final String? description;

  factory CategoryModel.fromJson(Map<String, dynamic>? json) {
    final Map<String, dynamic> data = json ?? <String, dynamic>{};
    
    return CategoryModel(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null && id!.isNotEmpty) 'id': id,
      'name': name ?? '',
      'description': description ?? '',
    };
  }
}