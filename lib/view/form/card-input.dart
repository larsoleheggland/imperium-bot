import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/data/card-database.dart';
import 'package:imperium_bot/extensions/enum-extensions.dart';
import 'package:imperium_bot/models/card-enums.dart';
import 'package:imperium_bot/models/card.dart';
import 'package:imperium_bot/view/widgets/custom-number-picker.dart';

class CardFormInput extends StatefulWidget {
  final CardAcquireType acquireType;
  final List<CardType> cardType;
  BotCubit botCubit;

  CardFormInput(this.botCubit, this.acquireType, this.cardType, {Key? key})
      : super(key: key);

  @override
  _CardFormInputState createState() =>
      _CardFormInputState(botCubit, acquireType, cardType);
}

class _CardFormInputState extends State<CardFormInput> {
  final CardAcquireType acquireType;
  final List<CardType> cardTypes;

  final textController = TextEditingController();
  BotCubit botCubit;

  late GameCard? selectedCard;
  late bool shouldTakeUnrest;
  bool hasFoundCard = false;
  String searchText = "";

  int materialTokens = 0;
  int progressTokens = 0;

  bool showExtraInfo = false;

  _CardFormInputState(this.botCubit, this.acquireType, this.cardTypes) {
    shouldTakeUnrest = acquireType == CardAcquireType.acquire;

    if (cardTypes.contains(CardType.region)) {
      shouldTakeUnrest = false;
    }

    if (cardTypes.contains(CardType.fame)) {
      shouldTakeUnrest = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot requires card'),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.black54,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              _generateUserDirections(),
              TextField(
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    focusColor: Colors.white,
                    hoverColor: Colors.white,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    hintText: "Enter a card name",
                    hintStyle: TextStyle(color: Colors.white70),
                    labelText: "Card name",
                    labelStyle: TextStyle(color: Colors.white70)),
                onChanged: (text) {
                  setState(() {
                    searchText = text;
                  });
                  _searchCards(text);
                },
                controller: textController,
              ),
              generateSearchResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _generateUserDirections() {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14.0,
            ),
            children: <TextSpan>[
              const TextSpan(text: 'The bot is '),
              if (acquireType == CardAcquireType.acquire)
                const TextSpan(
                    text: 'aqcuiring ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              if (acquireType == CardAcquireType.breakthrough)
                const TextSpan(
                    text: 'breaking through for ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: "a "),
              for (var type in _generateTypeList()) type,
            ],
          ),
        ),
      ],
    );
  }

  _showExtraRulesInfo() {
    if (showExtraInfo) {
      return Column(children: const [
        SizedBox(height: 10),
        Text(
            "After picking card, put card aside. Add eventual unrest card either to bot unrest pile (if acquiring) or market unrest pile (if breaking through)",
            style: TextStyle(fontSize: 13)),
        SizedBox(height: 10),
        Text(
            "Bot always chooses card with the most victory points. If tie, choose the one with most tokens. If still a tie, choose lowest number. ",
            style: TextStyle(fontSize: 13)),
        SizedBox(height: 10),
      ]);
    } else {
      return Center(
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(primary: Colors.blue),
            onPressed: () {
              setState(() {
                showExtraInfo = true;
              });
            },
            child: const Text("See rules, and explanation")),
      );
    }
  }

  List<TextSpan> _generateTypeList() {
    List<TextSpan> result = [];

    var index = 0;
    for (var type in cardTypes) {
      if (type == CardType.uncivilisedCivilised) {
        result.add(const TextSpan(text: "civilised / uncivilised"));
      } else {
        result.add(TextSpan(text: type.toShortString()));
      }

      if (index != cardTypes.length - 1) {
        result.add(const TextSpan(text: " or "));
      } else {
        result.add(const TextSpan(text: " card."));
      }

      index++;
    }

    return result;
  }

  Widget generateSearchResult() {
    if (hasFoundCard && searchText != "") {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(selectedCard?.name ?? "",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 27)),
            ),
            Divider(height: 20, color: Colors.white54),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(primary: Colors.green),
                    onPressed: () {
                      _onConfirmCard();
                    },
                    child: const Text("Confirm card")),
              ],
            ),
            _generateTokenInputs(),
            if (acquireType == CardAcquireType.acquire)
              CheckboxListTile(
                title: const Text(
                  "Should take unrest?",
                  style: TextStyle(color: Colors.white),
                ),
                side: MaterialStateBorderSide.resolveWith(
                  (states) => BorderSide(width: 1.0, color: Colors.white),
                ),
                value: shouldTakeUnrest,
                tileColor: Colors.transparent,
                onChanged: (newValue) {
                  setState(() {
                    shouldTakeUnrest = newValue as bool;
                  });
                },
                controlAffinity:
                    ListTileControlAffinity.leading, //  <-- leading Checkbox
              ),
            const Divider(height: 20, color: Colors.white54),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("No cards found."),
        ),
        const Divider(height: 20),
        ElevatedButton(
            onPressed: () {
              _onNotPossible();
            },
            child: const Text("Can't acquire card")),
        const Divider(height: 20),
        _showExtraRulesInfo()
      ],
    );
  }

  _searchCards(String text) {
    if (text == "") {
      setState(() {
        hasFoundCard = false;
      });
    }

    List<GameCard> cards =
        CardDatabase.all.where((x) => cardTypes.contains(x.type)).toList();
    debugPrint(textController.text);
    try {
      GameCard cardSearchResult = cards
          .where((card) => card.name
              .toLowerCase()
              .startsWith(textController.text.toLowerCase()))
          .first;

      if (cardSearchResult != null) {
        setState(() {
          hasFoundCard = true;
          selectedCard = cardSearchResult;
        });
      }
    } catch (e) {
      setState(() {
        hasFoundCard = false;
      });
    }
  }

  Widget _numberPickerButton(IconData sign) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FaIcon(sign, size: 18, color: Colors.white),
    );
  }

  Widget _generateTokenInputs() {
    return Row(
      children: [
        //Progress tokens
        Column(
          children: [
            Text("Progress tokens"),
            CustomNumberPicker(
              value: 0,
              maxValue: 20,
              minValue: 0,
              step: 1,
              customAddButton: _numberPickerButton(FontAwesomeIcons.plus),
              customMinusButton: _numberPickerButton(FontAwesomeIcons.minus),
              onValue: (value) {
                progressTokens = value as int;
              },
            ),
          ],
        ),

        Spacer(),

        // material tokens
        Column(
          children: [
            Text("Material tokens"),
            CustomNumberPicker(
              value: 0,
              maxValue: 20,
              minValue: 0,
              step: 1,
              customAddButton: _numberPickerButton(FontAwesomeIcons.plus),
              customMinusButton: _numberPickerButton(FontAwesomeIcons.minus),
              onValue: (value) {
                materialTokens = value as int;
              },
            ),
          ],
        ),
      ],
    );
  }

  _onConfirmCard() {
    var playerSelectedCard = PlayerSelectedCard(selectedCard as GameCard,
        progressTokens, materialTokens, 0, shouldTakeUnrest);
    botCubit.selectUserCard(playerSelectedCard);

    Navigator.of(context).maybePop();
  }

  _onNotPossible() {
    var playerSelectedCard = PlayerSelectedCard(null, 0, 0, 0, false);
    botCubit.selectUserCard(playerSelectedCard);

    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    textController.dispose();
    super.dispose();
  }
}
