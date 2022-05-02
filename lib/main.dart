import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/data/card-database.dart';
import 'package:imperium_bot/theme/custom-colors.dart';
import 'package:imperium_bot/view/form/card-input.dart';
import 'package:imperium_bot/view/screens/bot-diagnostics-screen.dart';
import 'package:imperium_bot/view/screens/user-messages-overlay.dart';
import 'package:imperium_bot/view/widgets/user-action-required.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import 'singleton/bloc-sigleton.dart';
import 'view/widgets/big-button.dart';

/*
  TODO:
  - Implement unrest card on aquire
  - Implement empire logic
 */
void main() {
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
        textTheme: TextTheme(
          bodyText1: TextStyle(),
          bodyText2: TextStyle(),
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const App(title: 'imperium bot'),
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
  BotCubit botCubit = BlocSingletons.botCubit;

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      CardDatabase.initialize();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: BlocBuilder<BotCubit, BotState>(
            bloc: BlocSingletons.botCubit,
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
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/background.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [generateBotButtons(context, state)]),
              );
            }),
      ),
    );
  }

  _botAbandonRegion() {
    var region = botCubit.bot.abandonRegion();
    if (region != null) {
      showTopSnackBar(
        context,
        CustomSnackBar.success(
          message: "Bot abandoned region " + region.name,
        ),
      );
    } else {
      showTopSnackBar(
        context,
        const CustomSnackBar.error(
          message: "Bot has no region to abandon",
        ),
      );
    }
  }

  _botDrawCard() {
    var card = botCubit.bot.drawAndDiscard();
    showTopSnackBar(
      context,
      CustomSnackBar.success(
        message: "Bot discarded " + card.name,
      ),
    );
  }

  _requireCard(BotRequestCard state, context) {
    Future.microtask(() => Navigator.push(
          context,
          UserMessagesOverlay(CardFormInput(state.acquireType, state.cardType)),
        ));
  }

  _requireUserAction(BotRequestUserAction state, context) {
    Future.microtask(() => Navigator.push(
          context,
          UserMessagesOverlay(
              RequiredUserAction(state.title, state.userDirections)),
        ));
  }

  _openBotDiagnostics() {
    Future.microtask(() => Navigator.push(
          context,
          UserMessagesOverlay(BotDiagnosticsScreen()),
        ));
  }

  generateBotButtons(BuildContext context, BotState state) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BigButton("Take bot turn", CustomColors.red, botCubit.takeBotTurn),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: BigButton("Draw card", Colors.black87, _botDrawCard)),
              SizedBox(width: 10),
              Expanded(
                  child: BigButton(
                      "Abandon region", Colors.black87, _botAbandonRegion)),
            ],
          ),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  _openBotDiagnostics();
                });
              },
              child: Text("Open bot diagnostics")),
        ],
      ),
    );
  }
}
