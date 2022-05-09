import 'package:flutter/material.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/extensions/enum-extensions.dart';
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
  late String title = _getTitle();
  _BotSetupScreenState(this.setBotFunction);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(title),
      ),
      backgroundColor: Colors.black87,
      body: Container(
        child: _generateSetup(),
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
          height: 75,
          decoration: BoxDecoration(
            color: _getDifficultyColor(difficulty),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(difficulty.toShortString()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _generateSelectFaction() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text("Available factions"),
          Column(children: _generateImplematedFactionList()),
          Text("Unvailable factions"),
          Column(children: _generateUnimplementedFactionList()),
        ],
      ),
    );
  }

  List<Widget> _generateImplematedFactionList() {
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
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(faction.toShortString()),
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

    return Colors.grey;
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
      return "Faction selection";
    }

    throw Exception("_getTitle() in bot selection failed. ");
  }

  List<Faction> _implementedFactions() => <Faction>[Faction.carthaginians];
}
