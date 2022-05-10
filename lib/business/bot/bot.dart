import 'dart:math';

import 'package:flutter/material.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/business/card-parser.dart';
import 'package:imperium_bot/data/card-database.dart';
import 'package:imperium_bot/extensions/enum-extensions.dart';
import 'package:imperium_bot/models/bot-log-entry.dart';
import 'package:imperium_bot/models/card-deck.dart';
import 'package:imperium_bot/models/card-enums.dart';
import 'package:imperium_bot/models/card.dart';

class Bot {
  final Faction faction;
  final Difficulty difficulty;

  int materialTokens = 0;
  int populationTokens = 0;
  int progressTokens = 0;

  //BotCubit botCubit = BlocSingletons.botCubit;
  Stage stage = Stage.barbarian;

  bool isEndOfGameTriggered = false;
  bool hasGameEnded = false;
  int roundsSinceGameEndTriggered = 0;
  int latestDiceRoll = 0;

  late BotCubit botCubit;
  late List<GameCard> pinnedCards = [];
  late CardDeck drawPile;
  late CardDeck discardPile;
  late CardDeck dynastyDeck;
  late CardDeck historyDeck;
  late List<GameCard> removedCards = [];
  late List<GameCard> cardsInPlay;
  late List<GameCard> cardsToBeRemovedFromPlayDeck;

  GameCard? retainedCardInPlay;
  List<BotLogEntry> botLog = [];

  Bot(this.faction, this.difficulty);

  void initialize(BotCubit cubit) async {
    var cards = await CardParser.parseFile(
        faction.toShortString(), CardCategory.faction);

    botCubit = cubit;
    cardsToBeRemovedFromPlayDeck = [];
    historyDeck = CardDeck([], "(Bot) History Deck");
    discardPile = CardDeck([], "(Bot) Discard Pile");
    cardsInPlay = [];

    CardDatabase.all.addAll(cards);

    setupDrawPile(cards);
    setupDynastyDeck(cards);
    drawCardsToPlayArea();
    difficultySetup();
    extraSetup();
  }

  void difficultySetup() {
    if (difficulty == Difficulty.sovereign ||
        difficulty == Difficulty.overlord) {
      materialTokens += 3;
      populationTokens += 2;
      progressTokens += 1;
    }
  }

  void log(String text, {BotLogEntryType entryType = BotLogEntryType.info}) {
    botLog.add(BotLogEntry(text, type: entryType));
  }

  Future<bool> playTurn() async {
    latestDiceRoll = rollDice(6);
    var index = 1;
    for (var card in cardsInPlay) {
      if (latestDiceRoll != index) {
        //priority cards = unrest, king of kings etc.
        var resolvedPriorityCard = await resolvePriorityCards(card);

        if (!resolvedPriorityCard) {
          await resolveCard(card);
        }
      }
      index++;
    }

    if (latestDiceRoll != 6) {
      addTokensToCard(latestDiceRoll);
    }

    cleanUp();

    if (isEndOfGameTriggered) {
      if (roundsSinceGameEndTriggered > 0) {
        hasGameEnded = true;
      } else {
        roundsSinceGameEndTriggered++;
      }
    }

    return true;
  }

  Future<bool> resolvePriorityCards(GameCard card) async {
    if (card.hasIcon(CardIcon.unrest)) {
      log("Resolves unrest action: alerts user to put an unrest card in pile, and removes card from bots deck");
      await botCubit.alertAddUnrest();
      cardsToBeRemovedFromPlayDeck.add(card);
      return true;
    }

    return false;
  }

  void drawCardsToPlayArea() {
    var cardsToDraw = _getCardCountToPlayEachRound();

    if (retainedCardInPlay != null) {
      cardsToDraw -= 1;
    }

    //initial draw
    if (latestDiceRoll == 0) {
      cardsToDraw = _getCardCountToPlayEachRound();
    }

    while (cardsInPlay.length < cardsToDraw) {
      //Don't overwrite existing card from last round.
      var card = drawCard();
      log("Bot adds card " + card.name + " to play area");
      cardsInPlay.add(card);
    }

    if (retainedCardInPlay != null) {
      cardsInPlay.insert(latestDiceRoll - 1, retainedCardInPlay as GameCard);
    }
  }

  GameCard drawCard() {
    if (drawPile.cardCount() > 0) {
      var card = drawPile.draw();
      log("Bot draws " + card.name);
      return card;
    }

    log("Draw pile empty!");
    // If empty draw pile
    var dynastyCard = drawDynastyCard();

    if (dynastyCard != null) {
      discardPile.addCard(dynastyCard);
    }

    log("Shuffling discard pile..");
    discardPile.shuffle();
    log("Adds cards to draw deck..");
    drawPile.addCards(discardPile.getCards());
    discardPile.removeAll();

    var card = drawPile.draw();
    log("Bot draws " + card.name);
    return card;
  }

  GameCard? drawDynastyCard() {
    if (dynastyDeck.cardCount() == 0 && !isEndOfGameTriggered) {
      isEndOfGameTriggered = true;
      botCubit.alertBotTriggeredEndOfGame("Drawn last card of dynasty deck");
      return null;
    }

    var dynastyCard = dynastyDeck.draw();
    log("Dynasty card added: " + dynastyCard.name);
    if (dynastyCard.IsType(CardType.accession)) {
      log("Dynasty card was an accession card, and bot entered empire stage");
      stage = Stage.empire;
    }

    return dynastyCard;
  }

  GameCard drawAndDiscard() {
    var card = drawCard();
    discardPile.addCard(card);

    return card;
  }

  GameCard? abandonRegion({GameCard? card}) {
    if (card != null) {
      pinnedCards.remove(card);
      discardPile.addCard(card);
      return card;
    }

    for (var card in pinnedCards) {
      if (card.icons.contains(CardIcon.region)) {
        pinnedCards.remove(card);
        discardPile.addCard(card);

        log("Bot abandoned region " + card.name);
        return card;
      }
    }

    log("Bot tried to abandon region, but has none.");
    return null;
  }

  GameCard? recallRegion({GameCard? card}) {
    if (card != null) {
      pinnedCards.remove(card);
      drawPile.addCard(card);
      return card;
    }

    // Recall newest

    for (var card in pinnedCards) {
      if (card.icons.contains(CardIcon.region)) {
        pinnedCards.remove(card);
        drawPile.addCard(card);

        log("Bot recalled region " + card.name);
        return card;
      }
    }

    log("Bot tried to recall region, but has none.");
    return null;
  }

  int getScore() {
    var score = 0;
    List<GameCard> scoringCards = [];
    scoringCards.addAll(cardsInPlay);
    scoringCards.addAll(drawPile.getCards());
    scoringCards.addAll(discardPile.getCards());
    scoringCards.addAll(historyDeck.getCards());
    scoringCards.addAll(pinnedCards);

    score += progressTokens;

    var tokenDivider = 10;

    if (difficulty == Difficulty.sovereign ||
        difficulty == Difficulty.overlord) {
      tokenDivider = 5;
    }

    var pointsForTokens = (materialTokens + populationTokens) / tokenDivider;
    score += pointsForTokens.floor();

    for (var card in scoringCards) {
      score += card.victoryPoints;
    }

    return score;
  }

  int getPinnedRegionCount() {
    var pinnedRegions = 0;

    for (var pinned in pinnedCards) {
      if (pinned.hasIcon(CardIcon.region)) {
        pinnedRegions++;
      }
    }

    return pinnedRegions;
  }

  Future<bool> breakthroughFor(List<CardType> cardTypes) async {
    var breakthroughCard = await botCubit.requireCardFromUser(
        CardAcquireType.breakthrough, cardTypes);

    if (breakthroughCard.card != null) {
      log("Bot broke through and got " + breakthroughCard.card!.name);
      addPlayerSelectedCard(breakthroughCard);
      return true;
    } else {
      log("Bot could not break through for a card.");
      return false;
    }
  }

  Future<bool> acquire(List<CardType> cardTypes) async {
    var acquireCard =
        await botCubit.requireCardFromUser(CardAcquireType.acquire, cardTypes);

    if (acquireCard.card != null) {
      addPlayerSelectedCard(acquireCard);
      log("Bot acquired: " + acquireCard.card!.name);
      return true;
    } else {
      log("Bot could not acquire card.");
      return false;
    }
  }

  playRegion(GameCard card) {
    pinnedCards.insert(0, card);
    cardsToBeRemovedFromPlayDeck.add(card);
    log("Bot played region " + card.name);
  }

  pinCard(GameCard card) {
    log("Bot pinned card  " + card.name);

    pinnedCards.insert(0, card);
  }

  addPlayerSelectedCard(PlayerSelectedCard card) {
    if (card.card == null) {
      return;
    }

    resolveIfKingOfKings(card.card as GameCard);

    drawPile.addCard(card.card as GameCard);

    if (card.takeUnrest) {
      drawPile.addCard(CardDatabase.basicUnrestCard);
      log("Bot takes unrest, for acquiring card " + card.card!.name);
    }

    progressTokens += card.progressTokens;
    materialTokens += card.materialTokens;
    populationTokens += card.populationTokens;
  }

  resolveIfKingOfKings(GameCard card) {
    if (card.name == "King of Kings") {
      if (stage == Stage.barbarian) {
        progressTokens += 6;
        log("Bot got King of Kings, but is in barbariage stage. Gains 6 progress tokens.");
      }
      if (stage == Stage.empire) {
        progressTokens += 3;
        isEndOfGameTriggered = true;
        botCubit.alertBotTriggeredEndOfGame("Bot received king of kings card");
      }

      return true;
    }
  }

  putCardInHistory(GameCard card) {
    log("Bot put " + card.name + " into history pile");

    cardsToBeRemovedFromPlayDeck.add(card);
    historyDeck.addCard(card);
  }

  discardTopCards(int cards) {
    for (int i = cards; i == 0; i--) {
      var card = drawCard();
      discardPile.addCard(card);

      log("Bot discarded " + card.name);
    }
  }

  gainPopulationForEveryRegion() {
    var amount = 0;
    for (var pinned in pinnedCards) {
      if (pinned.icons.contains(CardIcon.region)) {
        amount++;
      }
    }

    populationTokens += amount;

    log("bot gained " +
        amount.toString() +
        " population tokens for regions in play.");
  }

  gainMaterialForEveryRegion() {
    var amount = 0;
    for (var pinned in pinnedCards) {
      if (pinned.icons.contains(CardIcon.region)) {
        amount++;
      }
    }
    materialTokens += amount;
    log("bot gained " +
        populationTokens.toString() +
        " population tokens for regions in play.");
  }

  abandonPinnedCard(GameCard card) {
    pinnedCards.remove(card);
    discardPile.addCard(card);

    log("bot abandons " + card.name);
  }

  abandonPinnedRegions(int regionCount) {
    var abandonedCount = 0;
    for (var card in pinnedCards) {
      if (abandonedCount == regionCount) break;
      if (card.type == CardType.region) {
        abandonPinnedCard(card);
        abandonedCount++;
        log("bot abandons " + card.name);
      }
    }
  }

  void setupDrawPile(List<GameCard> cards) {
    drawPile = CardDeck(
        cards.where((card) => card.type == CardType.start).toList(),
        "(Bot) draw pile");

    drawPile.shuffle();
  }

  void setupDynastyDeck(List<GameCard> cards) {
    //setup dynasty deck
    var accessionCard =
        cards.firstWhere((card) => card.type == CardType.accession);

    var nationCards = CardDeck(
        cards.where((card) => card.type == CardType.nation).toList(),
        "Nation deck");

    var developmentCards = CardDeck(
        cards.where((card) => card.type == CardType.development).toList(),
        "Development deck");
    developmentCards.sortByVictoryPoints();
    nationCards.shuffle();

    dynastyDeck = CardDeck([], "(Bot) Dynasty deck");
    dynastyDeck.addDeck(developmentCards);
    dynastyDeck.addCard(accessionCard);
    dynastyDeck.addDeck(nationCards);
  }

  void cleanUp() {
    log("Bot does cleanup..");
    // Place cards at correct places from in play cards
    for (var card in cardsInPlay) {
      if (cardsToBeRemovedFromPlayDeck.contains(card)) {
        log("Bot does not add " + card.name + " to discard pile");
        removedCards.insert(0, card);
        continue;
      } else {
        discardPile.addCard(card);
      }
    }

    try {
      retainedCardInPlay = cardsInPlay[latestDiceRoll - 1];
    } catch (e) {
      retainedCardInPlay = null;
    }

    cardsInPlay = [];
    cardsToBeRemovedFromPlayDeck.clear();

    if (difficulty == Difficulty.warlord) {
      discardTopCards(1);
    }

    drawCardsToPlayArea();
  }

  void addCardToDiscardPile(GameCard card) {
    log("Bot adds card " + card.name + " to discard pile");
    discardPile.addCard(card);
  }

  void addCardsToDiscardPile(List<GameCard> cards) {
    for (var card in cards) {
      log("Bot adds card " + card.name + " to discard pile");
    }

    discardPile.addCards(cards);
  }

  //overridable methods

  void extraSetup() {}

  int rollDice(int sides) {
    var rng = Random();
    var result = 1 + rng.nextInt(sides - 1);
    return result;
  }

  Future<bool> resolveCard(GameCard card) async {
    return false;
  }

  Future<bool> addTokensToCard(int diceRoll) async {
    botCubit.requireUserAction("Add tokens to card",
        Text("Add 1 progress token to card in place " + diceRoll.toString()));
    return true;
  }

  Future<bool> basicBarbarianAction(GameCard card) async {
    return true;
  }

  Future<bool> basicEmpireAction(GameCard card) async {
    return true;
  }

  _getCardCountToPlayEachRound() {
    switch (difficulty) {
      case Difficulty.chieftain:
        return 4;
      case Difficulty.warlord:
        return 4;
      case Difficulty.imperator:
        return 5;
      case Difficulty.sovereign:
        return 5;
      case Difficulty.overlord:
        return 6;
    }
  }
}
