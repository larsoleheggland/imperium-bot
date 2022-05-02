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

  List<BotLogEntry> botLog = [];

  int materialTokens = 0;
  int populationTokens = 0;
  int progressTokens = 0;

  int diceRoll = 0;

  //BotCubit botCubit = BlocSingletons.botCubit;
  Stage stage = Stage.barbarian;

  late BotCubit botCubit;
  late List<GameCard> pinnedCards = [];
  late CardDeck drawPile;
  late CardDeck discardPile;
  late CardDeck dynastyDeck;
  late CardDeck historyDeck;
  late CardDeck cardsInPlay;

  late List<GameCard> cardsToBeRemovedFromPlayDeck;

  Bot(this.faction, this.difficulty);

  void initialize(BotCubit cubit) async {
    var cards = await CardParser.parseFile(
        faction.toShortString(), CardCategory.faction);

    botCubit = cubit;
    cardsToBeRemovedFromPlayDeck = [];
    historyDeck = CardDeck([], "(Bot) History Deck");
    discardPile = CardDeck([], "(Bot) Discard Pile");
    cardsInPlay = CardDeck([], "(Bot) Market cards");

    CardDatabase.all.addAll(cards);

    setupDrawPile(cards);
    setupDynastyDeck(cards);
    drawCardsToPlayArea();

    extraSetup();
  }

  void log(String text, {BotLogEntryType entryType = BotLogEntryType.info}) {
    botLog.add(BotLogEntry(text, type: entryType));
  }

  void playTurn() async {
    diceRoll = rollDice(6);
    var index = 1;
    for (var card in cardsInPlay.getCards()) {
      if (diceRoll != index) {
        await resolveCard(card);
      }
      index++;
    }

    addTokensToCard();
    cleanUp();
  }

  void drawCardsToPlayArea() {
    var count = cardsInPlay.cardCount();
    while (cardsInPlay.cardCount() < 5) {
      var card = drawCard();
      log("Bot adds card " + card.name + " to play area");
      cardsInPlay.addCard(card);
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
    var dynastyCard = dynastyDeck.draw();
    log("Dynasty card added: " + dynastyCard.name);
    if (dynastyCard.IsType(CardType.accession)) {
      log("Dynasty card was an accession card, and bot entered empire stage");
      stage = Stage.empire;
    }

    discardPile.addCard(dynastyCard);

    log("Shuffling discard pile..");
    discardPile.shuffle();
    log("Adds cards to draw deck..");
    drawPile.addCards(discardPile.getCards());
    discardPile.removeAll();

    var card = drawPile.draw();
    log("Bot draws " + card.name);
    return card;
  }

  GameCard drawAndDiscard() {
    var card = drawCard();
    discardPile.addCard(card);

    return card;
  }

  GameCard? abandonRegion() {
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

  int getScore() {
    var score = 0;
    List<GameCard> scoringCards = [];
    scoringCards.addAll(cardsInPlay.getCards());
    scoringCards.addAll(drawPile.getCards());
    scoringCards.addAll(discardPile.getCards());
    scoringCards.addAll(historyDeck.getCards());
    scoringCards.addAll(pinnedCards);

    score += progressTokens;

    var pointsForTokens = (materialTokens + populationTokens) / 10;
    score += pointsForTokens.floor();

    for (var card in scoringCards) {
      score += card.victoryPoints;
    }

    return score;
  }

  int getPinnedRegionCount() {
    var pinnedRegions = 0;

    for (var pinned in pinnedCards) {
      if (pinned.type == CardType.region) {
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
    pinnedCards.add(card);
    cardsToBeRemovedFromPlayDeck.add(card);
    log("Bot played region " + card.name);
  }

  pinCard(GameCard card) {
    log("Bot pinned card  " + card.name);

    pinnedCards.add(card);
  }

  addPlayerSelectedCard(PlayerSelectedCard card) {
    if (card.card == null) {
      return;
    }

    drawPile.addCard(card.card as GameCard);

    if (card.takeUnrest) {
      log("Bot takes unrest, for acquiring card " + card.card!.name);
    }

    progressTokens += card.progressTokens;
    materialTokens += card.materialTokens;
    populationTokens += card.populationTokens;
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
    dynastyDeck.addDeck(nationCards);
    dynastyDeck.addCard(accessionCard);
    dynastyDeck.addDeck(developmentCards);
  }

  void cleanUp() {
    log("Bot does cleanup");
    var removedCards = cardsToBeRemovedFromPlayDeck;
    var cards = cardsInPlay.getCards();
    for (var card in cards) {
      if (removedCards.contains(card)) {
        log("Bot does not add " + card.name + " to discard pile");
        continue;
      } else {
        discardPile.addCard(card);
      }
    }

    cardsInPlay.removeAll();
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

  Future<bool> addTokensToCard() async {
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
}
