# Arquitetura do Quanto Posso

## Visão geral

O aplicativo adota uma arquitetura em camadas simples:

```text
UI (features e shared)
↓
Provider (estado e coordenação)
↓
Repository (persistência)
↓
SQLite ou SharedPreferences
```

O funcionamento é offline-first. Perfil, categorias e gastos são persistidos
em SQLite. Tema, lembrete diário e controle de alertas financeiros usam
SharedPreferences. Notificações são locais e não enviam dados pela internet.

## Camada de UI

`lib/features/` contém páginas por fluxo. `lib/shared/` contém componentes
reutilizáveis, inputs, cards, navegação e gráficos. A UI observa providers,
coleta entrada e exibe estados; ela não executa SQL nem acessa repositories.

`StartupPage` escolhe entre primeiro acesso e aplicação configurada.
`MainShellPage` mantém Home, Dashboard, Histórico e Configurações em um
`IndexedStack` e coordena atualizações cruzadas após mudanças financeiras.

## Providers

- `InitialSetupProvider`: perfil, categorias e primeiro acesso.
- `ExpenseProvider`: gastos recentes e total do mês atual.
- `HistoryProvider`: lista completa, busca, filtro e exclusão local.
- `DashboardProvider`: métricas mensais, totais por categoria e série diária.
- `ThemeProvider`: modo claro, escuro ou sistema.
- `NotificationProvider`: lembrete diário e sua permissão.
- `BudgetAlertProvider`: preferências, deduplicação mensal e reconciliação dos
  alertas de orçamento.

Providers não usam `BuildContext`. Coleções são expostas como visualizações não
modificáveis.

## Repositories

- `SetupRepository`: perfil, categorias e configuração inicial.
- `ExpenseRepository`: CRUD e consultas agregadas de gastos.
- `PreferencesRepository`: tema, lembrete diário e alertas financeiros.

Somente repositories acessam SQLite ou SharedPreferences. Consultas SQL usam
parâmetros e datas persistidas usam ISO 8601.

## SQLite

O banco atual está na versão 3 e mantém `PRAGMA foreign_keys = ON`.

### `profiles`

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | INTEGER | chave primária |
| `name` | TEXT | obrigatório |
| `monthly_income` | REAL | maior que zero |
| `created_at` | TEXT | ISO 8601 |
| `updated_at` | TEXT | ISO 8601 |

### `categories`

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | TEXT | chave primária |
| `name` | TEXT | obrigatório |
| `icon_code_point` | INTEGER | obrigatório |
| `icon_font_family` | TEXT | obrigatório |
| `color_value` | INTEGER | obrigatório |
| `is_default` | INTEGER | 0 ou 1 |
| `created_at` | TEXT | ISO 8601 |

### `expenses`

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | INTEGER | chave primária autoincremental |
| `amount` | REAL | maior que zero |
| `category_id` | TEXT | FK para `categories.id` |
| `description` | TEXT | opcional |
| `occurred_at` | TEXT | ISO 8601 |
| `created_at` | TEXT | ISO 8601 |
| `updated_at` | TEXT | ISO 8601 |

`expenses.category_id` referencia `categories.id`, usa `ON UPDATE CASCADE` e
`ON DELETE RESTRICT`. Há índices por data de ocorrência e categoria.

## Migrações

- Versão 2: cria a tabela e os índices de gastos.
- Versão 3: adiciona `categories.color_value` com valor padrão compatível.

`onCreate` cria diretamente o schema da versão atual. Migrações devem continuar
incrementais e nunca apagar tabelas ou dados existentes.

## Design System e utilitários

O Design System fica em `lib/app/theme/`. Componentes devem consumir seus
tokens, sem valores visuais arbitrários. `CurrencyUtils` centraliza parsing e
formatação monetária brasileira. Novos utilitários só devem existir quando
houver duplicação comprovada.

## Testes

Testes de providers usam repositories e serviços falsos em memória. Widget
tests não usam SQLite, SharedPreferences ou plugins reais. Antes de entregar
qualquer mudança, execute formatação, `flutter analyze` e `flutter test`.
