/// A journal entry template (system or user-created).
class TemplateModel {
  const TemplateModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.structure,
    this.isSystem = false,
    this.createdBy,
    this.usageCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final String category;
  /// Map with "title" and "content" for pre-filling the entry.
  final Map<String, dynamic> structure;
  final bool isSystem;
  final String? createdBy;
  final int usageCount;

  String get titlePlaceholder => structure['title'] is String ? structure['title'] as String : '';
  String get contentPlaceholder => structure['content'] is String ? structure['content'] as String : '';

  /// Built-in example template so users can try templates without creating one.
  static const TemplateModel example = TemplateModel(
    id: 'example-quick-reflection',
    name: 'Example: Quick reflection',
    description: 'Try this template to see how it works',
    category: 'example',
    structure: {
      'title': 'Quick reflection',
      'content': 'Today in one word: \n\nWhat went well:\n\nWhat I\'d do differently:\n',
    },
    isSystem: false,
    createdBy: null,
    usageCount: 0,
  );

  static TemplateModel? fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id']?.toString();
    final name = json['name']?.toString();
    final category = json['category']?.toString();
    if (id == null || name == null || category == null) return null;
    final structure = json['structure'];
    final Map<String, dynamic> structureMap = structure is Map
        ? Map<String, dynamic>.from(structure as Map)
        : <String, dynamic>{'title': '', 'content': ''};
    return TemplateModel(
      id: id,
      name: name,
      description: json['description']?.toString(),
      category: category,
      structure: structureMap,
      isSystem: json['is_system'] == true,
      createdBy: json['created_by']?.toString(),
      usageCount: (json['usage_count'] is int) ? json['usage_count'] as int : 0,
    );
  }
}
