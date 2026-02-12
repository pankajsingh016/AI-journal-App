/// A single media item (image) attached to an entry.
class EntryMediaItem {
  const EntryMediaItem({
    required this.id,
    required this.url,
    this.fileName,
    this.mimeType,
  });
  final String id;
  final String url;
  final String? fileName;
  final String? mimeType;

  static EntryMediaItem? fromJson(dynamic json) {
    if (json is! Map) return null;
    final id = json['id']?.toString();
    final url = json['url']?.toString();
    if (id == null || url == null) return null;
    return EntryMediaItem(
      id: id,
      url: url,
      fileName: json['file_name']?.toString(),
      mimeType: json['mime_type']?.toString(),
    );
  }
}

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
    this.media,
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
  final List<EntryMediaItem>? media;

  factory EntryModel.fromJson(Map<String, dynamic> json) {
    String? _str(dynamic v) => v == null ? null : v.toString();
    String _strReq(dynamic v) => v?.toString() ?? '';
    return EntryModel(
      id: _strReq(json['id']),
      userId: _strReq(json['user_id']),
      title: _str(json['title']),
      content: _str(json['content']) ?? '',
      mood: _str(json['mood']),
      moodIntensity: json['mood_intensity'] is int ? json['mood_intensity'] as int : (json['mood_intensity'] != null ? int.tryParse(json['mood_intensity'].toString()) : null),
      entryDate: _str(json['entry_date']) ?? '',
      entryTime: _str(json['entry_time']) ?? '00:00:00',
      wordCount: (json['word_count'] is int) ? json['word_count'] as int : (int.tryParse(json['word_count']?.toString() ?? '') ?? 0),
      characterCount: (json['character_count'] is int) ? json['character_count'] as int : (int.tryParse(json['character_count']?.toString() ?? '') ?? 0),
      isDraft: json['is_draft'] == true,
      isFavorite: json['is_favorite'] == true,
      weather: json['weather'] is Map ? Map<String, dynamic>.from(json['weather'] as Map) : null,
      location: _str(json['location']),
      templateId: _str(json['template_id']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      tags: (json['tags'] is List) ? (json['tags'] as List).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList() : null,
      media: _parseMedia(json['media']),
    );
  }

  static List<EntryMediaItem>? _parseMedia(dynamic v) {
    if (v is! List || v.isEmpty) return null;
    final list = <EntryMediaItem>[];
    for (final e in v) {
      final map = e is Map ? Map<String, dynamic>.from(e as Map) : null;
      final item = map != null ? EntryMediaItem.fromJson(map) : null;
      if (item != null) list.add(item);
    }
    return list.isEmpty ? null : list;
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
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
