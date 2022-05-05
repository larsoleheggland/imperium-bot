import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/extensions/enum-extensions.dart';
import 'package:imperium_bot/models/card.dart';

class CardDeckList extends StatefulWidget {
  BotCubit botCubit;
  List<GameCard> cards;
  bool compact;

  CardDeckList(this.botCubit, this.cards, {this.compact = false});

  @override
  State<StatefulWidget> createState() =>
      _CardDeckListState(this.botCubit, cards, compact: compact);
}

class _CardDeckListState extends State<CardDeckList> {
  BotCubit botCubit;
  List<GameCard> cards;
  bool compact;
  _CardDeckListState(this.botCubit, this.cards, {this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _generateCardOverview(cards),
    );
  }

  List<Widget> _generateCardOverview(List<GameCard> cards) {
    List<Widget> result = [];

    for (var card in cards) {
      result.add(_generateCard(card));
      result.add(SizedBox(height: 2));
    }

    return result;
  }

  TextStyle _getTextStyle({double fontSize = 15.0, color = Colors.black}) {
    return GoogleFonts.roboto(
      color: color,
      fontSize: fontSize,
    );
  }

  Widget _generateCard(GameCard card) {
    return Container(
      width: 120,
      child: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: _getTextStyle(),
                      ),
                      Text(_generateIconString(card),
                          style: _getTextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ))
                    ]),
              ),
              _generateFullCard(),
            ],
          )),
    );
  }

  Widget _generateFullCard() {
    if (compact) {
      return Container();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        TextButton(
          child: const Text('Abandon'),
          onPressed: () {/* ... */},
        ),
        const SizedBox(width: 8),
        TextButton(
          child: const Text('Recall'),
          onPressed: () {/* ... */},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  String _generateIconString(GameCard card) {
    var iconString = "";
    var index = 0;
    for (var icon in card.icons) {
      iconString += icon.toShortString();
      if (card.icons[index] != card.icons.last) {
        iconString += ", ";
      }
      index++;
    }
    return iconString;
  }
}
