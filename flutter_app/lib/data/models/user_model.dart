class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.onboardingCompleted = false,
    this.journalingGoal,
    this.preferredJournalingTime,
    this.aiPersonality = 'supportive',
    this.createdAt,
    this.updatedAt,
  });
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final bool onboardingCompleted;
  final String? journalingGoal;
  final String? preferredJournalingTime;
  final String aiPersonality;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      journalingGoal: json['journaling_goal'] as String?,
      preferredJournalingTime: json['preferred_journaling_time'] as String?,
      aiPersonality: json['ai_personality'] as String? ?? 'supportive',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'onboarding_completed': onboardingCompleted,
        'journaling_goal': journalingGoal,
        'preferred_journaling_time': preferredJournalingTime,
        'ai_personality': aiPersonality,
      };
}
