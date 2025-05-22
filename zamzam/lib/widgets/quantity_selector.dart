import 'package:flutter/material.dart';

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final Function(int) onChanged;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  const QuantitySelector({
    Key? key,
    required this.quantity,
    this.maxQuantity = 99,
    required this.onChanged,
    this.width,
    this.height = 36,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surface;
    final fgColor = iconColor ?? theme.colorScheme.primary;
    final txtColor = textColor ?? theme.textTheme.bodyLarge?.color;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildButton(
            icon: Icons.remove,
            onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
            color: fgColor,
          ),
          Container(
            constraints: BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: txtColor,
              ),
            ),
          ),
          _buildButton(
            icon: Icons.add,
            onPressed: quantity < maxQuantity ? () => onChanged(quantity + 1) : null,
            color: fgColor,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: height,
          height: height,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null ? color.withOpacity(0.3) : color,
          ),
        ),
      ),
    );
  }
} 