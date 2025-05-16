import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';

class UpdateValuesPage extends StatefulWidget {
  final QueryDocumentSnapshot product;
  UpdateValuesPage({required this.product});

  @override
  _UpdateValuesPageState createState() => _UpdateValuesPageState();
}

class _UpdateValuesPageState extends State<UpdateValuesPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late double _price;
  late double _rating;
  late int _ratingCount;
  late int _stockCount;
  late bool _isFeatured;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _name = widget.product['name'] ?? '';
    _price = (widget.product['price'] ?? 0).toDouble();
    _rating = (widget.product['rating'] ?? 0).toDouble();
    _ratingCount = (widget.product['ratingCount'] ?? 0).toInt();
    _stockCount = (widget.product['stockCount'] ?? 0).toInt();
    _isFeatured = widget.product['isFeatured'] ?? false;
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    String? base64Image = widget.product['image'];
    if (_imageFile != null) {
      final bytes = await _imageFile!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    final updatedData = {
      'name': _name,
      'price': _price,
      'rating': _rating,
      'ratingCount': _ratingCount,
      'stockCount': _stockCount,
      'isFeatured': _isFeatured,
      'image': base64Image ?? '',
    };

    await FirebaseFirestore.instance
        .collection('Products')
        .doc(widget.product['docId'])
        .update(updatedData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Product updated successfully!')),
    );
    Navigator.of(context).pop(); // Go back to update_product.dart
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    if (_imageFile == null && widget.product['image'] != null && widget.product['image'] != '') {
      try {
        imageBytes = base64Decode(widget.product['image']);
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter the product name' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _price.toString(),
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || double.tryParse(value) == null ? 'Please enter a valid price' : null,
                onSaved: (value) => _price = double.parse(value!),
              ),
              TextFormField(
                initialValue: _rating.toString(),
                decoration: InputDecoration(labelText: 'Rating'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || double.tryParse(value) == null ? 'Please enter a valid rating' : null,
                onSaved: (value) => _rating = double.parse(value!),
              ),
              TextFormField(
                initialValue: _ratingCount.toString(),
                decoration: InputDecoration(labelText: 'Rating Count'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || int.tryParse(value) == null ? 'Please enter a valid rating count' : null,
                onSaved: (value) => _ratingCount = int.parse(value!),
              ),
              TextFormField(
                initialValue: _stockCount.toString(),
                decoration: InputDecoration(labelText: 'Stock Count'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || int.tryParse(value) == null ? 'Please enter a valid stock count' : null,
                onSaved: (value) => _stockCount = int.parse(value!),
              ),
              SwitchListTile(
                title: Text('Is Featured'),
                value: _isFeatured,
                onChanged: (value) => setState(() => _isFeatured = value),
              ),
              SizedBox(height: 16),
              _imageFile == null
                  ? (imageBytes != null
                      ? Image.memory(imageBytes, height: 120, width: double.infinity, fit: BoxFit.cover)
                      : Text('No image selected'))
                  : FutureBuilder<Uint8List>(
                      future: _imageFile!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        } else if (snapshot.hasError) {
                          return Text('Error loading image');
                        } else {
                          return CircularProgressIndicator();
                        }
                      },
                    ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera),
                    label: Text('Camera'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo),
                    label: Text('Gallery'),
                  ),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateProduct,
                child: Text('Update Product'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}