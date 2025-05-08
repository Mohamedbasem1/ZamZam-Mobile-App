import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/api_services.dart' show Product;
import 'quantity_selector.dart';

class ProductDetailDialog extends StatefulWidget {
  final Product product;
  final Function(int)? onNavigate;

  const ProductDetailDialog({
    Key? key,
    required this.product,
    this.onNavigate,
  }) : super(key: key);

  @override
  _ProductDetailDialogState createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  final CartService _cartService = CartService();
  int _selectedQuantity = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.product.image,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.product.price,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Stock: ${widget.product.stockCount}',
                      style: TextStyle(
                        color: widget.product.stockCount > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: QuantitySelector(
                  quantity: _selectedQuantity,
                  maxQuantity: widget.product.stockCount,
                  onChanged: (value) {
                    setState(() {
                      _selectedQuantity = value;
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: widget.product.stockCount > 0
                      ? () {
                          _cartService.addToCart(widget.product, quantity: _selectedQuantity);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${widget.product.name} added to cart'),
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'VIEW CART',
                                onPressed: () {
                                  if (widget.onNavigate != null) {
                                    widget.onNavigate!(3);
                                  }
                                },
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.product.stockCount > 0 ? 'Add to Cart' : 'Out of Stock',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
} 