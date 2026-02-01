import 'dart:typed_data';

class UserProfile {
  final String id;
  final DateTime dateOfBirth;
  final String petName;
  final String petType;
  final Uint8List? petImage;
  final EnergyDNA? energyDNA;
  final SoulID? soulID;

  UserProfile({
    String? id,
    required this.dateOfBirth,
    required this.petName,
    required this.petType,
    this.petImage,
    this.energyDNA,
    this.soulID,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'petName': petName,
        'petType': petType,
        'energyDNA': energyDNA?.toJson(),
        'soulID': soulID?.toJson(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        dateOfBirth: DateTime.parse(json['dateOfBirth']),
        petName: json['petName'],
        petType: json['petType'],
        energyDNA: json['energyDNA'] != null
            ? EnergyDNA.fromJson(json['energyDNA'])
            : null,
        soulID: json['soulID'] != null ? SoulID.fromJson(json['soulID']) : null,
      );
}

class EnergyDNA {
  final String type;
  final String description;
  final int colorHex;

  EnergyDNA({
    required this.type,
    required this.description,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
        'colorHex': colorHex,
      };

  factory EnergyDNA.fromJson(Map<String, dynamic> json) => EnergyDNA(
        type: json['type'],
        description: json['description'],
        colorHex: json['colorHex'],
      );
}

class SoulID {
  final String id;
  final String archetype;
  final String quote;

  SoulID({
    required this.id,
    required this.archetype,
    required this.quote,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'archetype': archetype,
        'quote': quote,
      };

  factory SoulID.fromJson(Map<String, dynamic> json) => SoulID(
        id: json['id'],
        archetype: json['archetype'],
        quote: json['quote'],
      );
}
