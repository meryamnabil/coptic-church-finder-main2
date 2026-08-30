import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/church_provider.dart';
import 'select_location_screen.dart';

const Color primaryGold = Color(0xFFB8965E);
const Color darkGold = Color(0xFF8C6A3E);
const Color backgroundBeige = Color(0xFFF5EFE6);

class AddChurchScreen extends StatefulWidget {
  const AddChurchScreen({super.key});

  @override
  State<AddChurchScreen> createState() => _AddChurchScreenState();
}

class _AddChurchScreenState extends State<AddChurchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  LatLng? _selectedLatLng;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundBeige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Wrap(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.photo_library, color: primaryGold),
                  ),
                  title: const Text(
                    'معرض الصور',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGold,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        _selectedImage = File(pickedFile.path);
                      });
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.camera_alt, color: primaryGold),
                  ),
                  title: const Text(
                    'الكاميرا',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGold,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        _selectedImage = File(pickedFile.path);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickLocation() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SelectLocationScreen(initialLocation: _selectedLatLng),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLatLng = result;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد الموقع على الخريطة'),
          backgroundColor: darkGold,
        ),
      );
      return;
    }

    final churchProvider = context.read<ChurchProvider>();

    final success = await churchProvider.addChurch(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      latitude: _selectedLatLng!.latitude,
      longitude: _selectedLatLng!.longitude,
      description: _descriptionController.text.trim(),
      imageFile: _selectedImage,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(churchProvider.errorMessage ?? 'حدث خطأ أثناء الحفظ'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: darkGold),
      prefixIcon: Icon(icon, color: primaryGold),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryGold, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: primaryGold.withOpacity(0.3)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<ChurchProvider>().isSaving;

    return Scaffold(
      backgroundColor: backgroundBeige,
      appBar: AppBar(
        title: const Text(
          'إضافة كنيسة جديدة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryGold, darkGold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: isSaving ? null : _pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: primaryGold.withOpacity(0.4)),
                    image:
                        _selectedImage != null
                            ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      _selectedImage == null
                          ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: primaryGold,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'اضغط لتحميل صورة الكنيسة',
                                style: TextStyle(
                                  color: darkGold,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                enabled: !isSaving,
                decoration: _inputDecoration('اسم الكنيسة', Icons.church),
                validator:
                    (val) =>
                        val == null || val.isEmpty
                            ? 'يرجى إدخال اسم الكنيسة'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                enabled: !isSaving,
                decoration: _inputDecoration('العنوان', Icons.location_on),
                validator:
                    (val) =>
                        val == null || val.isEmpty
                            ? 'يرجى إدخال العنوان'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !isSaving,
                maxLines: 3,
                decoration: _inputDecoration('الوصف', Icons.description),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: primaryGold, width: 1.5),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: isSaving ? null : _pickLocation,
                icon: const Icon(Icons.map, color: primaryGold),
                label: Text(
                  _selectedLatLng == null
                      ? 'تحديد الموقع على الخريطة'
                      : 'تم تحديد الموقع (${_selectedLatLng!.latitude.toStringAsFixed(4)}, ${_selectedLatLng!.longitude.toStringAsFixed(4)})',
                  style: const TextStyle(
                    color: darkGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                onPressed: isSaving ? null : _submit,
                child:
                    isSaving
                        ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                        : const Text(
                          'حفظ الكنيسة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
