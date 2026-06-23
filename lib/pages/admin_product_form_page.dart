import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';

class AdminProductFormPage extends StatefulWidget {
  final ProductModel? product;

  const AdminProductFormPage({super.key, this.product});

  @override
  State<AdminProductFormPage> createState() => _AdminProductFormPageState();
}

class _AdminProductFormPageState extends State<AdminProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageController;
  late final TextEditingController _stockController;
  int _category = 1;
  bool _isSaving = false;

  static const Map<int, String> _categories = {
    1: 'Perfumes',
    2: 'Watches',
    3: 'Wallets',
    4: 'Shirts',
  };

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _priceController = TextEditingController(
      text: product != null ? product.price.round().toString() : '',
    );
    _imageController = TextEditingController(text: product?.imageUrl ?? '');
    _stockController = TextEditingController(
      text: product != null ? product.stock.toString() : '0',
    );
    if (product != null && product.category >= 1 && product.category <= 4) {
      _category = product.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final price = int.parse(_priceController.text.trim());
      final stock = int.parse(_stockController.text.trim());
      final payload = (
        itemName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        category: _category,
        image: _imageController.text.trim(),
        stock: stock,
      );

      if (_isEditing) {
        await ApiService.updateProduct(
          productId: widget.product!.id,
          itemName: payload.itemName,
          description: payload.description,
          price: payload.price,
          category: payload.category,
          image: payload.image,
          stock: payload.stock,
        );
      } else {
        await ApiService.createProduct(
          itemName: payload.itemName,
          description: payload.description,
          price: payload.price,
          category: payload.category,
          image: payload.image,
          stock: payload.stock,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Product updated' : 'Product created'),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isEditing ? 'Update product details' : 'Create a new product',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildNameField()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPriceField()),
                      ],
                    )
                  else ...[
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildPriceField(),
                  ],
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 16),
                  _buildCategoryField(cs),
                  const SizedBox(height: 16),
                  _buildImageField(),
                  const SizedBox(height: 16),
                  _buildStockField(),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEditing ? 'Save Changes' : 'Create Product',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryField(ColorScheme cs) {
    return DropdownMenu<int>(
      initialSelection: _category,
      label: const Text('Category'),
      textStyle: const TextStyle(color: Colors.white),
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: _categories.entries
          .map(
            (e) => DropdownMenuEntry<int>(
              value: e.key,
              label: e.value,
            ),
          )
          .toList(),
      onSelected: (value) {
        if (value != null) setState(() => _category = value);
      },
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(cs.surface),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surface,
        labelStyle: const TextStyle(color: Colors.white),
        floatingLabelStyle: const TextStyle(color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline),
        ),
      ),
      trailingIcon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      selectedTrailingIcon: const Icon(Icons.arrow_drop_up, color: Colors.white),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Product name',
        labelStyle: TextStyle(color: Colors.white),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Name is required' : null,
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Price (USD)',
        labelStyle: TextStyle(color: Colors.white),
        prefixText: '\$ ',
      ),
      validator: (value) {
        final parsed = int.tryParse(value?.trim() ?? '');
        if (parsed == null || parsed < 0) return 'Enter a valid price';
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Description',
        labelStyle: TextStyle(color: Colors.white),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildImageField() {
    return TextFormField(
      controller: _imageController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Image URL or asset path',
        labelStyle: TextStyle(color: Colors.white),
        hintText: 'https://... or assets/images/...',
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Image is required' : null,
    );
  }

  Widget _buildStockField() {
    return TextFormField(
      controller: _stockController,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Stock quantity',
        labelStyle: TextStyle(color: Colors.white),
      ),
      validator: (value) {
        final parsed = int.tryParse(value?.trim() ?? '');
        if (parsed == null || parsed < 0) return 'Enter a valid stock count';
        return null;
      },
    );
  }
}
