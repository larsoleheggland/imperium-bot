import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imperium_bot/business/bot/bot.dart';
import 'package:imperium_bot/business/bot/factions/carthaginians-bot.dart';
import 'package:imperium_bot/data/card-database.dart';
import 'package:imperium_bot/data/rules.dart';
import 'package:imperium_bot/models/card-enums.dart';
import 'package:imperium_bot/models/card.dart';

class BotCubit extends Cubit<BotState> {
  late Bot bot;

  late Completer<void> userActionCompleter;
  late PlayerSelectedCard? playerSelectedCard;

  BotCubit(Faction faction, Difficulty difficulty) : super(BotLoading()) {
    bot = CarthaginiansBot(difficulty);
    bot.initialize(this);
  }

  Future<bool> takeBotTurn() async {
    return await bot.playTurn();
  }

  Future<PlayerSelectedCard> requireCardFromUser(
      CardAcquireType acquireType, List<CardType> cardType) async {
    emit(BotRequestCard(acquireType, cardType));

    userActionCompleter = Completer<void>();

    await userActionCompleter.future;

    var result = playerSelectedCard;
    userActionCompleter = Completer<void>();
    return playerSelectedCard as PlayerSelectedCard;
  }

  Future<bool> requireUserAction(String title, Widget userDirections) async {
    emit(BotRequestUserAction(title, userDirections));

    userActionCompleter = Completer<void>();

    await userActionCompleter.future;
    userActionCompleter = Completer<void>();

    return true;
  }

  void selectUserCard(PlayerSelectedCard card) {
    playerSelectedCard = card;
    userActionCompleter.complete();
  }

  void confirmUserAction() {
    userActionCompleter.complete();
  }

  // User alerts

  Future<bool> alertRequireCardExile() async {
    var userDirections = Column(
      children: const [
        Text("Exile a card from market. "),
        Divider(height: 20),
        Text(
          Rules.exile,
          style: TextStyle(fontSize: 15),
        )
      ],
    );

    return await requireUserAction("Exile card", userDirections);
  }

  Future<bool> alertTakeUnrest() async {
    var userDirections = const Text("You take one unrest card.");

    return await alertAttack(userDirections);
  }

  Future<bool> alertBotTriggeredEndOfGame(String reason) async {
    var userDirections = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Bot has triggered end of game"),
          Text("(" + reason + ")"),
          Divider(height: 10),
          Text("You and the bot take one more turn before scoring"),
        ]);

    return await alertCustom("End of game triggered", userDirections);
  }

  Future<bool> alertAttack(Widget userDirections) async {
    var rulesAddToUserdirections = Row(
      children: [
        userDirections,
        const Divider(height: 20),
        const Text(
            "If you have an ability that allows you to cancel or ignore an attack you can use it to stop the negative effect",
            style: TextStyle(fontSize: 15))
      ],
    );
    return await requireUserAction("Attack!", userDirections);
  }

  Future<bool> alertAddUnrest() async {
    var userDirections = const Text(
        "Bot played an unrest card. Add one card from bots unrest pile to market unrest pile.");

    return await requireUserAction("Bot played unrest", userDirections);
  }

  Future<bool> alertUserMayDrawCard() async {
    var userDirections = const Text("You may draw a card");

    return await requireUserAction("Draw card", userDirections);
  }

  Future<bool> alertCustom(String title, Widget userDirections) async {
    return await requireUserAction(title, userDirections);
  }

  Future<bool> alertBotAddingUnrest() async {
    var userDirections = const Text(
        "Remove unrest card from market unrest pile, and add it to bots unrest pile.");
    bot.drawPile.addCard(CardDatabase.basicUnrestCard);
    return await requireUserAction("Bot received unrest card", userDirections);
  }
}

// States
class BotState {}

class BotFinishedTurn extends BotState {
  @override
  List<Object?> get props => throw UnimplementedError();
}

class BotRequestCard extends BotState {
  final CardAcquireType acquireType;
  final List<CardType> cardType;

  BotRequestCard(this.acquireType, this.cardType);
}

class BotRequestUserAction extends BotState {
  final String title;
  final Widget userDirections;

  BotRequestUserAction(this.title, this.userDirections);
}

class BotLoading extends BotState {}

class PlayerSelectedCard {
  final GameCard? card;
  final int progressTokens;
  final int materialTokens;
  final int populationTokens;
  final bool takeUnrest;

  PlayerSelectedCard(this.card, this.progressTokens, this.materialTokens,
      this.populationTokens, this.takeUnrest);
}
