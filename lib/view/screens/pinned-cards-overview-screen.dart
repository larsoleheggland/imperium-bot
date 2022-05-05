import 'package:flutter/material.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
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
        title: const Text('Bot diagnostics'),
      ),
      backgroundColor: Colors.transparent,
      body: Text("Pinned cards"),
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
  }
}
