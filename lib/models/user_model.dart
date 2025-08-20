class MMUser {
  final String id;
  final String displayName;
  final String email;
  final String role;
  final bool verified;
  final Map<String, dynamic>? emergencyContact;

  MMUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.verified,
    this.emergencyContact,
  });

  factory MMUser.fromMap(String id, Map<String, dynamic> data) {
    return MMUser(
      id: id,
      displayName: (data['displayName'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      role: (data['role'] ?? '') as String,
      verified: data['verified'] == true,
      emergencyContact: data['emergencyContact'] as Map<String, dynamic>?,
    );
  }
}
