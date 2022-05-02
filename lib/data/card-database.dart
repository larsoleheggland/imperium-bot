import 'package:imperium_bot/business/card-parser.dart';
import 'package:imperium_bot/models/card-enums.dart';
import 'package:imperium_bot/models/card.dart';

class CardDatabase {
  static List<GameCard> commons = [];
  static List<GameCard> fame = [];
  static GameCard basicUnrestCard = null as GameCard;

  static List<GameCard> all = [];

  static Future<bool> initialize() async {
    commons = await CardParser.parseFile("commons", CardCategory.common);
    fame = await CardParser.parseFile("fame", CardCategory.common);
    basicUnrestCard = generateUnrestCard();

    all.addAll(commons);
    all.addAll(fame);

    return true;
  }

  static GameCard generateUnrestCard() {
    return GameCard(
        "Unrest",
        "common",
        "unrest",
        "",
        "",
        "Choose: Pay 1 Pop OR discard 2 cards OR pay 3 Materials. If you do, return this card to the unrest pile.",
        "",
        "",
        "",
        "-2",
        "",
        "classics");
  }
}
