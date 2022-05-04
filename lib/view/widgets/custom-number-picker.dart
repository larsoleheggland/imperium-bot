import 'dart:async';

import 'package:flutter/material.dart';

class CustomNumberPicker<T extends num> extends StatefulWidget {
  final ShapeBorder? shape;
  final TextStyle? valueTextStyle;
  final Function(T) onValue;
  final Widget? customAddButton;
  final Widget? customMinusButton;
  final T maxValue;
  final T minValue;
  int value;
  final T step;

  ///default vale true
  final bool enable;

  CustomNumberPicker(
      {Key? key,
      this.shape,
      this.valueTextStyle,
      required this.onValue,
      required this.value,
      required this.maxValue,
      required this.minValue,
      required this.step,
      this.customAddButton,
      this.customMinusButton,
      this.enable = true})
      : assert(value.runtimeType != String),
        assert(maxValue.runtimeType == value.runtimeType),
        assert(minValue.runtimeType == value.runtimeType),
        super(key: key) {}

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return CustomNumberPickerState();
  }
}

class CustomNumberPickerState<T extends num>
    extends State<CustomNumberPicker<T>> {
  late num _maxValue;
  late num _minValue;
  late num _step;
  Timer? _timer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //_value = widget.value;
    _maxValue = widget.maxValue;
    _minValue = widget.minValue;
    _step = widget.step;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.enable,
      child: Card(
        shadowColor: Colors.transparent,
        elevation: 0.0,
        semanticContainer: true,
        color: Colors.transparent,
        shape: widget.shape ??
            RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(0.0)),
                side: BorderSide(width: 1.0, color: Color(0xffF0F0F0))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: minus,
                onTapDown: (details) {
                  onLongPress(DoAction.MINUS);
                },
                onTapUp: (details) {
                  _timer?.cancel();
                },
                onTapCancel: () {
                  _timer?.cancel();
                },
                child: widget.customMinusButton),
            Container(
              width: _textSize(widget.valueTextStyle ?? TextStyle(fontSize: 14))
                  .width,
              child: Text(
                widget.value.toString(),
                style: widget.valueTextStyle ?? TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: add,
                onTapDown: (details) {
                  onLongPress(DoAction.ADD);
                },
                onTapUp: (details) {
                  _timer?.cancel();
                },
                onTapCancel: () {
                  _timer?.cancel();
                },
                child: widget.customAddButton)
          ],
        ),
      ),
    );
  }

  Size _textSize(TextStyle style) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: _maxValue.toString(), style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(
          minWidth: 0, maxWidth: _maxValue.toString().length * style.fontSize!);
    return textPainter.size;
  }

  void minus() {
    if (canDoAction(DoAction.MINUS)) {
      setState(() {
        widget.value -= _step as int;
      });
    }
    widget.onValue(widget.value as T);
  }

  void add() {
    if (canDoAction(DoAction.ADD)) {
      setState(() {
        widget.value += _step as int;
      });
    }
    widget.onValue(widget.value as T);
  }

  void onLongPress(DoAction action) {
    var timer = Timer.periodic(Duration(milliseconds: 300), (t) {
      action == DoAction.MINUS ? minus() : add();
    });
    setState(() {
      _timer = timer;
    });
  }

  bool canDoAction(DoAction action) {
    if (action == DoAction.MINUS) {
      return widget.value - _step >= _minValue;
    }
    if (action == DoAction.ADD) {
      return widget.value + _step <= _maxValue;
    }
    return false;
  }
}

enum DoAction { MINUS, ADD }
