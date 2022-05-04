import 'dart:collection';
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

  //BotCubit botCubit = BlocSingletons.botCubit;
  Stage stage = Stage.barbarian;

  bool isEndOfGameTriggered = false;
  bool hasGameEnded = false;
  int roundsSinceGameEndTriggered = 0;

  late BotCubit botCubit;
  late List<GameCard> pinnedCards = [];
  late CardDeck drawPile;
  late CardDeck discardPile;
  late CardDeck dynastyDeck;
  late CardDeck historyDeck;
  late LinkedHashMap<int, GameCard> cardsInPlay;

  late List<GameCard> cardsToBeRemovedFromPlayDeck;

  Bot(this.faction, this.difficulty);

  void initialize(BotCubit cubit) async {
    var cards = await CardParser.parseFile(
        faction.toShortString(), CardCategory.faction);

    botCubit = cubit;
    cardsToBeRemovedFromPlayDeck = [];
    historyDeck = CardDeck([], "(Bot) History Deck");
    discardPile = CardDeck([], "(Bot) Discard Pile");
    cardsInPlay = LinkedHashMap<int, GameCard>();

    CardDatabase.all.addAll(cards);

    setupDrawPile(cards);
    setupDynastyDeck(cards);
    drawCardsToPlayArea();

    extraSetup();
  }

  void log(String text, {BotLogEntryType entryType = BotLogEntryType.info}) {
    botLog.add(BotLogEntry(text, type: entryType));
  }

  Future<bool> playTurn() async {
    var diceRoll = rollDice(6);
    var index = 1;
    for (var card in cardsInPlay.values) {
      if (diceRoll != index) {
        //priority cards = unrest, king of kings etc.
        var resolvedPriorityCard = await resolvePriorityCards(card);

        if (!resolvedPriorityCard) {
          await resolveCard(card);
        }
      }
      index++;
    }

    if (diceRoll != 6) {
      addTokensToCard(diceRoll);
    }

    cleanUp(diceRoll);

    if (isEndOfGameTriggered) {
      if (roundsSinceGameEndTriggered == 1) {
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
    for (var i = 0; i < 5; i++) {
      //Don't overwrite existing card from last round.

      if (cardsInPlay.containsKey(i)) continue;
      var card = drawCard();
      log("Bot adds card " + card.name + " to play area");
      cardsInPlay[i] = card;
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
    if (dynastyDeck.cardCount() == 0) {
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

  GameCard? recallRegion() {
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
    scoringCards.addAll(cardsInPlay.values);
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
    dynastyDeck.addDeck(nationCards);
    dynastyDeck.addCard(accessionCard);
    dynastyDeck.addDeck(developmentCards);
  }

  void cleanUp(int diceRoll) {
    log("Bot does cleanup");
    var removedCards = cardsToBeRemovedFromPlayDeck;
    var cards = cardsInPlay.values;

    // Place cards at correct places from in play cards
    for (var card in cards) {
      if (removedCards.contains(card)) {
        log("Bot does not add " + card.name + " to discard pile");
        continue;
      } else {
        discardPile.addCard(card);
      }
    }

    // Deal with retained card (if any)
    var retainedCard = cardsInPlay[diceRoll - 1];
    cardsInPlay = LinkedHashMap<int, GameCard>();

    if (retainedCard != null) {
      cardsInPlay[diceRoll - 1] = retainedCard;
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
}
