import 'package:flutter/material.dart';
import '../models/card_item.dart';
import '../../../theme/color_palette.dart';

class CardWidget extends StatelessWidget {
  final CardItem card;
  final VoidCallback onTap;

  const CardWidget({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(card.icon, size: 40, color: card.color),
            const SizedBox(height: 12),
            Text(
              card.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorPalette.text800,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (card.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                card.subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: ColorPalette.text500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}