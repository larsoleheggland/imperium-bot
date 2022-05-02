import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_number_picker/flutter_number_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/data/card-database.dart';
import 'package:imperium_bot/extensions/enum-extensions.dart';
import 'package:imperium_bot/models/card-enums.dart';
import 'package:imperium_bot/models/card.dart';
import 'package:imperium_bot/singleton/bloc-sigleton.dart';

class CardFormInput extends StatefulWidget {
  final CardAcquireType acquireType;
  final List<CardType> cardType;

  const CardFormInput(this.acquireType, this.cardType, {Key? key})
      : super(key: key);

  @override
  _CardFormInputState createState() =>
      _CardFormInputState(acquireType, cardType);
}

class _CardFormInputState extends State<CardFormInput> {
  final CardAcquireType acquireType;
  final List<CardType> cardTypes;

  final textController = TextEditingController();
  BotCubit botCubit = BlocSingletons.botCubit;

  late GameCard? selectedCard;
  late bool shouldTakeUnrest;
  bool hasFoundCard = false;
  String searchText = "";

  int materialTokens = 0;
  int progressTokens = 0;

  _CardFormInputState(this.acquireType, this.cardTypes) {
    shouldTakeUnrest = acquireType == CardAcquireType.acquire;

    if (cardTypes.contains(CardType.region)) {
      shouldTakeUnrest = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot requires card'),
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
    return RichText(
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
    );
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
            _generateTokenInputs(),
            if (acquireType == CardAcquireType.acquire)
              CheckboxListTile(
                title: Text(
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
                const SizedBox(width: 20),
                ElevatedButton(
                    onPressed: () {
                      _onNotPossible();
                    },
                    child: const Text("Can't acquire card")),
              ],
            ),
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
        Divider(height: 20),
        ElevatedButton(
            onPressed: () {
              _onNotPossible();
            },
            child: const Text("Can't acquire card")),
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
              initialValue: 0,
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
              initialValue: 0,
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
