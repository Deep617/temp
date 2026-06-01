// To parse this JSON data, do
//
//     final uploadProfileRequest = uploadProfileRequestFromJson(jsonString);

import 'dart:convert';

UploadProfileRequest uploadProfileRequestFromJson(String str) => UploadProfileRequest.fromJson(json.decode(str));

String uploadProfileRequestToJson(UploadProfileRequest data) => json.encode(data.toJson());

class UploadProfileRequest {
  String? primaryActivity;
  String? experienceLevel;
  List<String>? goals;
  String? city;

  UploadProfileRequest({
    this.primaryActivity,
    this.experienceLevel,
    this.goals,
    this.city,
  });

  factory UploadProfileRequest.fromJson(Map<String, dynamic> json) => UploadProfileRequest(
    primaryActivity: json["primaryActivity"],
    experienceLevel: json["experienceLevel"],
    goals: json["goals"] == null ? [] : List<String>.from(json["goals"]!.map((x) => x)),
    city: json["city"],
  );

  Map<String, dynamic> toJson() => {
    "primaryActivity": primaryActivity,
    "experienceLevel": experienceLevel,
    "goals": goals == null ? [] : List<dynamic>.from(goals!.map((x) => x)),
    "city": city,
  };
}
