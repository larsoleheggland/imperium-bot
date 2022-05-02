import 'package:flutter/cupertino.dart';

import 'card-enums.dart';

class GameCard {
  final String name;
  final String playEffect;
  final String passiveEffect;
  final String exhaustEffect;
  final String solsticeEffect;
  final String victoryPointsText;

  late int playerCount;
  late CardSet gameSet;
  late int victoryPoints;
  late CardType type;
  late List<CardIcon> icons;

  GameCard(
    this.name,
    String typeString,
    String iconsString1,
    String iconsString2,
    String iconsString3,
    String iconsString4,
    this.playEffect,
    this.passiveEffect,
    this.exhaustEffect,
    this.solsticeEffect,
    this.victoryPointsText,
    String playerCountString,
    String setString,
  ) {
    try {
      type = _parseType(typeString);
      playerCount = _parsePlayerCount(playerCountString);
      victoryPoints = _parseVictoryPoints(victoryPointsText);
      icons = _parseIcons(iconsString1 +
          "," +
          iconsString2 +
          "," +
          iconsString3 +
          "," +
          iconsString4);
      var debut = true;
    } catch (e) {
      debugPrint(e.toString());
      var debug = e;
    }
  }

  bool hasIcon(CardIcon icon) {
    return icons.any((i) => i == icon);
  }

  bool IsType(CardType cardType) {
    return type == cardType;
  }

  //Parse methods

  int _parsePlayerCount(String playerCountString) {
    try {
      return int.parse(playerCountString);
    } catch (e) {
      var debug = e;
    }

    return 0;
  }

  List<CardIcon> _parseIcons(String iconString) {
    var icons = iconString.split(",");
    List<CardIcon> result = [];
    for (var icon in icons) {
      icon = icon.trim();
      if (icon == "") continue;
      var parsedIcon = _parseIcon(icon);
      if (parsedIcon == CardIcon.undefined)
        debugPrint("Unknown icon: " + icon);
      else {
        result.add(parsedIcon);
      }
    }

    return result;
  }

  CardIcon _parseIcon(String iconString) {
    //scroll, trade, grain, water, metropolis, helmet, undefined
    if (iconString == "") {
      return CardIcon.undefined;
    }

    iconString = iconString.toLowerCase();
    iconString = iconString.replaceAll(RegExp(r'[^\w\s]+'), '');

    for (var icon in CardIcon.values) {
      var iconName = icon.toString().toLowerCase();

      if (iconName.contains(iconString)) {
        return icon;
      }
    }

    debugPrint("Unknown icon: " + iconString);
    return CardIcon.undefined;
  }

  int _parseVictoryPoints(String victoryPointsText) {
    victoryPointsText = victoryPointsText.toLowerCase().trim();

    if (victoryPointsText == "") {
      return 0;
    }

    if (victoryPointsText.contains("per")) {
      return 5;
    }
    if (victoryPointsText.contains("history")) {
      var extractIntegers =
          victoryPointsText.replaceAll(new RegExp(r'[^0-9]'), '');
      return int.parse(extractIntegers);
    }
    try {
      return int.parse(victoryPointsText);
    } catch (e) {
      var debug = e;
      return 0;
    }
  }

  CardType _parseType(String type) {
    switch (type.toLowerCase()) {
      case "uncivilised":
        return CardType.uncivilised;
      case "uncivilised/civilised":
        return CardType.uncivilisedCivilised;
      case "region":
        return CardType.region;
      case "tributary":
        return CardType.tributary;
      case "start":
        return CardType.start;
      case "power a":
        return CardType.powerA;
      case "power b":
        return CardType.powerB;
      case "common":
        return CardType.common;
      case "nation":
        return CardType.nation;
      case "accession":
        return CardType.accession;
      case "civilised":
        return CardType.civilised;
      case "development":
        return CardType.development;
      case "fame":
        return CardType.fame;
      case "fame a":
        return CardType.fameA;
      case "fame b":
        return CardType.fameB;
    }

    debugPrint("Undefined card type: " + type);
    return CardType.undefined;
  }
}
