import 'package:flutter/material.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/extensions/enum-extensions.dart';
import 'package:imperium_bot/models/bot-log-entry.dart';
import 'package:imperium_bot/singleton/bloc-sigleton.dart';

class BotDiagnosticsScreen extends StatefulWidget {
  BotCubit botCubit;

  BotDiagnosticsScreen(this.botCubit);

  @override
  State<StatefulWidget> createState() => _BotDiagnosticsState(this.botCubit);
}

class _BotDiagnosticsState extends State<BotDiagnosticsScreen> {
  BotCubit botCubit;

  _BotDiagnosticsState(this.botCubit);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot diagnostics'),
      ),
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _generateBotInfo(),
                _generateBotLog(),
                ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: Text("Update"))
              ],
            ),
          ),
        ),
      ),
    );
    return _generateBotInfo();
  }

  Widget _generateBotLog() {
    List<Widget> logItems = [];

    for (var entry in botCubit.bot.botLog) {
      if (entry.type == BotLogEntryType.playCard) {
        logItems.add(Text(entry.text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.blue)));
      }

      logItems.add(Text(entry.text));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text("Bot log"),
          Container(
            height: 300,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: logItems)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _generateBotInfo() {
    try {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: new Column(
          children: [
            Text("Material tokens: " + botCubit.bot.materialTokens.toString()),
            Text("population tokens: " +
                botCubit.bot.populationTokens.toString()),
            Text("progress tokens: " + botCubit.bot.progressTokens.toString()),
            Divider(height: 10, color: Colors.white54),
            Text("Cards in draw pile: " +
                botCubit.bot.drawPile.cardCount().toString()),
            Text("Cards in discard pile: " +
                botCubit.bot.discardPile.cardCount().toString()),
            Text("Cards in dynasty deck: " +
                botCubit.bot.dynastyDeck.cardCount().toString()),
            Text("Cards in play: " +
                botCubit.bot.cardsInPlay.values.length.toString()),
            Text("Cards in history: " +
                botCubit.bot.historyDeck.cardCount().toString()),
            Text("Pinned cards: " + botCubit.bot.pinnedCards.length.toString()),
            Text("Regions: " + botCubit.bot.getPinnedRegionCount().toString()),
            Divider(height: 10, color: Colors.white54),
            Text("Stage: " + botCubit.bot.stage.toShortString()),
            Text("Score: " + botCubit.bot.getScore().toString()),
          ],
        ),
      );
    } catch (e) {
      return Text("Bot not initialized");
    }
  }
}
