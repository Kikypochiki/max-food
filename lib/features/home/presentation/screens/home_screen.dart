import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:max_food/features/auth/data/auth_repository.dart';
import 'package:max_food/features/auth/presentation/providers/auth_providers.dart';
import 'package:max_food/features/listings/data/listing_repository.dart';
import 'package:max_food/features/listings/presentation/providers/listing_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildListingCard(
    BuildContext context,
    ListingItem listing,
    bool isOwner,
  ) {
    final statusColor = switch (listing.status.toLowerCase()) {
      'sold' => Colors.red.shade600,
      'hidden' => Colors.grey.shade400,
      _ => const Color(0xFF2A8F3A),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/farmers/${listing.farmerUserId}/listings'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      color: const Color(0xFFF0F0F0),
                      child:
                          listing.imageUrl == null || listing.imageUrl!.isEmpty
                          ? Image.asset(
                              'assets/images/logo_ubayharvest1.png',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              listing.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/logo_ubayharvest1.png',
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                    ),
                  ),
                  if (listing.status.toLowerCase() != 'available')
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            listing.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PHP ${listing.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF186A3B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      listing.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Color(0xFF1D4F2A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      listing.location?.isEmpty ?? true
                          ? listing.categoryName
                          : listing.location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF667A6C),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final listingsAsync = ref.watch(filteredMarketplaceListingsProvider);
    final query = ref.watch(listingSearchQueryProvider);

    if (_searchController.text != query) {
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A8F3A),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: const Color(0xFF2A8F3A),
        titleSpacing: 0,
        leading: Container(
          padding: const EdgeInsets.only(left: 12),
          alignment: Alignment.centerLeft,
          child: const Text(
            'UbayHarvest',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        leadingWidth: 180,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 26),
            tooltip: 'Create listing',
            onPressed: () => context.push('/listings/create'),
          ),
          IconButton(
            icon: const Icon(Icons.store_outlined, size: 26),
            tooltip: 'My listings',
            onPressed: user == null
                ? null
                : () => context.push('/farmers/${user.id}/listings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              color: const Color(0xFF2A8F3A),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) =>
                    ref.read(listingSearchQueryProvider.notifier).state = value,
                decoration: InputDecoration(
                  hintText: 'Search vegetables, fruits, rice...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF80868B),
                  ),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () =>
                              ref
                                      .read(listingSearchQueryProvider.notifier)
                                      .state =
                                  '',
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintStyle: const TextStyle(color: Color(0xFF667A6C)),
                ),
              ),
            ),
            Expanded(
              child: listingsAsync.when(
                data: (listings) {
                  if (listings.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No listings found.\nTry adding your first product.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF667A6C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF2A8F3A),
                    onRefresh: () async {
                      ref.invalidate(marketplaceListingsProvider);
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth >= 1080
                            ? 4
                            : constraints.maxWidth >= 760
                            ? 3
                            : 2;

                        return GridView.builder(
                          padding: const EdgeInsets.all(10),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: listings.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.65,
                              ),
                          itemBuilder: (context, index) {
                            final listing = listings[index];
                            final isOwner = user?.id == listing.farmerUserId;
                            return _buildListingCard(context, listing, isOwner);
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2A8F3A)),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Could not load listings.\n$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
