import 'package:classchat/auth/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'marketplace.dart';

class MarketplaceItem {
  final List<String> imageUrls; // Now supports multiple image URLs
  final String title;
  final String description;
  final String price;
  final String seller;
  final String sellerName;
  final int amount;
  final String id;
  final String category;
  MarketplaceItem({
    required this.imageUrls,
    required this.title,
    required this.description,
    required this.price,
    required this.seller,
    required this.sellerName,
    required this.amount,
    required this.id,
    required this.category,
  });

  factory MarketplaceItem.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MarketplaceItem(
      id: doc.id,
      imageUrls: List<String>.from(data['images'] ?? []),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] ?? 0,
      seller: data['userId'] ?? '',
      sellerName: data['userName'] ?? '',
      amount: data['amount'] ?? 0,
      category: data['category'] ?? '',
    );
  }
}