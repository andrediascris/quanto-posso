# Quanto Posso — guia para agentes

## Propósito

Quanto Posso é um aplicativo Flutter offline-first para registrar gastos e
compará-los com a renda mensal. Os dados financeiros permanecem no dispositivo.

## Stack e fluxo de dados

- Flutter e Material para a interface.
- Provider/ChangeNotifier para estado e coordenação.
- SQLite (`sqflite`) para perfil, categorias e gastos.
- SharedPreferences para tema e preferências de notificações.
- Notificações locais para lembrete diário e alertas de orçamento.

O fluxo normal é `UI → Provider → Repository → SQLite/SharedPreferences`.
Widgets não acessam banco ou repositories diretamente.

## Estrutura

- `lib/app/`: composição do aplicativo e Design System.
- `lib/core/`: banco, notificações, constantes e utilitários compartilhados.
- `lib/features/`: páginas e fluxos agrupados por funcionalidade.
- `lib/models/`: modelos imutáveis e mapeamento de persistência.
- `lib/providers/`: estado, operações assíncronas e mensagens amigáveis.
- `lib/repositories/`: única camada autorizada a acessar persistência.
- `lib/shared/`: widgets, cards, inputs, gráficos e navegação reutilizáveis.
- `test/`: testes de modelos, providers e widgets com fakes.

## Responsabilidades

Providers expõem estado somente leitura, coordenam repositories e notificam a
UI. Não recebem `BuildContext` e não dependem diretamente de outros providers.
Repositories validam entradas e encapsulam SQLite ou SharedPreferences. SQL
deve usar parâmetros; transações devem usar o `Transaction` recebido.

## Design System

Use sempre `AppColors`, `AppSpacing`, `AppRadius`, `AppTypography` e
`AppShadows`. Nunca introduza cores, espaçamentos, raios ou tipografia
hardcoded em widgets. Preserve acessibilidade com labels, tooltips e Semantics.

## Convenções

- Arquivos e pastas em `snake_case`; tipos em `PascalCase`; membros em
  `camelCase`.
- Widgets privados para trechos locais repetidos; componentes compartilhados
  apenas quando há reutilização real.
- Verifique `mounted`/`context.mounted` depois de operações assíncronas.
- Descarte controllers, focus nodes e listeners no `dispose`.
- Exponha listas e mapas com `List.unmodifiable`/`Map.unmodifiable`.
- Use `CurrencyUtils` para moeda brasileira.

## Fluxos principais

No primeiro acesso, `StartupPage` conduz onboarding, perfil e seleção de
categorias; `InitialSetupProvider` persiste o conjunto inicial. Depois disso,
`MainShellPage` apresenta Home, Dashboard, Histórico e Configurações.

Um gasto é validado pela UI, criado por `ExpenseProvider` via
`ExpenseRepository` e refletido nos providers de Home, Histórico e Dashboard.
A exclusão remove localmente o item do Histórico, recarrega totais e reconcilia
alertas de orçamento.

## Comandos obrigatórios

```text
dart format lib test
flutter analyze
flutter test
```

## Regras para futuras IAs

- Nunca usar cores hardcoded.
- Nunca acessar SQLite em widgets.
- Nunca colocar lógica de negócio em telas.
- Sempre usar AppColors, AppSpacing, AppRadius e AppTypography.
- Sempre executar `flutter analyze` e `flutter test` após alterações.
- Preservar migrações e dados existentes; nunca apagar ou recriar o banco para
  facilitar mudanças.
- Não adicionar dependências, mudar navegação ou ampliar arquitetura sem pedido
  explícito.
- Não remover testes aprovados nem usar plugins/SQLite reais em widget tests.
