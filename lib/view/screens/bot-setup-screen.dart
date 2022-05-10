import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/extensions/enum-extensions.dart';
import 'package:imperium_bot/extensions/string-extensions.dart';
import 'package:imperium_bot/models/card-enums.dart';

class BotSetupScreen extends StatefulWidget {
  Function(BotCubit) setBotFunction;

  BotSetupScreen(this.setBotFunction);

  @override
  State<StatefulWidget> createState() => _BotSetupScreenState(setBotFunction);
}

enum BotSetupStage { factionSelection, difficultySelection }

class _BotSetupScreenState extends State<BotSetupScreen> {
  Function(BotCubit) setBotFunction;

  late Faction selectedFaction;
  late Difficulty selectedDifficulty;

  BotSetupStage setupStage = BotSetupStage.factionSelection;
  _BotSetupScreenState(this.setBotFunction);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_getTitle()),
      ),
      backgroundColor: Colors.black26,
      body: SingleChildScrollView(
        child: Container(
          child: _generateSetup(),
        ),
      ),
    );
  }

  Widget _generateSetup() {
    if (setupStage == BotSetupStage.factionSelection) {
      return _generateSelectFaction();
    }
    if (setupStage == BotSetupStage.difficultySelection) {
      return _generateDifficultySelection();
    }

    return Container();
  }

  Widget _generateDifficultySelection() {
    return Column(
      children: _generateSelectDifficulty(),
    );
  }

  List<Widget> _generateSelectDifficulty() {
    List<Widget> result = [];
    for (var difficulty in Difficulty.values) {
      result.add(_generateSelectDifficultyCard(difficulty));
    }
    return result;
  }

  Widget _generateSelectDifficultyCard(Difficulty difficulty) {
    return GestureDetector(
      onTapUp: (e) {
        setupStage = BotSetupStage.difficultySelection;
        selectedDifficulty = difficulty;

        var bot = BotCubit(selectedFaction, selectedDifficulty);
        setBotFunction(bot);
        Navigator.of(context).maybePop();
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.all(Radius.circular(10)),
            color: _getDifficultyColor(difficulty),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(difficulty.toShortString().capitalize()),
                  SizedBox(height: 5),
                  _generateStars(_getDifficultyStarCount(difficulty)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _generateStars(int count) {
    List<Widget> result = [];
    for (int i = 0; i < count; i++) {
      result.add(
          FaIcon(FontAwesomeIcons.solidStar, color: Colors.yellow, size: 16));
    }

    for (int i = 0; i < 5 - count; i++) {
      result.add(FaIcon(FontAwesomeIcons.star, size: 16));
    }

    return Row(children: result);
  }

  int _getDifficultyStarCount(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.chieftain:
        return 1;
      case Difficulty.warlord:
        return 2;
      case Difficulty.imperator:
        return 3;
      case Difficulty.sovereign:
        return 4;
      case Difficulty.overlord:
        return 5;
    }

    return 0;
  }

  Widget _generateSelectFaction() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text("Available factions"),
          Column(children: _generateImplementedFactionList()),
          Text("Unavailable factions"),
          Column(children: _generateUnimplementedFactionList()),
        ],
      ),
    );
  }

  List<Widget> _generateImplementedFactionList() {
    List<Widget> result = [];
    for (var value in Faction.values) {
      if (_implementedFactions().contains(value)) {
        result.add(_generateFactionCard(value));
      }
    }

    return result;
  }

  List<Widget> _generateUnimplementedFactionList() {
    List<Widget> result = [];
    for (var value in Faction.values) {
      if (!_implementedFactions().contains(value)) {
        result.add(_generateFactionCard(value));
      }
    }

    return result;
  }

  Widget _generateFactionCard(Faction faction) {
    return GestureDetector(
      onTapUp: (e) {
        if (_implementedFactions().contains(faction)) {
          setupStage = BotSetupStage.difficultySelection;
          selectedFaction = faction;
          setState(() {});
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: double.infinity,
          height: 75,
          decoration: BoxDecoration(
              color: _getFactionColor(faction),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(10))),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: Text(faction.toShortString().capitalize())),
          ),
        ),
      ),
    );
  }

  Color _getFactionColor(Faction faction) {
    switch (faction) {
      case Faction.carthaginians:
        return Colors.blue;
    }

    return Colors.white12;
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    return Colors.white24;

    switch (difficulty) {
      case Difficulty.chieftain:
        return Colors.lightGreen;
      case Difficulty.warlord:
        return Colors.green;
      case Difficulty.imperator:
        return Colors.yellow;
      case Difficulty.sovereign:
        return Colors.red;
      case Difficulty.overlord:
        return Colors.deepPurple;
    }
    return Colors.red;
  }

  String _getTitle() {
    if (setupStage == BotSetupStage.factionSelection) {
      return "Faction selection";
    }

    if (setupStage == BotSetupStage.difficultySelection) {
      return "Difficulty selection";
    }

    throw Exception("_getTitle() in bot selection failed. ");
  }

  List<Faction> _implementedFactions() => <Faction>[Faction.carthaginians];
}
