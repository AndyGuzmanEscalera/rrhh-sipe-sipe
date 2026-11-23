import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';
import 'package:rrhh_sipe_sipe/features/home/widgets/home_components.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/auth_split_layout.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/official_logo.dart';

/// Asset oficial que resuelve el logo dentro del alcance indicado.
String assetName(WidgetTester tester, Finder scope) {
  final image = tester.widget<Image>(
      find.descendant(of: scope, matching: find.byType(Image)));
  return (image.image as AssetImage).assetName;
}

void main() {
  testWidgets('El logotipo usa el asset oficial de la institución',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: OfficialLogo(compact: true))));

    expect(assetName(tester, find.byType(OfficialLogo)),
        'assets/branding/sipe_sipe_crest.png');
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain);
    // Sin filtros ni tintes: el material oficial se muestra tal cual.
    expect(image.color, isNull);
    expect(image.semanticLabel, contains('Gobierno Autónomo Municipal'));
  });

  testWidgets('Las variantes horizontal y blanca resuelven su asset',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: OfficialLogo(width: 300))));
    expect(assetName(tester, find.byType(OfficialLogo)),
        'assets/branding/sipe_sipe_horizontal.png');

    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: OfficialLogo(white: true, width: 300))));
    expect(assetName(tester, find.byType(OfficialLogo)),
        'assets/branding/sipe_sipe_horizontal_white.png');

    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: OfficialLogo(compact: true, white: true))));
    expect(assetName(tester, find.byType(OfficialLogo)),
        'assets/branding/sipe_sipe_crest_white.png');
  });

  testWidgets('El login de escritorio muestra el logotipo oficial en blanco',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: AuthSplitLayout(
                heroTitle: 'Sistema de Recursos Humanos',
                heroSubtitle: 'Acceso institucional.',
                form: SizedBox.shrink()))));
    await tester.pumpAndSettle();

    final logo = find.byType(OfficialLogo);
    expect(logo, findsOneWidget);
    expect(assetName(tester, logo), 'assets/branding/sipe_sipe_horizontal_white.png');
    // Sin el ícono de relleno que antes simulara la marca.
    expect(find.byIcon(Icons.account_balance_rounded), findsNothing);
  });

  testWidgets('El login móvil muestra el escudo oficial a color',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: AuthSplitLayout(
                heroTitle: 'Sistema de Recursos Humanos',
                heroSubtitle: 'Acceso institucional.',
                form: SizedBox.shrink()))));
    await tester.pumpAndSettle();

    final logo = find.byType(OfficialLogo);
    expect(logo, findsOneWidget);
    expect(assetName(tester, logo), 'assets/branding/sipe_sipe_crest.png');
    expect(find.byIcon(Icons.account_balance_rounded), findsNothing);
  });

  testWidgets('La marca del sidebar usa el logotipo oficial en blanco',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HomeBrandMark())));

    expect(assetName(tester, find.byType(HomeBrandMark)),
        'assets/branding/sipe_sipe_horizontal_white.png');
    // El ícono genérico de personas ya no representa a la institución.
    expect(find.byIcon(Icons.people_alt_rounded), findsNothing);
  });

  testWidgets('El encabezado del home usa el escudo, sin ícono decorativo',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: HomeWelcome(username: 'prueba', compact: false))));
    await tester.pumpAndSettle();

    expect(find.byType(OfficialLogo), findsOneWidget);
    // El círculo decorativo con el ícono de diversidad fue retirado.
    expect(find.byIcon(Icons.diversity_3_outlined), findsNothing);
  });

  test('El color principal de RRHH se mantiene', () {
    expect(UiColors.primary, const Color(0xFF4F46E5));
    expect(UiColors.sidebar, const Color(0xFF171D35));
  });
}
