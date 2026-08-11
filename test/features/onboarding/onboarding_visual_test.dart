import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/app/theme/app_theme.dart';
import 'package:quanto_posso/features/categories/pages/category_setup_page.dart';
import 'package:quanto_posso/features/onboarding/pages/onboarding_page.dart';
import 'package:quanto_posso/features/profile/pages/profile_setup_page.dart';

void main() {
  testWidgets('apresentação mostra identidade e benefícios', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in const [Size(360, 800), Size(412, 915)]) {
      await tester.binding.setSurfaceSize(size);
      var started = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: OnboardingPage(onStart: () => started = true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quanto Posso'), findsOneWidget);
      expect(find.text('Cuide melhor do seu dinheiro'), findsOneWidget);
      expect(find.text('Controle simples'), findsOneWidget);
      expect(find.text('Funciona offline'), findsOneWidget);
      expect(find.text('Seus dados ficam com você'), findsOneWidget);
      expect(find.text('Começar'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Apresentação em $size');

      await tester.ensureVisible(find.text('Começar'));
      await tester.tap(find.text('Começar'));
      expect(started, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('perfil mantém campos, privacidade e validações', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(360, 800));
    var continueCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: ProfileSetupPage(onContinue: (name, income) => continueCalls++),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vamos começar pelo seu perfil'), findsOneWidget);
    expect(find.text('Seu nome'), findsOneWidget);
    expect(find.text('Renda mensal'), findsOneWidget);
    expect(
      find.text('Seus dados ficam armazenados somente neste dispositivo.'),
      findsOneWidget,
    );

    final continueButton = find.text('Continuar');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();
    expect(find.text('Informe seu nome'), findsOneWidget);
    expect(find.text('Informe sua renda mensal'), findsOneWidget);
    expect(continueCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('categorias selecionam e avançam para a conclusão', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(412, 915));
    var finishCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: CategorySetupPage(
          name: 'André',
          monthlyIncome: 3500,
          onFinish: (categories) async {
            finishCalls++;
            expect(categories, isNotEmpty);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Organize seus gastos'), findsOneWidget);
    expect(find.text('7 categorias selecionadas'), findsOneWidget);
    await tester.tap(find.text('Alimentação'));
    await tester.pump();
    expect(find.text('6 categorias selecionadas'), findsOneWidget);

    final continueButton = find.text('Continuar');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Tudo pronto!'), findsOneWidget);
    expect(find.text('André'), findsOneWidget);
    expect(find.text('6 selecionadas'), findsOneWidget);
    expect(find.text('Ir para a Home'), findsOneWidget);
    expect(finishCalls, 0);

    await tester.tap(find.text('Ir para a Home'));
    await tester.pumpAndSettle();
    expect(finishCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
