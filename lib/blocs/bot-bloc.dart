import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imperium_bot/business/bot/bot.dart';
import 'package:imperium_bot/business/bot/factions/carthaginians-bot.dart';
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

  void takeBotTurn() async {
    bot.playTurn();
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

  Future<bool> alertRequireCardExile() async {
    var userDirections = const Text("Exile a card from market");

    return await requireUserAction("Exile card", userDirections);
  }

  Future<bool> alertTakeUnrest() async {
    var userDirections = const Text("You take one unrest card");

    return await requireUserAction("Attack", userDirections);
  }

  Future<bool> alertUserMayDrawCard() async {
    var userDirections = const Text("You may draw a card");

    return await requireUserAction("Draw card", userDirections);
  }

  Future<bool> alertCustom(String title, Widget userDirections) async {
    return await requireUserAction(title, userDirections);
  }

  void selectUserCard(PlayerSelectedCard card) {
    playerSelectedCard = card;
    userActionCompleter.complete();
  }

  void confirmUserAction() {
    userActionCompleter.complete();
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
