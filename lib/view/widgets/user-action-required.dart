import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/singleton/bloc-sigleton.dart';

class RequiredUserAction extends StatefulWidget {
  final String title;
  final Widget userDirections;
  const RequiredUserAction(this.title, this.userDirections, {Key? key})
      : super(key: key);

  @override
  _RequiredUserActionState createState() =>
      _RequiredUserActionState(title, userDirections);
}

class _RequiredUserActionState extends State<RequiredUserAction> {
  final String title;
  final Widget userDirections;

  BotCubit botCubit = BlocSingletons.botCubit;

  _RequiredUserActionState(this.title, this.userDirections);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      backgroundColor: Colors.black26,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              userDirections,
              Divider(height: 50),
              ElevatedButton(onPressed: _onConfirm, child: Text("Done!"))
            ],
          ),
        ),
      ),
    );
  }

  _onConfirm() {
    botCubit.confirmUserAction();
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
  }
}
