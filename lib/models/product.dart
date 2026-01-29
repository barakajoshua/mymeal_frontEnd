import 'package:mymeal/models/menu_item.dart' as model;

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> images;
  final String category;
  final double rating;
  final List<String> sauces;
  final List<String> toppings;
  final String? chefName;
  final String? chefSpecialty;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    required this.category,
    this.rating = 4.5,
    List<String>? sauces,
    List<String>? toppings,
    this.chefName,
    this.chefSpecialty,
  }) : this.sauces = sauces ?? const ['Teriyaki', 'Yakiniku'],
       this.toppings = toppings ?? const ['Cheese', 'Egg'];

  factory Product.fromMenuItem(model.MenuItem item) {
    final List<String> imgs = [];
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) imgs.add(item.imageUrl!);
    if (item.imageUrl2 != null && item.imageUrl2!.isNotEmpty) imgs.add(item.imageUrl2!);
    if (item.imageUrl3 != null && item.imageUrl3!.isNotEmpty) imgs.add(item.imageUrl3!);
    if (item.imageUrl4 != null && item.imageUrl4!.isNotEmpty) imgs.add(item.imageUrl4!);
    if (item.imageUrl5 != null && item.imageUrl5!.isNotEmpty) imgs.add(item.imageUrl5!);
    if (imgs.isEmpty) imgs.add("https://via.placeholder.com/150");

    return Product(
      id: item.id.toString(),
      name: item.name,
      description: item.description,
      price: item.price,
      images: List<String>.from(imgs),
      category: item.category?.name ?? 'All',
      chefName: item.chef?.displayName,
      chefSpecialty: item.chef?.specialty,
      sauces: const ['Teriyaki', 'Yakiniku'],
      toppings: const ['Cheese', 'Egg'],
    );
  }

  String get imageUrl => images.isNotEmpty ? images.first : "https://via.placeholder.com/150";
}
