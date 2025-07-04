class UserModel {
  final String id;
  String name;
  final String username;
  final String email;
  final DateTime? dob;
  String? phoneNumber;
  String? profilePicturePath;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.dob,
    this.phoneNumber,
    this.profilePicturePath,
    this.role = 'student', // Default new users to the 'student' role
  });
}
