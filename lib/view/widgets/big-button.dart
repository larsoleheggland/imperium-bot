import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BigButton extends StatelessWidget {
  final String buttonText;
  final Color color;
  final VoidCallback onPressed;

  double height;

  BigButton(this.buttonText, this.color, this.onPressed, {this.height = 70});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: color,
        ),
        onPressed: () {
          onPressed();
        },
        child: Align(
          alignment: Alignment.center,
          child: Text(buttonText,
              style: const TextStyle(color: Colors.white, fontSize: 20)),
        ),
      ),
    );
  }
}
