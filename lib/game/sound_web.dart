import 'dart:js_interop';

@JS('bulletSound')
external void _bulletSound(JSString kind);

void playTone(String kind) => _bulletSound(kind.toJS);
