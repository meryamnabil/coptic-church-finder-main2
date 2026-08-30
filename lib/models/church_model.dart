import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class Church {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String description;
  final String imageUrl;

  Church({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.imageUrl,
  });

  factory Church.fromJson(Map<String, dynamic> json) {
    return Church(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'],
      imageUrl: json['imageUrl'],
    );
  }

  factory Church.fromParse(ParseObject object) {
    return Church(
      id: object.objectId ?? '',
      name: object.get<String>('name') ?? '',
      address: object.get<String>('address') ?? '',
      latitude: (object.get<num>('latitude') ?? 0).toDouble(),
      longitude: (object.get<num>('longitude') ?? 0).toDouble(),
      description: object.get<String>('description') ?? '',
      imageUrl: object.get<String>('imageUrl') ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
