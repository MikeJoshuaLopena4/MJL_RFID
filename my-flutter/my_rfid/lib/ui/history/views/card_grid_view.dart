import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_item.dart';
import '../widgets/card_widget.dart';
import '../../../theme/color_palette.dart';

class CardGridView extends StatelessWidget {  // Changed from GridView to CardGridView
  final Stream<QuerySnapshot> linkedIdsStream;
  final List<CardItem> Function(QuerySnapshot) buildCardItems;
  final Function(CardItem) onCardTap;

  const CardGridView({  // Changed constructor name
    super.key,
    required this.linkedIdsStream,
    required this.buildCardItems,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: linkedIdsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.credit_card_off,
                  size: 64,
                  color: ColorPalette.text300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No linked cards yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: ColorPalette.text600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add cards in the Linked IDs section',
                  style: TextStyle(
                    color: ColorPalette.text400,
                  ),
                ),
              ],
            ),
          );
        }

        final cards = buildCardItems(snapshot.data!);

        return Container(
          color: ColorPalette.background50,
          padding: const EdgeInsets.all(16),
          child: GridView.builder(  // This now refers to Flutter's GridView
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return CardWidget(
                card: card,
                onTap: () => onCardTap(card),
              );
            },
          ),
        );
      },
    );
  }
}