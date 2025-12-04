import 'package:flutter/widgets.dart';
import 'match_team_card.dart';

extension MatchTeamCardActions on MatchTeamCard {
  MatchTeamCard onCardAction(VoidCallback fn) {
    return MatchTeamCard(team: team, onAction: fn);
  }
}
