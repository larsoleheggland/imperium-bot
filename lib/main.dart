import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/data/card-database.dart';
import 'package:imperium_bot/extensions/enum-extensions.dart';
import 'package:imperium_bot/extensions/string-extensions.dart';
import 'package:imperium_bot/theme/custom-colors.dart';
import 'package:imperium_bot/view/screens/bot-deck-overview.dart';
import 'package:imperium_bot/view/screens/bot-diagnostics-screen.dart';
import 'package:imperium_bot/view/screens/card-input.dart';
import 'package:imperium_bot/view/screens/pinned-cards-overview-screen.dart';
import 'package:imperium_bot/view/widgets/token-inputs.dart';
import 'package:imperium_bot/view/widgets/user-action-required.dart';
import 'package:imperium_bot/view/widgets/user-messages-overlay.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import 'view/screens/bot-setup-screen.dart';
import 'view/widgets/big-button.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Imperium bot',
      theme: ThemeData(
        primarySwatch: Colors.red,
        textTheme: GoogleFonts.macondoTextTheme(
          const TextTheme(
            bodyText1: TextStyle(fontSize: 21),
            bodyText2: TextStyle(fontSize: 19),
          ).apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
      ),
      home: const App(title: 'Imperium'),
    );
  }
}

class App extends StatefulWidget {
  const App({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  String lastEvent = "";
  BotCubit? botCubit;
  bool isSettingUp = false;

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      CardDatabase.initialize();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (botCubit == null) {
      if (!isSettingUp) {
        setupBotCubit();
      }
      return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/background.png"),
              fit: BoxFit.cover,
            ),
          ));
    }

    return Scaffold(
      body: Center(
        child: BlocBuilder<BotCubit, BotState>(
            bloc: getBotCubit(),
            builder: (context, state) {
              if (lastEvent != state.hashCode.toString()) {
                if (state is BotRequestCard) {
                  _requireCard(state, context);
                }
                if (state is BotRequestUserAction) {
                  _requireUserAction(state, context);
                }
              }

              lastEvent = state.hashCode.toString();

              return Container(
                height: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/background.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Spacer(),
                      if (getBotCubit().bot.isEndOfGameTriggered)
                        endOfGameTriggeredMessage(),
                      generateBotButtons(context, state),
                      Divider(height: 20),
                      TokenInputs(this.getBotCubit()),
                      SizedBox(height: 30),
                      Center(
                          child: ElevatedButton(
                              onPressed: () {
                                getBotCubit().bot.isEndOfGameTriggered = true;
                                setState(() {});
                              },
                              child: Text("Trigger end of game"))),
                      Divider(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                              onPressed: () {
                                reset();
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                  primary: CustomColors.brown),
                              child: Text("Reset")),
                          SizedBox(width: 20),
                          ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _openBotDiagnostics();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                  primary: CustomColors.brown),
                              child: Text("Open bot diagnostics")),
                        ],
                      ),
                      Spacer(),
                      _generateBotInfo(),
                    ]),
              );
            }),
      ),
    );
  }

  _generateBotInfo() {
    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
            child: Text(
                "Playing against " +
                    getBotCubit().bot.faction.toShortString().capitalize() +
                    " (" +
                    getBotCubit().bot.difficulty.toShortString().capitalize() +
                    ")",
                style: TextStyle(fontSize: 15))),
      ),
    );
  }

  void reset() {
    setState(() {
      botCubit = null;
    });
  }

  BotCubit getBotCubit() {
    return botCubit as BotCubit;
  }

  void setupBotCubit() {
    if (botCubit == null) {
      isSettingUp = true;
      Future.microtask(() => Navigator.push(
            context,
            UserMessagesOverlay(BotSetupScreen(_setBotCubit)),
          ));
    }
  }

  _setBotCubit(BotCubit setupBotCubit) {
    isSettingUp = false;
    setState(() {
      botCubit = setupBotCubit;
    });
  }

  Widget endOfGameTriggeredMessage() {
    if (getBotCubit().bot.hasGameEnded) {
      return Container();
    }

    return Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: Colors.black87),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
              child: Text("Game end has been triggered. Take one more turn.")),
        ));
  }

  generateBotButtons(BuildContext context, BotState state) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!getBotCubit().bot.hasGameEnded)
            BigButton(
              "Take bot turn",
              CustomColors.red,
              _takeBotTurn,
              height: 100,
            ),
          if (getBotCubit().bot.hasGameEnded)
            BigButton(
              "Go to scoring",
              CustomColors.red,
              _goToScoring,
              height: 100,
            ),
          SizedBox(height: 10),
          Row(
            //addUnrestAndAlertUser()
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  child: BigButton(
                      "Pinned cards", Colors.black87, _openPinnedCardOverview)),
              SizedBox(width: 10),
              Expanded(
                  child: BigButton("Bot deck", Colors.black87, _openBotDeck)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            //addUnrestAndAlertUser()
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  child: BigButton("Draw card", Colors.black87, _botDrawCard)),
              SizedBox(width: 10),
              Expanded(
                  child: BigButton("Give unrest", Colors.black87,
                      getBotCubit().alertBotAddingUnrest)),
            ],
          ),
        ],
      ),
    );
  }

  _openPinnedCardOverview() {
    Future.microtask(() => Navigator.push(
          context,
          UserMessagesOverlay(PinnedCardsOverviewScreen(getBotCubit())),
        ));
  }

  _openBotDeck() {
    Future.microtask(() => Navigator.push(
          context,
          UserMessagesOverlay(BotDeckOverviewScreen(getBotCubit())),
        ));
  }

  _botDrawCard() {
    var card = getBotCubit().bot.drawAndDiscard();
    showTopSnackBar(
      context,
      CustomSnackBar.success(
        message: "Bot added " + card.name + " to discard pile.",
      ),
    );
  }

  _requireCard(BotRequestCard state, context) {
    Future.microtask(() => Navigator.push(
          context,
          UserMessagesOverlay(CardFormInputScreen(
              getBotCubit(), state.acquireType, state.cardType)),
        ));
  }

  _requireUserAction(BotRequestUserAction state, context) {
    Future.microtask(() => Navigator.push(
          context,
          UserMessagesOverlay(RequiredUserAction(
              getBotCubit(), state.title, state.userDirections)),
        ));
  }

  _openBotDiagnostics() {
    Future.microtask(() => Navigator.push(
          context,
          UserMessagesOverlay(BotDiagnosticsScreen(getBotCubit())),
        ));
  }

  Future<bool> _takeBotTurn() async {
    await getBotCubit().takeBotTurn();
    setState(() {});
    return true;
  }

  _goToScoring() {
    getBotCubit().alertCustom(
        "Scoring",
        Center(
          child: Column(
            children: [
              Text("Bot scored"),
              Text(getBotCubit().bot.getScore().toString() + " points",
                  style: TextStyle(fontSize: 80)),
            ],
          ),
        ));
  }
}
