import 'package:flutter/material.dart';
import 'package:imperium_bot/business/bot/bot.dart';
import 'package:imperium_bot/extensions/enum-extensions.dart';
import 'package:imperium_bot/models/bot-log-entry.dart';
import 'package:imperium_bot/models/card-enums.dart';
import 'package:imperium_bot/models/card.dart';

class CarthaginiansBot extends Bot {
  CarthaginiansBot(Difficulty difficulty)
      : super(Faction.carthaginians, difficulty);

  @override
  Future<bool> basicBarbarianAction(GameCard card) async {
    discardTopCards(2);
    return true;
  }

  @override
  Future<bool> basicEmpireAction(GameCard card) async {
    putCardInHistory(card);

    if (materialTokens >= 2) {
      materialTokens -= 2;
      progressTokens++;
    } else if (populationTokens >= 2) {
      populationTokens -= 2;
      progressTokens++;
    }

    botCubit.alertAddUnrestCard();

    return true;
  }

  @override
  void extraSetup() {}

  @override
  Future<bool> resolveCard(GameCard card) async {
    log(
        "Bot plays card: " +
            card.name +
            ", and resolved as " +
            stage.toShortString(),
        entryType: BotLogEntryType.playCard);

    if (card.hasIcon(CardIcon.unrest)) {
      log("Resolves unrest action: alerts user to put an unrest card in pile, and removes card from bots deck");
      await botCubit.alertAddUnrestCard();
      cardsToBeRemovedFromPlayDeck.add(card);
      return true;
    } else {
      if (stage == Stage.barbarian) {
        return await resolveBarbarian(card);
      } else {
        return await resolveEmpire(card);
      }
    }
  }

  Future<bool> resolveEmpire(GameCard card) async {
    // Barbarian

    if (card.hasIcon(CardIcon.barbarian)) {
      log("Resolves barbarian icon: gain materian and population, put card to history");
      materialTokens++;
      populationTokens++;
      putCardInHistory(card);
      return true;
    }

    // Fame

    else if (card.hasIcon(CardIcon.fame)) {
      log("Resolves fame icon: put into history");
      putCardInHistory(card);
      return true;
    }

    // Attack

    else if (card.hasIcon(CardIcon.attack)) {
      log("Resolves attack icon: break through for region, and You abandon a region, and MAY draw a card.");
      if (await breakthroughFor(<CardType>[CardType.tributary])) {
        await botCubit.alertCustom(
            "Attack!", new Text("You abandon a region, and MAY draw a card"));
        return true;
      }
    }

    // card name = "glory"

    else if (card.name == "Glory") {
      log("Resolves 'glory' card: if able, abandons 3 pinned regions to breakthrough for fame card. Else breaks through for region and attack.");

      if (getPinnedRegionCount() >= 3) {
        abandonPinnedRegions(3);
        if (await breakthroughFor(<CardType>[CardType.fame])) {
          return true;
        }

        if (await breakthroughFor(<CardType>[CardType.region])) {
          await botCubit.alertCustom(
              "Attack!", new Text("You discard two cards."));
          return true;
        }
      }
    }

    // Empire icon

    else if (card.hasIcon(CardIcon.empire)) {
      log("Resolves 'empire' icon: aquires fame card, or adds progress tokens and player takes unrest");
      if (await acquire(<CardType>[CardType.fame])) {
        return true;
      } else {
        progressTokens++;
        botCubit.alertTakeUnrest();
        return true;
      }
    }

    // Region icon

    else if (card.hasIcon(CardIcon.region)) {
      log("Resolves 'region' icon: plays region, adds 1 material token, and alerts user to exile card");
      playRegion(card);
      materialTokens++;
      await botCubit.alertRequireCardExile();
      return true;
    }

    // Pinned icon

    else if (card.hasIcon(CardIcon.pinned)) {
      log("Resolves 'pinned' icon: gains  2 materials, and puts card into history");
      materialTokens += 2;
      await putCardInHistory(card);
      return true;
    }

    basicEmpireAction(card);
    return true;
  }

  Future<bool> resolveBarbarian(GameCard card) async {
    //Fame
    if (card.hasIcon(CardIcon.fame)) {
      log("Resolves fame icon: adds one population token, and one material token");
      populationTokens++;
      materialTokens++;

      return true;
    }

    // card name = "glory"
    else if (card.name == "Glory") {
      log("Resolves 'glory' card: if able, abandons 3 pinned regions to breakthrough for fame card. Else breaks through for region");

      if (getPinnedRegionCount() >= 3) {
        abandonPinnedRegions(3);
        if (await breakthroughFor(<CardType>[CardType.fame])) {
          return true;
        }

        if (await breakthroughFor(<CardType>[CardType.region])) {
          return true;
        }
      }
    }

    // barbarian

    else if (card.hasIcon(CardIcon.barbarian)) {
      log("Resolves 'barbarian' card: ..");
      if (populationTokens >= 3) {
        log("Bot spends 3 population tokens, and breaks through for tributary card.");
        populationTokens -= 3;
        if (await breakthroughFor(<CardType>[CardType.tributary])) {
          return true;
        }
      } else if (materialTokens >= 2) {
        log("Bot spends 2 material tokens, and aquires a civilised or unsiviliced card.");
        materialTokens -= 2;
        if (await acquire(
            <CardType>[CardType.civilised, CardType.uncivilised])) {
          return true;
        }
      } else {
        log("Bot gains 1 material token, 1 population token, and puts card into history");
        materialTokens++;
        populationTokens++;
        putCardInHistory(card);
        return true;
      }
    }

    // region

    else if (card.hasIcon(CardIcon.region)) {
      log("Resolves 'region' icon: plays region, and alerts user to exile card");
      playRegion(card);
      await botCubit.alertRequireCardExile();
      return true;
    }

    // pinned

    else if (card.hasIcon(CardIcon.pinned)) {
      log("Resolves 'pinned' icon: adds 1 population, 2 materials, and puts card into history");
      populationTokens += 1;
      materialTokens += 2;
      await putCardInHistory(card);
      return true;
    }

    // Prosperity

    else if (card.name.toLowerCase() == "prosperity") {
      log("Resolves 'prosperity' card: discard 1 card, gain population and materials for every region.");
      discardTopCards(1);
      gainPopulationForEveryRegion();
      gainMaterialForEveryRegion();
      return true;
    }

    // Tributary

    else if (card.hasIcon(CardIcon.tributary)) {
      log("Resolves 'tributary' icon: discards 3 cards.");
      discardTopCards(3);
      return true;
    } else {
      log("Resolves 'other' icon");
      if (materialTokens != 0) {
        log("Replace material tokens for progress tokens.");
        progressTokens += materialTokens;
        materialTokens = 0;
        return true;
      } else {
        log("Bot aquires region.");
        if (await acquire(<CardType>[CardType.region])) {
          return true;
        }
      }
    }

    basicBarbarianAction(card);
    return true;
  }

  @override
  Future<bool> addTokensToCard() async {
    await botCubit.requireUserAction("Add tokens to card",
        Text("Add 2 material tokens to card in place " + diceRoll.toString()));

    return true;
  }
}
