class _Token {
  final String base;
  const _Token(this.base);
  String get png => '$base.png';
  String get jpg => '$base.jpg';
  String get jpeg => '$base.jpeg';
  String get webp => '$base.webp';
  String get bmp => '$base.bmp';
  @override
  String toString() => base;
}

// Tokens used by generated Scenario Outline substitutions
const corrupted = _Token('corrupted');
const signature = _Token('signature');
const empty = _Token('empty');
