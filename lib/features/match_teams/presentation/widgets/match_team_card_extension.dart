// lib\features\match_teams\presentation\widgets\match_team_card_extension.dart
import 'package:flutter/widgets.dart';
import 'match_team_card.dart';

extension MatchTeamCardActions on MatchTeamCard {
  MatchTeamCard onCardAction(VoidCallback fn) {
    return MatchTeamCard(match: match, team: team, players: players, onAction: fn);
  }
}
