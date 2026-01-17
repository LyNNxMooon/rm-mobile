import 'package:flutter/cupertino.dart';
import 'package:rmstock_scanner/constants/colors.dart';

TextStyle getSmartTitle({Color? color, double? fontSize}) {
  TitleStyleComponent title = DefaultTitleStyle();

  if (color != null && fontSize != null) {
    title = WithColor(title, color, fontSize);
  }

  return title.getStyle();
}

abstract class TitleStyleComponent {
  TextStyle getStyle();
}

// Concrete Component (The Base)
class DefaultTitleStyle implements TitleStyleComponent {
  @override
  TextStyle getStyle() {
    return const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: kSecondaryColor,
    );
  }
}

//The Decorator Base Class
abstract class TitleDecorator implements TitleStyleComponent {
  final TitleStyleComponent _wrappedStyle;

  TitleDecorator(this._wrappedStyle);

  @override
  TextStyle getStyle() {
    return _wrappedStyle.getStyle();
  }
}

//Concrete Decorator (Color Override)
class WithColor extends TitleDecorator {
  final Color _color;
  final double _fontSize;

  WithColor(super.style, this._color, this._fontSize);

  @override
  TextStyle getStyle() {
    return super.getStyle().copyWith(color: _color, fontSize: _fontSize);
  }
}
