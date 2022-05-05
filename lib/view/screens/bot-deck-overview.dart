import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/view/widgets/card-deck-list.dart';

class BotDeckOverviewScreen extends StatefulWidget {
  BotCubit botCubit;

  BotDeckOverviewScreen(this.botCubit);

  @override
  State<StatefulWidget> createState() =>
      _BotDeckOverviewScreenState(this.botCubit);
}

class _BotDeckOverviewScreenState extends State<BotDeckOverviewScreen> {
  BotCubit botCubit;

  _BotDeckOverviewScreenState(this.botCubit);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot deck'),
      ),
      backgroundColor: Colors.black87,
      body: SingleChildScrollView(
        child: Container(
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              children: [
                // Actions
                Row(
                  children: [
                    ElevatedButton(
                        onPressed: _botDrawCard, child: Text("Draw bot card"))
                  ],
                ),

                // Cards in play

                _generatePlayedCards(),

                // Pinned cards
                _generatePinnedCards(),
                //Decks

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Draw pile"),
                        ),
                        CardDeckList(
                          botCubit,
                          botCubit.bot.drawPile.getCards(),
                          compact: true,
                        ),
                      ],
                    ),
                    Spacer(),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Discard pile"),
                        ),
                        CardDeckList(
                          botCubit,
                          botCubit.bot.discardPile.getCards(),
                          compact: true,
                        ),
                      ],
                    ),
                    Spacer(),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Dynasty deck"),
                        ),
                        CardDeckList(
                          botCubit,
                          botCubit.bot.dynastyDeck.getCards(),
                          compact: true,
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _generatePinnedCards() {
    var cards = botCubit.bot.pinnedCards;
    return Container();
  }

  _generatePlayedCards() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: _generatePlayedCard(),
        ),
      ),
    );
  }

  List<Widget> _generatePlayedCard() {
    List<Widget> result = [];
    result.add(Spacer());
    for (var card in botCubit.bot.cardsInPlay) {
      result.add(
          Text(truncate(card.name), style: GoogleFonts.roboto(fontSize: 10)));
      result.add(Spacer());
    }
    return result;
  }

  String truncate(String text, {length = 10, omission = '..'}) {
    if (length >= text.length) {
      return text;
    }
    return text.replaceRange(length, text.length, omission);
  }

  _botDrawCard() {
    var card = botCubit.bot.drawAndDiscard();

    setState(() {});
  }
}
