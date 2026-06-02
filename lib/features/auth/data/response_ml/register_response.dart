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
  String? username;
  String? avatarUrl;
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
  int level;
  int? chatTokens;
  int trustScore;
  bool? idVerified;
  bool? isInfluencer;
  dynamic instagramHandle;
  dynamic instagramFollowers;
  String? subscriptionPlan;
  dynamic subscriptionExpiry;
  int? buddyCount;
  int? sessionCount;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.phone,
    this.username,
    this.bio,
    this.country,
    this.city,
    this.status = 'ACTIVE',
    this.emailVerified = false,
    this.isBanned = false,
    this.loginCount = 0,
    this.lastLoginAt,
    required this.createdAt,
    this.primaryActivity,
    this.activities = const [],
    this.experienceLevel,
    this.goals = const [],
    this.primaryGym,
    this.latitude,
    this.longitude,
    this.xpTotal = 0,
    this.level = 1,
    this.chatTokens = 20,
    this.isInfluencer = false,
    this.instagramHandle,
    this.instagramFollowers,
    this.trustScore = 50,
    this.idVerified = false,
    this.buddyCount = 0,
    this.sessionCount = 0,
    this.subscriptionPlan = 'free',
    this.subscriptionExpiry,
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

  String get fullName => '$firstName $lastName';
  String? get displayHandle => username != null ? '@$username' : email;
  bool get isPro     => subscriptionPlan == 'pro'   || subscriptionPlan == 'elite';
  bool get isElite   => subscriptionPlan == 'elite';
  bool get isActive  => subscriptionExpiry == null || subscriptionExpiry!.isAfter(DateTime.now());
  String get levelName {
    const names = ['Newbie','Rookie','Regular','Athlete','Pro','Elite','Champion','Legend','Icon','GOAT'];
    return level <= names.length ? names[level - 1] : 'Legend';
  }
}
