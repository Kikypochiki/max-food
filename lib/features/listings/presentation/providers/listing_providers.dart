import 'dart:typed_data';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:max_food/features/listings/data/listing_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final categoriesProvider = FutureProvider<List<CategoryOption>>((ref) {
  return ref.watch(listingRepositoryProvider).getCategories();
});

final listingSearchQueryProvider = StateProvider<String>((ref) => '');

final marketplaceListingsProvider = FutureProvider<List<ListingItem>>((ref) {
  return ref.watch(listingRepositoryProvider).getMarketplaceListings();
});

final filteredMarketplaceListingsProvider =
    Provider<AsyncValue<List<ListingItem>>>((ref) {
      final query = ref.watch(listingSearchQueryProvider).trim().toLowerCase();
      final listingsAsync = ref.watch(marketplaceListingsProvider);

      return listingsAsync.whenData((listings) {
        if (query.isEmpty) {
          return listings;
        }

        return listings.where((listing) {
          final searchable =
              '${listing.name} ${listing.description} ${listing.categoryName}'
                  .toLowerCase();
          return searchable.contains(query);
        }).toList();
      });
    });

final farmerListingsProvider = FutureProvider.family<List<ListingItem>, String>(
  (ref, farmerUserId) {
    return ref.watch(listingRepositoryProvider).getFarmerListings(farmerUserId);
  },
);

final myListingsProvider = FutureProvider<List<ListingItem>>((ref) {
  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser == null) {
    return Future.value(const <ListingItem>[]);
  }
  return ref.watch(listingRepositoryProvider).getFarmerListings(currentUser.id);
});

void _invalidateListingCaches(Ref ref, {String? farmerUserId}) {
  ref.invalidate(marketplaceListingsProvider);
  ref.invalidate(filteredMarketplaceListingsProvider);
  ref.invalidate(myListingsProvider);
  if (farmerUserId != null) {
    ref.invalidate(farmerListingsProvider(farmerUserId));
  }
}

class CreateListingController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> createListing({
    required String name,
    required String description,
    required String categoryId,
    required int quantity,
    required double price,
    required String location,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repo = ref.read(listingRepositoryProvider);
      await repo.createListing(
        name: name,
        description: description,
        categoryId: categoryId,
        quantity: quantity,
        price: price,
        location: location,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
      );
      _invalidateListingCaches(ref, farmerUserId: repo.currentUserId);
    });

    return !state.hasError;
  }
}

final createListingControllerProvider =
    AsyncNotifierProvider<CreateListingController, void>(
      CreateListingController.new,
    );

class ListingCrudController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> updateListing({
    required String listingId,
    required String productId,
    required String name,
    required String description,
    required String categoryId,
    required int quantity,
    required double price,
    required String status,
    required String location,
    required String farmerUserId,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref
          .read(listingRepositoryProvider)
          .updateListing(
            listingId: listingId,
            productId: productId,
            name: name,
            description: description,
            categoryId: categoryId,
            quantity: quantity,
            price: price,
            status: status,
            location: location,
          );
      _invalidateListingCaches(ref, farmerUserId: farmerUserId);
    });

    return !state.hasError;
  }

  Future<bool> deleteListing({
    required String listingId,
    required String productId,
    required String farmerUserId,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref
          .read(listingRepositoryProvider)
          .deleteListing(listingId: listingId, productId: productId);
      _invalidateListingCaches(ref, farmerUserId: farmerUserId);
    });

    return !state.hasError;
  }
}

final listingCrudControllerProvider =
    AsyncNotifierProvider<ListingCrudController, void>(
      ListingCrudController.new,
    );
