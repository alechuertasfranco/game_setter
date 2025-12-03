import 'package:flutter/widgets.dart';
import 'match_card.dart';

extension MatchCardActions on MatchCard {
  MatchCard onCardAction(VoidCallback fn) {
    return MatchCard(match: match, onAction: fn);
  }
}
