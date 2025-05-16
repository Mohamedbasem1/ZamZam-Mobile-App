import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'update_values.dart';

class UpdateProductPage extends StatefulWidget {
  @override
  _UpdateProductPageState createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Product'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Products',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No products found.'));
                }
                final products = snapshot.data!.docs.where((doc) {
                  final name = (doc['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchText);
                }).toList();

                if (products.isEmpty) {
                  return Center(child: Text('No products match your search.'));
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product['name'] ?? ''),
                      subtitle: Text('Price: \$${product['price'] ?? ''}'),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.orange),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UpdateValuesPage(product: product),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EditProductDialog extends StatefulWidget {
  final QueryDocumentSnapshot product;
  EditProductDialog({required this.product});

  @override
  _EditProductDialogState createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
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

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Product updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    if (_imageFile == null && widget.product['image'] != null && widget.product['image'] != '') {
      try {
        imageBytes = base64Decode(widget.product['image']);
      } catch (_) {}
    }

    return AlertDialog(
      title: Text('Edit Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text('Submit'),
          onPressed: _updateProduct,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        ),
      ],
    );
  }
}

