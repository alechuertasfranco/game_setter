import 'package:flutter_test/flutter_test.dart';

import 'package:game_setter/core/update/update_service.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
import 'package:game_setter/features/match_teams/domain/formations/soccer_formations.dart';
import 'package:game_setter/features/match_teams/domain/formations/volleyball_formations.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

MatchTeamPlayer _tp(int slot, String code) => MatchTeamPlayer(
  teamId: 1,
  playerId: slot,
  slot: slot,
  positionId: code.hashCode,
  position: Position(id: code.hashCode, sportId: 1, name: code, shortName: code),
);

void main() {
  group('Vóley', () {
    test('5-1 tiene opuesto en diagonal al armador y 4-2 dos armadores', () {
      final f51 = volleyballFormations['5-1']!;
      final f42 = volleyballFormations['4-2']!;

      expect(f51.allSlots.map((s) => s.code), ['PTA', 'CTR', 'ARM', 'OP', 'CTR', 'PTA']);
      expect(f42.allSlots.map((s) => s.code), ['PTA', 'CTR', 'ARM', 'ARM', 'CTR', 'PTA']);
      expect(f51.allSlots.map((s) => s.slot), [1, 2, 3, 4, 5, 6]);
    });

    test('usa la formación guardada', () {
      expect(resolveVolleyballFormation('5-1', []).name, '5-1');
      expect(resolveVolleyballFormation('4-2', [_tp(4, 'OP')]).name, '4-2');
    });

    test('equipos antiguos: deduce 5-1 si hay opuesto, si no 4-2', () {
      expect(resolveVolleyballFormation(null, [_tp(1, 'PTA'), _tp(4, 'OP')]).name, '5-1');
      expect(resolveVolleyballFormation(null, [_tp(1, 'PTA'), _tp(4, 'ARM')]).name, '4-2');
      expect(resolveVolleyballFormation(null, []).name, '4-2');
    });

    test('líbero se detecta por su slot', () {
      expect(teamHasLibero([_tp(7, 'LIB')]), isTrue);
      expect(teamHasLibero([_tp(1, 'PTA')]), isFalse);
    });
  });

  group('Fútbol', () {
    test('deduce la formación por el slot más bajo', () {
      expect(detectFormationFromSlots([_tp(305, 'MID'), _tp(300, 'DEL')]).name, '4-3-3');
      expect(resolveSoccerFormation('2-2', [_tp(305, 'MID')]).name, '2-2');
    });

    test('slots planos en orden de dibujo', () {
      expect(formations['3-2']!.slots, [(800, 'DEL'), (801, 'DEL'), (802, 'DEF'), (803, 'DEF'), (804, 'DEF'), (805, 'GK')]);
    });
  });

  group('UpdateService.parseRelease', () {
    Map<String, dynamic> release({String tag = 'v1.2.0+3', String body = 'Novedades', bool withApk = true}) => {
      'tag_name': tag,
      'body': body,
      'assets': [
        if (withApk) {'name': 'game_setter-1.2.0.apk', 'browser_download_url': 'https://example.com/app.apk'},
        {'name': 'notes.txt', 'browser_download_url': 'https://example.com/notes.txt'},
      ],
    };

    test('lee versión, build y APK', () {
      final info = UpdateService.parseRelease(release())!;
      expect(info.latestVersion, '1.2.0');
      expect(info.latestBuildNumber, 3);
      expect(info.apkUrl, 'https://example.com/app.apk');
      expect(info.forceUpdate, isFalse);
    });

    test('#obligatoria fuerza la actualización y no se muestra', () {
      final info = UpdateService.parseRelease(release(body: 'Arreglos #obligatoria'))!;
      expect(info.forceUpdate, isTrue);
      expect(info.releaseNotes, 'Arreglos');
    });

    test('ignora releases sin APK o con tag inválido', () {
      expect(UpdateService.parseRelease(release(withApk: false)), isNull);
      expect(UpdateService.parseRelease(release(tag: 'v1.2.0')), isNull);
    });
  });
}
