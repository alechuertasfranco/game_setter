import 'package:flutter/widgets.dart';
import 'court_card.dart';

extension CourtCardActions on CourtCard {
  CourtCard onCardAction(VoidCallback fn) {
    return CourtCard(court: court, onAction: fn);
  }
}
