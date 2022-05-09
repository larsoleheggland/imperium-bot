import 'package:flutter/material.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/theme/custom-colors.dart';
import 'package:imperium_bot/view/widgets/big-button.dart';
import 'package:imperium_bot/view/widgets/pinned-card-deck-list.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class PinnedCardsOverviewScreen extends StatefulWidget {
  BotCubit botCubit;

  PinnedCardsOverviewScreen(this.botCubit);

  @override
  State<StatefulWidget> createState() =>
      _PinnedCardsOverviewScreenState(this.botCubit);
}

class _PinnedCardsOverviewScreenState extends State<PinnedCardsOverviewScreen> {
  BotCubit botCubit;

  _PinnedCardsOverviewScreenState(this.botCubit);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinned cards'),
      ),
      backgroundColor: Colors.transparent,
      body: _generateBody(),
    );
  }

  Widget _generateBody() {
    if (botCubit.bot.pinnedCards.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("Bot has no pinned cards."),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SingleChildScrollView(child: _generatePinnedCards()),
              Row(
                children: [
                  Expanded(
                    child: BigButton(
                      "Abandon region",
                      CustomColors.red,
                      _botAbandonRegion,
                      height: 100,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                      child: BigButton(
                    "Recall region",
                    CustomColors.red,
                    _botRecallRegion,
                    height: 100,
                  )),
                ],
              )
            ],
          ),
        ],
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
    setState(() {});
  }

  _botRecallRegion() {
    var region = botCubit.bot.recallRegion();
    if (region != null) {
      showTopSnackBar(
        context,
        CustomSnackBar.success(
          message: "Bot recalled region " + region.name,
        ),
      );
    } else {
      showTopSnackBar(
        context,
        const CustomSnackBar.error(
          message: "Bot has no region to recall",
        ),
      );
    }
    setState(() {});
  }

  Widget _generatePinnedCards() {
    return PinnedCardDeckList(botCubit, botCubit.bot.pinnedCards);
  }
}
