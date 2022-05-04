import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:imperium_bot/blocs/bot-bloc.dart';
import 'package:imperium_bot/singleton/bloc-sigleton.dart';
import 'package:imperium_bot/view/widgets/custom-number-picker.dart';

class TokenInputs extends StatefulWidget {
  const TokenInputs({Key? key}) : super(key: key);

  @override
  _TokenInputsState createState() => _TokenInputsState();
}

class _TokenInputsState extends State<TokenInputs> {
  BotCubit botCubit = BlocSingletons.botCubit;
  int someNumber = 0;
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(color: Colors.black87),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: _generateTokenInputs(),
        ));
  }

  Widget _generateTokenInputs() {
    return Column(
      children: [
        Row(
          children: [
            //Progress tokens
            Column(
              children: [
                Text("Progress tokens", style: TextStyle(fontSize: 17)),
                CustomNumberPicker(
                  value: botCubit.bot.progressTokens,
                  maxValue: 20,
                  minValue: 0,
                  step: 1,
                  customAddButton: _numberPickerButton(FontAwesomeIcons.plus),
                  customMinusButton:
                      _numberPickerButton(FontAwesomeIcons.minus),
                  onValue: (value) {
                    botCubit.bot.progressTokens = value as int;
                  },
                ),
              ],
            ),

            Spacer(),

            // material tokens
            Column(
              children: [
                Text("Material tokens", style: TextStyle(fontSize: 17)),
                CustomNumberPicker(
                  value: botCubit.bot.materialTokens,
                  maxValue: 200,
                  minValue: 0,
                  step: 1,
                  customAddButton: _numberPickerButton(FontAwesomeIcons.plus),
                  customMinusButton:
                      _numberPickerButton(FontAwesomeIcons.minus),
                  onValue: (value) {
                    botCubit.bot.materialTokens = value as int;
                  },
                ),
              ],
            ),

            Spacer(),
            // Pop tokens

            Column(
              children: [
                Text("Population tokens", style: TextStyle(fontSize: 17)),
                CustomNumberPicker(
                  value: botCubit.bot.populationTokens,
                  maxValue: 200,
                  minValue: 0,
                  step: 1,
                  customAddButton: _numberPickerButton(FontAwesomeIcons.plus),
                  customMinusButton:
                      _numberPickerButton(FontAwesomeIcons.minus),
                  onValue: (value) {
                    botCubit.bot.populationTokens = value as int;
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _numberPickerButton(IconData sign) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FaIcon(sign, size: 18, color: Colors.white),
    );
  }
}
