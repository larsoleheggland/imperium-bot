import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BigButton extends StatelessWidget {
  final String buttonText;
  final Color color;
  final VoidCallback onPressed;

  BigButton(this.buttonText, this.color, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
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
        child: Text(buttonText,
            style: const TextStyle(color: Colors.white, fontSize: 20)),
      ),
    );
  }
}
