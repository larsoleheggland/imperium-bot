import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/models/card-enums.dart';

class BlocSingletons {
  static BotCubit? _botCubitInstance;
  static BotCubit botCubit = _getBotCubit();

  static BotCubit _getBotCubit() {
    if (_botCubitInstance == null) {
      _botCubitInstance = BotCubit(Faction.carthaginians, Difficulty.overlord);
    }

    return _botCubitInstance as BotCubit;
  }
}
