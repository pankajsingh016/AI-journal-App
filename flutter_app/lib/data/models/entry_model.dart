class EntryModel {
  const EntryModel({
    required this.id,
    required this.userId,
    this.title,
    required this.content,
    this.mood,
    this.moodIntensity,
    required this.entryDate,
    required this.entryTime,
    this.wordCount = 0,
    this.characterCount = 0,
    this.isDraft = false,
    this.isFavorite = false,
    this.weather,
    this.location,
    this.templateId,
    this.createdAt,
    this.updatedAt,
    this.tags,
  });
  final String id;
  final String userId;
  final String? title;
  final String content;
  final String? mood;
  final int? moodIntensity;
  final String entryDate;
  final String entryTime;
  final int wordCount;
  final int characterCount;
  final bool isDraft;
  final bool isFavorite;
  final Map<String, dynamic>? weather;
  final String? location;
  final String? templateId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? tags;

  factory EntryModel.fromJson(Map<String, dynamic> json) {
    return EntryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
      mood: json['mood'] as String?,
      moodIntensity: json['mood_intensity'] as int?,
      entryDate: json['entry_date'] as String? ?? '',
      entryTime: json['entry_time'] as String? ?? '00:00:00',
      wordCount: json['word_count'] as int? ?? 0,
      characterCount: json['character_count'] as int? ?? 0,
      isDraft: json['is_draft'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
      weather: json['weather'] as Map<String, dynamic>?,
      location: json['location'] as String?,
      templateId: json['template_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'mood': mood,
        'mood_intensity': moodIntensity,
        'entry_date': entryDate,
        'entry_time': entryTime,
        'is_draft': isDraft,
        'is_favorite': isFavorite,
        'weather': weather,
        'location': location,
        'template_id': templateId,
        'tags': tags,
      };
}
