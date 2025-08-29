class _Token {
  final String base;
  const _Token(this.base);
  String get png => '$base.png';
  String get jpg => '$base.jpg';
  String get jpeg => '$base.jpeg';
  String get webp => '$base.webp';
  String get bmp => '$base.bmp';
  // Allow combining tokens with a dash, e.g., zh - TW -> 'zh-TW'
  _Token operator -(Object other) {
    if (other is _Token) {
      return _Token('$base-${other.base}');
    }
    return _Token(base);
  }

  @override
  String toString() => base;
}

// Tokens used by generated Scenario Outline substitutions
const corrupted = _Token('corrupted');
const signature = _Token('signature');
const empty = _Token('empty');

// Preferences & i18n tokens used by generated tests
const light = _Token('light');
const dark = _Token('dark');
const system = _Token('system');
const en = _Token('en');
const es = _Token('es');
const zh = _Token('zh');
// ignore: constant_identifier_names
const TW = _Token('TW');
const theme = _Token('theme');
const language = _Token('language');
