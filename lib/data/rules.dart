class Rules {
  String exile =
      '''If the bot exiles a card from the market, it places the eligible card from the lowest-numbered
  slot in the market in the exile pile.
  The bot will never exile a card with one or more tokens on it. If all cards in the market
  have tokens on them, it does not exile a card.''';

  String recall =
      '''If the bot recalls a card, put one of its region cards in play on top of the bot deck. If there
are multiple in play, the bot recalls the one that was most recently played.''';
}
