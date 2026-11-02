import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../services/supabase_service.dart';

class AddProductDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final Function(String) onError;

  const AddProductDialog({
    super.key,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController typeCtrl = TextEditingController(text: 'Refill');
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();

  bool isAvailable = true;
  PlatformFile? _selectedImage;
  bool _isSaving = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    typeCtrl.dispose();
    priceCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImage = result.files.first;
        });
      }
    } catch (e) {
      widget.onError('Failed to pick image: $e');
    }
  }

  Future<void> _submit() async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      widget.onError('Product Name cannot be empty.');
      return;
    }
    if (name.length < 2) {
      widget.onError('Product Name must be at least 2 characters.');
      return;
    }
    if (name.length > 50) {
      widget.onError('Product Name cannot exceed 50 characters.');
      return;
    }

    final category = typeCtrl.text.trim();
    if (category.isEmpty) {
      widget.onError('Category / Type cannot be empty.');
      return;
    }
    if (category.length > 30) {
      widget.onError('Category / Type cannot exceed 30 characters.');
      return;
    }

    final priceStr = priceCtrl.text.trim();
    final price = double.tryParse(priceStr);
    if (price == null || price <= 0) {
      widget.onError('Please enter a valid price greater than 0.');
      return;
    }
    if (price > 100000) {
      widget.onError('Price cannot exceed ₱100,000.');
      return;
    }

    String desc = descCtrl.text.trim();
    if (desc.length > 100) {
      desc = desc.substring(0, 100);
    }

    setState(() => _isSaving = true);
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await SupabaseService.uploadProductImage(_selectedImage!);
      }

      await SupabaseService.addProduct({
        'name': name,
        'category': category,
        'price': price,
        'description': desc,
        'image_url': imageUrl,
        'is_active': true,
        'is_available': isAvailable,
        'stock': isAvailable ? 100 : 0,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      widget.onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String hint = '',
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
            prefixIcon: maxLines == 1 ? Icon(icon, size: 20, color: const Color(0xFF7DD3FC)) : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
            counterStyle: const TextStyle(fontSize: 10, color: Color(0xFF7DD3FC)),
          ),
          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxDialogHeight = MediaQuery.of(context).size.height * 0.90;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: BoxConstraints(maxWidth: 520, maxHeight: maxDialogHeight),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFA082A45),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x3838BDF8), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 36,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0x330284C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x4038BDF8)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF38BDF8), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add Master Product',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFFBAE6FD)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Divider(height: 24, color: Colors.white.withValues(alpha: 0.18)),
                  _buildField(
                    label: 'Product Name (Max 50 characters)',
                    controller: nameCtrl,
                    icon: Icons.shopping_bag_rounded,
                    hint: 'e.g. Purified Gallon Refill',
                    maxLength: 50,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    label: 'Category / Type (Max 30 characters)',
                    controller: typeCtrl,
                    icon: Icons.category_rounded,
                    hint: 'Refill, Container, Accessory',
                    maxLength: 30,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    label: 'Price (₱)',
                    controller: priceCtrl,
                    icon: Icons.payments_rounded,
                    hint: '35.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    label: 'Description (Max 100 characters)',
                    controller: descCtrl,
                    icon: Icons.description_rounded,
                    hint: 'Short product description...',
                    maxLines: 2,
                    maxLength: 100,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available for Ordering & POS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text(
                        isAvailable ? 'Status: Available' : 'Status: Unavailable',
                        style: TextStyle(fontSize: 11, color: isAvailable ? const Color(0xFF34D399) : const Color(0xFFFCA5A5)),
                      ),
                      value: isAvailable,
                      activeThumbColor: const Color(0xFF38BDF8),
                      onChanged: (val) => setState(() => isAvailable = val),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Product Image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _pickImage,
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: Text(_selectedImage == null ? 'Choose Image File' : 'Change Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_selectedImage != null)
                        Expanded(
                          child: Text(
                            _selectedImage!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        const Text('No file chosen', style: TextStyle(fontSize: 12, color: Color(0xFFBAE6FD))),
                    ],
                  ),
                  if (_selectedImage?.bytes != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _selectedImage!.bytes!,
                        height: 90,
                        width: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                        child: const Text('Cancel', style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD), fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Product', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
