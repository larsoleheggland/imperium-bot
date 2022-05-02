class BotLogEntry {
  final String text;
  BotLogEntryType? type;
  late DateTime time;

  BotLogEntry(this.text, {type = BotLogEntryType.info}) {
    type = type;
    time = DateTime.now();
  }
}

enum BotLogEntryType { action, playCard, info, debug, error, warning }
