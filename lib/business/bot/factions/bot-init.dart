import 'package:imperium_bot/business/bot/bot.dart';
import 'package:imperium_bot/models/card-enums.dart';
import 'package:imperium_bot/models/card.dart';

class Carthaginians extends Bot {
  Carthaginians(Difficulty difficulty)
      : super(Faction.carthaginians, difficulty);

  @override
  resolveCard(GameCard card) async{
    return false;
  }

  @override
  void extraSetup() {}
}
