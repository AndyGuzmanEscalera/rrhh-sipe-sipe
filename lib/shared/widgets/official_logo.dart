import 'package:flutter/material.dart';

import '../../core/app/app_identity.dart';

/// Marca oficial del Gobierno Autónomo Municipal de Sipe Sipe.
///
/// Copia del material institucional provisto por la Alcaldía y ya usado por el
/// sistema de Correspondencia. No se tiñe, no se deforma y no se añadieron
/// símbolos nuevos: a color sobre fondo claro y en blanco sobre fondo oscuro.
///
/// * [compact] usa el escudo; la variante horizontal usa el logotipo.
class OfficialLogo extends StatelessWidget {
  const OfficialLogo(
      {this.compact = false, this.white = false, this.width, super.key});

  final bool compact;
  final bool white;
  final double? width;

  static const institution = AppIdentity.institution;
  static const system = AppIdentity.name;

  // Proporción de cada variante: wordmark horizontal 1200x260, escudo 512x415.
  static const _horizontalRatio = 441 / 2033;
  static const _crestRatio = 415 / 512;

  @override
  Widget build(BuildContext context) {
    final variant = compact ? 'crest' : 'horizontal';
    final ratio = compact ? _crestRatio : _horizontalRatio;
    final box = width ?? (compact ? 48 : 320);
    return Image.asset(
      'assets/branding/sipe_sipe_$variant${white ? '_white' : ''}.png',
      width: box,
      height: box * ratio,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      semanticLabel: 'Escudo oficial del $institution',
    );
  }
}
