import 'package:flutter/rendering.dart';
import 'package:imperium_bot/models/card.dart';

class CardDeck {
  List<GameCard> _cards = [];
  String deckName;

  CardDeck(this._cards, this.deckName);

  GameCard draw() {
    var card = _cards.first;
    _cards.remove(card);

    return card;
  }

  GameCard removeCard(GameCard card) {
    var foundCard = _cards.firstWhere((deckCard) => deckCard == card);
    _cards.remove(card);
    return foundCard;
  }

  void sortByVictoryPoints() {
    _cards.sort((a, b) => a.victoryPoints.compareTo(b.victoryPoints));
  }

  void addCards(List<GameCard> cards) {
    _cards.addAll(cards);
  }

  void addCard(GameCard card) {
    _cards.insert(0, card);
  }

  void addDeck(CardDeck deck) {
    _cards.insertAll(0, deck.getCards());
  }

  void remove(GameCard card) {
    _cards.remove(card);
  }

  void shuffle() {
    _cards.shuffle();
  }

  void removeAllAbovePlayerCount(int playerCount) {
    _cards.removeWhere((card) => card.playerCount > playerCount);
  }

  int cardCount() {
    return _cards.length;
  }

  List<GameCard> getCards() {
    return _cards;
  }

  void print() {
    debugPrint("Cards in " + deckName + " deck");
    debugPrint("----------------------");
    for (var card in _cards) {
      debugPrint(card.name);
    }
    debugPrint("----------------------");
  }

  void removeAll() {
    _cards.clear();
  }
}
