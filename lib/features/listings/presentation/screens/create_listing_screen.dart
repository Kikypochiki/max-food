import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:max_food/features/listings/presentation/providers/listing_providers.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _selectedCategoryId;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final imageBytes = await image.readAsBytes();
    if (!mounted) return;

    setState(() {
      _selectedImage = image;
      _selectedImageBytes = imageBytes;
    });
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate() || _selectedCategoryId == null) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category.')),
        );
      }
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());
    final price = double.tryParse(_priceController.text.trim());

    if (quantity == null || quantity <= 0 || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity and price must be greater than 0.'),
        ),
      );
      return;
    }

    final success = await ref
        .read(createListingControllerProvider.notifier)
        .createListing(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          categoryId: _selectedCategoryId!,
          quantity: quantity,
          price: price,
          location: _locationController.text.trim(),
          imageBytes: _selectedImageBytes,
          imageFileName: _selectedImage?.name,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing created successfully.')),
      );
      Navigator.of(context).pop();
    } else {
      final error = ref.read(createListingControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Failed to create listing.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final controllerState = ref.watch(createListingControllerProvider);
    final isSubmitting = controllerState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A8F3A),
        foregroundColor: Colors.white,
        surfaceTintColor: const Color(0xFF2A8F3A),
        elevation: 0,
        title: const Text(
          'Create Listing',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    InkWell(
                      onTap: isSubmitting ? null : _pickImage,
                      child: Container(
                        height: 240,
                        color: const Color(0xFFF5F5F5),
                        child: _selectedImageBytes == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 48,
                                      color: Color(0xFF1F8E3E),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Add product photo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Color(0xFF202124),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Tap to select from gallery',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF80868B),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(
                                    _selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.1),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Tap to change photo',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Product Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF202124),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Product Name',
                              hintText: 'e.g., Organic Tomatoes',
                              prefixIcon: const Icon(
                                Icons.shopping_bag_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Product name is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          categoriesAsync.when(
                            data: (categories) =>
                                DropdownButtonFormField<String?>(
                                  initialValue: _selectedCategoryId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    prefixIcon: const Icon(
                                      Icons.category_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('Select a category'),
                                    ),
                                    ...categories.map(
                                      (category) => DropdownMenuItem<String>(
                                        value: category.id,
                                        child: Text(category.name),
                                      ),
                                    ),
                                  ],
                                  onChanged: isSubmitting
                                      ? null
                                      : (value) => setState(
                                          () => _selectedCategoryId = value,
                                        ),
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Category is required.';
                                    }
                                    return null;
                                  },
                                ),
                            loading: () => const LinearProgressIndicator(),
                            error: (error, _) => Text(
                              'Could not load categories: $error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            textInputAction: TextInputAction.next,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              hintText: 'Describe your product...',
                              prefixIcon: const Icon(
                                Icons.description_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Description is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Quantity',
                                    prefixIcon: const Icon(
                                      Icons.inventory_2_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (int.tryParse(value.trim()) == null) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Price',
                                    prefixIcon: const Text(
                                      'PHP ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value.trim()) == null) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _locationController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Location',
                              hintText: 'Where are you located?',
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Location is required.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2A8F3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isSubmitting ? null : _submit,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Flexible(
                    child: Text(
                      isSubmitting ? 'Publishing...' : 'Publish Listing',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
