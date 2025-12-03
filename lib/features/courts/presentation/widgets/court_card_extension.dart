import 'package:flutter/widgets.dart';
import 'court_card.dart';

extension CourtCardActions on CourtCard {
  CourtCard onCardAction({Key? key, VoidCallback? fn}) {
    return CourtCard(key: key, court: court, onAction: fn);
  }
}
