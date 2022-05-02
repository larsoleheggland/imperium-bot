extension ParseToString on Enum {
  String toShortString() {
    return this.toString().split('.').last;
  }
}
