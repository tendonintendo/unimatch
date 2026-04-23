// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, tutor }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? videoUrl;
  final String? cvPdfUrl;
  final String? idCardUrl;      // Uploaded during tutor registration
  final bool idVerified;        // Set by backend/admin after review
  final UserRole role;
  final GeoPoint? location;
  final String? bio;
  final List<String> subjects;  // e.g. ['Math', 'Physics']
  final double? hourlyRate;
  final String? fcmToken;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.videoUrl,
    this.cvPdfUrl,
    this.idCardUrl,
    this.idVerified = false,
    required this.role,
    this.location,
    this.bio,
    this.subjects = const [],
    this.hourlyRate,
    this.fcmToken,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      videoUrl: data['videoUrl'],
      cvPdfUrl: data['cvPdfUrl'],
      idCardUrl: data['idCardUrl'],
      idVerified: data['idVerified'] ?? false,
      role: data['role'] == 'tutor' ? UserRole.tutor : UserRole.student,
      location: data['location'] as GeoPoint?,
      bio: data['bio'],
      subjects: List<String>.from(data['subjects'] ?? []),
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble(),
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'videoUrl': videoUrl,
        'cvPdfUrl': cvPdfUrl,
        'idCardUrl': idCardUrl,
        'idVerified': idVerified,
        'role': role.name,
        'location': location,
        'bio': bio,
        'subjects': subjects,
        'hourlyRate': hourlyRate,
        'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? videoUrl,
    String? cvPdfUrl,
    String? idCardUrl,
    bool? idVerified,
    GeoPoint? location,
    String? bio,
    List<String>? subjects,
    double? hourlyRate,
    String? fcmToken,
  }) =>
      UserModel(
        uid: uid,
        name: name ?? this.name,
        email: email,
        photoUrl: photoUrl ?? this.photoUrl,
        videoUrl: videoUrl ?? this.videoUrl,
        cvPdfUrl: cvPdfUrl ?? this.cvPdfUrl,
        idCardUrl: idCardUrl ?? this.idCardUrl,
        idVerified: idVerified ?? this.idVerified,
        role: role,
        location: location ?? this.location,
        bio: bio ?? this.bio,
        subjects: subjects ?? this.subjects,
        hourlyRate: hourlyRate ?? this.hourlyRate,
        fcmToken: fcmToken ?? this.fcmToken,
        createdAt: createdAt,
      );
}
