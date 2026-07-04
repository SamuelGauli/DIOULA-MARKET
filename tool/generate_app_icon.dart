// Génère le logo de Dioula Market (icône de l'app) sans outil externe.
//
// Lancer :  dart run tool/generate_app_icon.dart
// Produit  :  assets/icon/app_icon.png            (1024², plein cadre — iOS/web)
//             assets/icon/app_icon_foreground.png (1024², transparent — Android adaptatif)
// Puis     :  dart run flutter_launcher_icons     (génère toutes les tailles)
//
// Design : carré terracotta + disque crème + monogramme « D » (terracotta foncé),
//          rappel de la charte « marché ivoirien ».
import 'dart:io';
import 'package:image/image.dart' as img;

// Charte (cf. lib/core/theme/app_colors.dart).
final _clay = img.ColorRgba8(0xE0, 0x70, 0x3A, 255); // terracotta
final _clayDark = img.ColorRgba8(0xC8, 0x5A, 0x28, 255); // terracotta foncé
final _cream = img.ColorRgba8(0xFB, 0xF4, 0xEA, 255); // crème

/// Dessine le disque crème + le « D » terracotta centré en (cx, cy).
void _drawMark(img.Image image, int cx, int cy, int r) {
  int p(double f) => (r * f).round();
  // Disque crème.
  img.fillCircle(image, x: cx, y: cy, radius: r, color: _cream, antialias: true);
  // Panse (demi-cercle droit) : bord gauche aligné sur la jambe (cx-0.58r).
  img.fillCircle(image,
      x: cx + p(0.02), y: cy, radius: p(0.60), color: _clayDark, antialias: true);
  // Contre-forme (le trou du D).
  img.fillCircle(image,
      x: cx + p(0.04), y: cy, radius: p(0.32), color: _cream, antialias: true);
  // Jambe verticale (bord gauche bien droit).
  img.fillRect(image,
      x1: cx - p(0.58),
      y1: cy - p(0.60),
      x2: cx - p(0.28),
      y2: cy + p(0.60),
      color: _clayDark,
      radius: p(0.06));
}

void main() {
  const size = 1024;
  const c = size ~/ 2;

  // 1) Icône pleine (fond terracotta) — iOS / web / Android legacy.
  final icon = img.Image(width: size, height: size, numChannels: 4);
  img.fillRect(icon, x1: 0, y1: 0, x2: size - 1, y2: size - 1, color: _clay);
  _drawMark(icon, c, c, 330);

  // 2) Premier plan transparent (le fond adaptatif fournira le terracotta).
  final fg = img.Image(width: size, height: size, numChannels: 4);
  _drawMark(fg, c, c, 300); // marge de sécurité pour le masque adaptatif

  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/app_icon.png').writeAsBytesSync(img.encodePng(icon));
  File('assets/icon/app_icon_foreground.png')
      .writeAsBytesSync(img.encodePng(fg));

  stdout.writeln('✅ Logo généré : assets/icon/app_icon.png (+ foreground)');
}
