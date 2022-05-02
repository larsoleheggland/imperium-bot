import 'package:flutter/services.dart' show rootBundle;
import 'package:imperium_bot/models/card.dart';

import '../models/card-enums.dart';

class CardParser {
  static const String separator = ";";

  static Future<List<GameCard>> parseFile(
      String name, CardCategory cardType) async {
    String filePath = "assets/csv/";

    switch (cardType) {
      case CardCategory.common:
        filePath += "commons/";
        break;
      case CardCategory.faction:
        filePath += "factions/";
        break;
    }

    filePath += name + ".csv";

    var fileContents = await rootBundle.loadString(filePath);
    fileContents = fileContents.replaceAll('\r', '');
    List<String> cardStrings = fileContents.split('\n');

    List<GameCard> cards = [];

    var index = 0;
    var headers = true;

    for (var cardString in cardStrings) {
      if (headers) {
        headers = false;
        continue;
      }

      var split = cardString.split(separator);

      //debugPrint("Csv line contents: ");
      for (var data in split) {
        //debugPrint(data);
      }
      try {
        cards.add(GameCard(
            split[0],
            split[1],
            split[2],
            split[3],
            split[4],
            split[5],
            split[6],
            split[7],
            split[8],
            split[9],
            split[10],
            split[11],
            split[12]));
      } catch (e) {
        var debug = index;
      }
    }

    index++;
    return cards;
  }
}
