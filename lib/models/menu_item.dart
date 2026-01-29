class Category {
  final int id;
  final String name;
  final String? description;
  final int? sortOrder;
  final int? isActive;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder,
    this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] ?? 'Unknown',
      description: json['description'],
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? ''),
      isActive: int.tryParse(json['is_active']?.toString() ?? ''),
    );
  }
}

class Chef {
  final int id;
  final int userId;
  final String displayName;
  final String? specialty;
  final String? bio;
  final int? experienceYears;
  final int? isActive;

  Chef({
    required this.id,
    required this.userId,
    required this.displayName,
    this.specialty,
    this.bio,
    this.experienceYears,
    this.isActive,
  });

  factory Chef.fromJson(Map<String, dynamic> json) {
    return Chef(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      displayName: json['display_name'] ?? 'Unknown',
      specialty: json['specialty'],
      bio: json['bio'],
      experienceYears: int.tryParse(json['experience_years']?.toString() ?? ''),
      isActive: int.tryParse(json['is_active']?.toString() ?? ''),
    );
  }
}

class MenuItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String? imageUrl2;
  final String? imageUrl3;
  final String? imageUrl4;
  final String? imageUrl5;
  final int isAvailable;
  final String? availableDate;
  final Category? category;
  final Chef? chef;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.imageUrl2,
    this.imageUrl3,
    this.imageUrl4,
    this.imageUrl5,
    required this.isAvailable,
    this.availableDate,
    this.category,
    this.chef,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] ?? 'Unknown',
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url'],
      imageUrl2: json['image_url_2'],
      imageUrl3: json['image_url_3'],
      imageUrl4: json['image_url_4'],
      imageUrl5: json['image_url_5'],
      isAvailable: int.tryParse(json['is_available']?.toString() ?? '') ?? 0,
      availableDate: json['available_date'],
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      chef: json['chef'] != null ? Chef.fromJson(json['chef']) : null,
    );
  }

  String get displayImage => imageUrl2 ?? imageUrl ?? "https://via.placeholder.com/150";
}
