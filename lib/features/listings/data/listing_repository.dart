import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:max_food/core/providers/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryOption {
  const CategoryOption({required this.id, required this.name});

  final String id;
  final String name;
}

class ListingItem {
  const ListingItem({
    required this.listingId,
    required this.farmerUserId,
    required this.productId,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.quantity,
    required this.status,
    required this.datePosted,
    this.imageUrl,
    this.location,
  });

  final String listingId;
  final String farmerUserId;
  final String productId;
  final String name;
  final String description;
  final String categoryId;
  final String categoryName;
  final double price;
  final int quantity;
  final String status;
  final DateTime datePosted;
  final String? imageUrl;
  final String? location;

  factory ListingItem.fromRow(Map<String, dynamic> row) {
    final productRow = row['product'] as Map<String, dynamic>?;
    final categoryRow = productRow?['category'] as Map<String, dynamic>?;

    return ListingItem(
      listingId: row['listing_id'].toString(),
      farmerUserId: row['farmer_user_id'].toString(),
      productId: row['product_id'].toString(),
      name: productRow?['name']?.toString() ?? 'Untitled product',
      description: productRow?['description']?.toString() ?? '',
      categoryId: productRow?['category_id']?.toString() ?? '',
      categoryName: categoryRow?['name']?.toString() ?? 'Uncategorized',
      price: (row['price'] as num).toDouble(),
      quantity: (row['quantity'] as num).toInt(),
      status: row['status']?.toString() ?? 'available',
      datePosted:
          DateTime.tryParse(row['date_posted']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      imageUrl: row['image_url']?.toString(),
      location: row['location']?.toString(),
    );
  }
}

class ListingRepository {
  ListingRepository(this._client);

  final SupabaseClient _client;

  Object _coerceIdValue(String rawId) {
    final asInt = int.tryParse(rawId);
    return asInt ?? rawId;
  }

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<CategoryOption>> getCategories() async {
    final rows = await _client
        .from('category')
        .select('category_id, name')
        .order('name', ascending: true);

    return rows
        .map(
          (row) => CategoryOption(
            id: row['category_id'].toString(),
            name: row['name'] as String,
          ),
        )
        .toList();
  }

  Future<void> createListing({
    required String name,
    required String description,
    required String categoryId,
    required int quantity,
    required double price,
    required String location,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('You must be logged in to create a listing.');
    }

    try {
      String? imageUrl;
      if (imageBytes != null) {
        final safeFileName = (imageFileName == null || imageFileName.isEmpty)
            ? 'listing-image.jpg'
            : imageFileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
        final storagePath =
            'listings/${user.id}/${DateTime.now().microsecondsSinceEpoch}_$safeFileName';

        await _client.storage
            .from('product_image')
            .uploadBinary(
              storagePath,
              imageBytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );
        imageUrl = _client.storage
            .from('product_image')
            .getPublicUrl(storagePath);
      }

      final productRow = await _client
          .from('product')
          .insert({
            'category_id': _coerceIdValue(categoryId),
            'name': name,
            'description': description,
          })
          .select('product_id')
          .single();

      final productId = productRow['product_id']?.toString();
      if (productId == null) {
        throw const PostgrestException(
          message: 'Missing product_id in response.',
        );
      }

      await _client.from('listing').insert({
        'farmer_user_id': user.id,
        'product_id': productId,
        'price': price,
        'quantity': quantity,
        'date_posted': DateTime.now().toUtc().toIso8601String(),
        'status': 'available',
        'location': location,
        'image_url': imageUrl,
      });
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<ListingItem>> getMarketplaceListings() async {
    try {
      final rows = await _client
          .from('listing')
          .select(
            'listing_id, farmer_user_id, product_id, price, quantity, date_posted, status, image_url, location, '
            'product:product_id(product_id, name, description, category_id, category:category_id(name))',
          )
          .order('date_posted', ascending: false);

      return (rows as List<dynamic>)
          .map((row) => ListingItem.fromRow(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<ListingItem>> getFarmerListings(String farmerUserId) async {
    try {
      final rows = await _client
          .from('listing')
          .select(
            'listing_id, farmer_user_id, product_id, price, quantity, date_posted, status, image_url, location, '
            'product:product_id(product_id, name, description, category_id, category:category_id(name))',
          )
          .eq('farmer_user_id', farmerUserId)
          .order('date_posted', ascending: false);

      return (rows as List<dynamic>)
          .map((row) => ListingItem.fromRow(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateListing({
    required String listingId,
    required String productId,
    required String name,
    required String description,
    required String categoryId,
    required int quantity,
    required double price,
    required String status,
    required String location,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('You must be logged in to update a listing.');
    }

    try {
      await _client
          .from('product')
          .update({
            'name': name,
            'description': description,
            'category_id': _coerceIdValue(categoryId),
          })
          .eq('product_id', productId);

      await _client
          .from('listing')
          .update({
            'quantity': quantity,
            'price': price,
            'status': status,
            'location': location,
          })
          .eq('listing_id', listingId)
          .eq('farmer_user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> deleteListing({
    required String listingId,
    required String productId,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('You must be logged in to delete a listing.');
    }

    try {
      await _client
          .from('listing')
          .delete()
          .eq('listing_id', listingId)
          .eq('farmer_user_id', userId);

      await _client.from('product').delete().eq('product_id', productId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepository(ref.watch(supabaseClientProvider));
});
