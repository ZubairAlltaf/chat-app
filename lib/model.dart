import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants.dart';

class Profile {
  final String id; // Ensure this is String
  final String username;

  Profile({required this.id, required this.username});

  factory Profile.fromMap(Map<String, dynamic> data) {
    return Profile(
      id: data['id'].toString(), // Ensure it is String
      username: data['username'] ?? 'Unknown',
    );
  }
}







class Message {
  final String id;
  final String profileId;
  final String content;
  final String conversationId;
  final bool isRead;
  final bool deleted; // ✅ Add this field
  final DateTime createdAt;

  Message({
    required this.id,
    required this.profileId,
    required this.content,
    required this.conversationId,
    required this.isRead,
    required this.deleted, // ✅ Initialize it
    required this.createdAt,
  });

  /// Convert from Supabase Map
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      profileId: map['profile_id'],
      content: map['content'],
      conversationId: map['conversation_id'],
      isRead: map['is_read'] ?? false,
      deleted: map['deleted'] ?? false, // ✅ Ensure default false
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Copy method to edit messages
  Message copyWith({
    String? content,
    bool? isRead,
    bool? deleted,
  }) {
    return Message(
      id: id,
      profileId: profileId,
      content: content ?? this.content,
      conversationId: conversationId,
      isRead: isRead ?? this.isRead,
      deleted: deleted ?? this.deleted, // ✅ Allow update
      createdAt: createdAt,
    );
  }
}
