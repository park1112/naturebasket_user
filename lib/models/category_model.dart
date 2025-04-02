// lib/models/category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? iconUrl;
  final bool isActive;
  final int order;
  final List<String>? subCategories;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.iconUrl,
    this.isActive = true,
    this.order = 0,
    this.subCategories,
  });

  // Firestore에서 데이터 로드
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      iconUrl: data['iconUrl'],
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      subCategories: data['subCategories'] != null
          ? List<String>.from(data['subCategories'])
          : null,
    );
  }

  // Firestore에 저장하기 위한 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'iconUrl': iconUrl,
      'isActive': isActive,
      'order': order,
      'subCategories': subCategories,
    };
  }

  // JSON 직렬화 (SharedPreferences 저장용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'iconUrl': iconUrl,
      'isActive': isActive,
      'order': order,
      'subCategories': subCategories,
    };
  }

  // JSON 역직렬화 (SharedPreferences에서 로드)
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      iconUrl: json['iconUrl'],
      isActive: json['isActive'],
      order: json['order'],
      subCategories: json['subCategories'] != null
          ? List<String>.from(json['subCategories'])
          : null,
    );
  }

  // 카테고리 복사 및 필드 업데이트
  CategoryModel copyWith({
    String? name,
    String? description,
    String? imageUrl,
    String? iconUrl,
    bool? isActive,
    int? order,
    List<String>? subCategories,
  }) {
    return CategoryModel(
      id: this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      subCategories: subCategories ?? this.subCategories,
    );
  }
}
