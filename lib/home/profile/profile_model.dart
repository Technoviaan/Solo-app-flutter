class ProfileModel {
  final String name;
  final String email;
  final String phone;
  final String? gender;
  final int? age;
  final String? profileImage;

  ProfileModel({
    required this.name,
    required this.email,
    required this.phone,
    this.gender,
    this.age,
    this.profileImage,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json["name"] ?? "",
      email: json["email"] ?? "",
      phone: json["phone"] ?? "",
      gender: json["gender"],
      age: json["age"],
      profileImage: json["profileImage"],
    );
  }
}