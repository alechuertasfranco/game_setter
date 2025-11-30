import 'package:flutter/widgets.dart';
import 'player_card.dart';

extension PlayerCardActions on PlayerCard {
  PlayerCard onCardAction(VoidCallback fn) {
    return PlayerCard(player: player, onAction: fn);
  }
}
