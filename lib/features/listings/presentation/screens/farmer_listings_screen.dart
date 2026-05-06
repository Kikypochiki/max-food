import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:max_food/features/listings/data/listing_repository.dart';
import 'package:max_food/features/listings/presentation/providers/listing_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FarmerListingsScreen extends ConsumerStatefulWidget {
  const FarmerListingsScreen({required this.farmerUserId, super.key});

  final String farmerUserId;

  @override
  ConsumerState<FarmerListingsScreen> createState() =>
      _FarmerListingsScreenState();
}

class _FarmerListingsScreenState extends ConsumerState<FarmerListingsScreen> {
  Future<void> _confirmDelete(ListingItem listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text(
          'This will permanently remove ${listing.name}. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(listingCrudControllerProvider.notifier)
        .deleteListing(
          listingId: listing.listingId,
          productId: listing.productId,
          farmerUserId: listing.farmerUserId,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Listing deleted.')));
      return;
    }

    final error = ref.read(listingCrudControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error?.toString() ?? 'Failed to delete listing.')),
    );
  }

  Future<void> _openEditSheet(
    ListingItem listing,
    List<CategoryOption> categories,
  ) async {
    final nameController = TextEditingController(text: listing.name);
    final descriptionController = TextEditingController(
      text: listing.description,
    );
    final quantityController = TextEditingController(
      text: listing.quantity.toString(),
    );
    final priceController = TextEditingController(
      text: listing.price.toStringAsFixed(2),
    );
    final locationController = TextEditingController(
      text: listing.location ?? '',
    );

    String? selectedCategoryId = listing.categoryId.isEmpty
        ? (categories.isNotEmpty ? categories.first.id : null)
        : listing.categoryId;
    String selectedStatus = listing.status;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Edit Listing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D4F2A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categories
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setModalState(() => selectedCategoryId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              border: OutlineInputBorder(),
                              prefixText: 'PHP ',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'available',
                          child: Text('Available'),
                        ),
                        DropdownMenuItem(value: 'sold', child: Text('Sold')),
                        DropdownMenuItem(
                          value: 'hidden',
                          child: Text('Hidden'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedStatus = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2A8F3A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final quantity = int.tryParse(quantityController.text);
                        final price = double.tryParse(priceController.text);

                        if (nameController.text.trim().isEmpty ||
                            descriptionController.text.trim().isEmpty ||
                            selectedCategoryId == null ||
                            quantity == null ||
                            quantity <= 0 ||
                            price == null ||
                            price <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please complete all fields correctly.',
                              ),
                            ),
                          );
                          return;
                        }

                        final success = await ref
                            .read(listingCrudControllerProvider.notifier)
                            .updateListing(
                              listingId: listing.listingId,
                              productId: listing.productId,
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                              categoryId: selectedCategoryId!,
                              quantity: quantity,
                              price: price,
                              status: selectedStatus,
                              location: locationController.text.trim(),
                              farmerUserId: listing.farmerUserId,
                            );

                        if (!context.mounted) return;

                        if (success) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Listing updated.')),
                          );
                        } else {
                          final error = ref
                              .read(listingCrudControllerProvider)
                              .error;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error?.toString() ??
                                    'Failed to update listing.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(
      farmerListingsProvider(widget.farmerUserId),
    );
    final categoriesAsync = ref.watch(categoriesProvider);
    final mutationState = ref.watch(listingCrudControllerProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMe = currentUserId == widget.farmerUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A8F3A),
        foregroundColor: Colors.white,
        surfaceTintColor: const Color(0xFF2A8F3A),
        elevation: 0,
        title: Text(
          isMe ? 'My Store' : 'Farmer Store',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          if (isMe)
            IconButton(
              tooltip: 'Add item',
              onPressed: () => context.push('/listings/create'),
              icon: const Icon(Icons.add_circle_outline, size: 26),
            ),
        ],
      ),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  isMe
                      ? 'You have no listings yet.\n\nTap the + button to add your first item.'
                      : 'This farmer has no listings yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
              ref.invalidate(farmerListingsProvider(widget.farmerUserId));
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
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.65,
                  ),
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return _buildListingCard(
                      context,
                      listing,
                      categoriesAsync,
                      isMe,
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1F8E3E)),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Could not load listings.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
      bottomNavigationBar: mutationState.isLoading
          ? const LinearProgressIndicator(minHeight: 3)
          : null,
    );
  }

  Widget _buildListingCard(
    BuildContext context,
    ListingItem listing,
    AsyncValue<List<CategoryOption>> categoriesAsync,
    bool isMe,
  ) {
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: !isMe
                ? null
                : () async {
                    final categories = categoriesAsync.valueOrNull ?? const [];
                    if (categories.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Categories unavailable. Try again.'),
                        ),
                      );
                      return;
                    }
                    await _openEditSheet(listing, categories);
                  },
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
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${listing.quantity}',
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
        ),
        if (isMe)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    final categories = categoriesAsync.valueOrNull ?? const [];
                    if (categories.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Categories unavailable. Try again.'),
                        ),
                      );
                      return;
                    }
                    await _openEditSheet(listing, categories);
                  }
                  if (value == 'delete') {
                    await _confirmDelete(listing);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
