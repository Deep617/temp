// To parse this JSON data, do
//
//     final registerResponse = registerResponseFromJson(jsonString);

import 'dart:convert';

RegisterResponse registerResponseFromJson(String str) => RegisterResponse.fromJson(json.decode(str));

String registerResponseToJson(RegisterResponse data) => json.encode(data.toJson());

class RegisterResponse {
  User? user;
  String? accessToken;
  String? refreshToken;

  RegisterResponse({
    this.user,
    this.accessToken,
    this.refreshToken,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) => RegisterResponse(
    user: json["user"] == null ? null : User.fromJson(json["user"]),
    accessToken: json["accessToken"],
    refreshToken: json["refreshToken"],
  );

  Map<String, dynamic> toJson() => {
    "user": user?.toJson(),
    "accessToken": accessToken,
    "refreshToken": refreshToken,
  };
}

class User {
  String? id;
  String? email;
  String? firstName;
  String? lastName;
  dynamic username;
  dynamic avatarUrl;
  String? phone;
  dynamic bio;
  dynamic country;
  dynamic city;
  dynamic latitude;
  dynamic longitude;
  String? status;
  bool? emailVerified;
  bool? isBanned;
  int? loginCount;
  DateTime? lastLoginAt;
  DateTime? createdAt;
  dynamic primaryActivity;
  List<dynamic>? activities;
  dynamic experienceLevel;
  List<dynamic>? goals;
  dynamic primaryGym;
  int? xpTotal;
  int? level;
  int? chatTokens;
  int? trustScore;
  bool? idVerified;
  bool? isInfluencer;
  dynamic instagramHandle;
  dynamic instagramFollowers;
  String? subscriptionPlan;
  dynamic subscriptionExpiry;
  int? buddyCount;
  int? sessionCount;

  User({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.username,
    this.avatarUrl,
    this.phone,
    this.bio,
    this.country,
    this.city,
    this.latitude,
    this.longitude,
    this.status,
    this.emailVerified,
    this.isBanned,
    this.loginCount,
    this.lastLoginAt,
    this.createdAt,
    this.primaryActivity,
    this.activities,
    this.experienceLevel,
    this.goals,
    this.primaryGym,
    this.xpTotal,
    this.level,
    this.chatTokens,
    this.trustScore,
    this.idVerified,
    this.isInfluencer,
    this.instagramHandle,
    this.instagramFollowers,
    this.subscriptionPlan,
    this.subscriptionExpiry,
    this.buddyCount,
    this.sessionCount,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    email: json["email"],
    firstName: json["firstName"],
    lastName: json["lastName"],
    username: json["username"],
    avatarUrl: json["avatarUrl"],
    phone: json["phone"],
    bio: json["bio"],
    country: json["country"],
    city: json["city"],
    latitude: json["latitude"],
    longitude: json["longitude"],
    status: json["status"],
    emailVerified: json["emailVerified"],
    isBanned: json["isBanned"],
    loginCount: json["loginCount"],
    lastLoginAt: json["lastLoginAt"] == null ? null : DateTime.parse(json["lastLoginAt"]),
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    primaryActivity: json["primaryActivity"],
    activities: json["activities"] == null ? [] : List<dynamic>.from(json["activities"]!.map((x) => x)),
    experienceLevel: json["experienceLevel"],
    goals: json["goals"] == null ? [] : List<dynamic>.from(json["goals"]!.map((x) => x)),
    primaryGym: json["primaryGym"],
    xpTotal: json["xpTotal"],
    level: json["level"],
    chatTokens: json["chatTokens"],
    trustScore: json["trustScore"],
    idVerified: json["idVerified"],
    isInfluencer: json["isInfluencer"],
    instagramHandle: json["instagramHandle"],
    instagramFollowers: json["instagramFollowers"],
    subscriptionPlan: json["subscriptionPlan"],
    subscriptionExpiry: json["subscriptionExpiry"],
    buddyCount: json["buddyCount"],
    sessionCount: json["sessionCount"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "email": email,
    "firstName": firstName,
    "lastName": lastName,
    "username": username,
    "avatarUrl": avatarUrl,
    "phone": phone,
    "bio": bio,
    "country": country,
    "city": city,
    "latitude": latitude,
    "longitude": longitude,
    "status": status,
    "emailVerified": emailVerified,
    "isBanned": isBanned,
    "loginCount": loginCount,
    "lastLoginAt": lastLoginAt?.toIso8601String(),
    "createdAt": createdAt?.toIso8601String(),
    "primaryActivity": primaryActivity,
    "activities": activities == null ? [] : List<dynamic>.from(activities!.map((x) => x)),
    "experienceLevel": experienceLevel,
    "goals": goals == null ? [] : List<dynamic>.from(goals!.map((x) => x)),
    "primaryGym": primaryGym,
    "xpTotal": xpTotal,
    "level": level,
    "chatTokens": chatTokens,
    "trustScore": trustScore,
    "idVerified": idVerified,
    "isInfluencer": isInfluencer,
    "instagramHandle": instagramHandle,
    "instagramFollowers": instagramFollowers,
    "subscriptionPlan": subscriptionPlan,
    "subscriptionExpiry": subscriptionExpiry,
    "buddyCount": buddyCount,
    "sessionCount": sessionCount,
  };
}
