import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/extensions/enum-extensions.dart';
import 'package:imperium_bot/models/card.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class PinnedCardDeckList extends StatefulWidget {
  BotCubit botCubit;
  List<GameCard> cards;
  bool compact;

  PinnedCardDeckList(this.botCubit, this.cards, {this.compact = false});

  @override
  State<StatefulWidget> createState() =>
      _PinnedCardDeckListState(this.botCubit, cards, compact: compact);
}

class _PinnedCardDeckListState extends State<PinnedCardDeckList> {
  BotCubit botCubit;
  List<GameCard> cards;
  bool compact;
  _PinnedCardDeckListState(this.botCubit, this.cards, {this.compact = false});

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
      result.add(SizedBox(height: 5));
    }

    return result;
  }

  TextStyle _getTextStyle({double fontSize = 20.0, color = Colors.black}) {
    return GoogleFonts.roboto(
      color: color,
      fontSize: fontSize,
    );
  }

  Widget _generateCard(GameCard card) {
    var width = MediaQuery.of(context).size.width - 16;
    return Container(
      width: width,
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
              _generateActionButtons(card),
            ],
          )),
    );
  }

  Widget _generateActionButtons(GameCard card) {
    if (compact) {
      return Container();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        TextButton(
          child: const Text('Abandon'),
          onPressed: () {
            _onAbandon(card);
          },
        ),
        const SizedBox(width: 8),
        TextButton(
          child: const Text('Recall'),
          onPressed: () {
            _onRecall(card);
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  _onAbandon(GameCard card) {
    var region = botCubit.bot.abandonRegion(card: card);
    if (region != null) {
      showTopSnackBar(
        context,
        CustomSnackBar.success(
          message: "Bot recalled region " + region.name,
        ),
      );
    }
    setState(() {});
  }

  _onRecall(GameCard card) {
    var region = botCubit.bot.recallRegion(card: card);
    if (region != null) {
      showTopSnackBar(
        context,
        CustomSnackBar.success(
          message: "Bot recalled region " + region.name,
        ),
      );
    }
    setState(() {});
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
