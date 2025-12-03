import 'package:flutter/widgets.dart';
import 'player_card.dart';

extension PlayerCardActions on PlayerCard {
  PlayerCard onCardAction({Key? key, VoidCallback? fn}) {
    return PlayerCard(key: key, player: player, onAction: fn);
  }
}
