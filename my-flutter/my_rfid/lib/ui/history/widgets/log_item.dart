import 'package:flutter/material.dart';
import '../models/access_log.dart';
import '../../../theme/color_palette.dart';

class LogItem extends StatelessWidget {
  final AccessLog log;
  final bool showCardName;

  const LogItem({
    super.key,
    required this.log,
    this.showCardName = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: log.type == 'Entry'
                ? ColorPalette.accent50
                : ColorPalette.primary50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            log.type == 'Entry' ? Icons.login : Icons.logout,
            color: log.type == 'Entry'
                ? ColorPalette.accent500
                : ColorPalette.primary500,
            size: 20,
          ),
        ),
        title: Text(
          log.time,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ColorPalette.text800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${log.type} - ${log.location}',
              style: TextStyle(
                color: ColorPalette.text600,
              ),
            ),
            if (showCardName)
              Text(
                log.cardName,
                style: TextStyle(
                  color: ColorPalette.text400,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Icon(
          log.type == 'Entry' ? Icons.arrow_forward : Icons.arrow_back,
          color: ColorPalette.text400,
        ),
      ),
    );
  }
}