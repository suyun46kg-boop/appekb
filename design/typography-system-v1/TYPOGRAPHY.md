# EKB Typography System v1 — «Marketplace Inter»

## Концепт
Единая шкала типографики уровня Airbnb / Avito / Apple / Kleinanzeigen.  
Шрифт: **Inter** — читается на Android и iPhone, современный, подходит для маркетплейсов.

## Шрифт
| Параметр | Значение |
|----------|----------|
| Family | Inter |
| Weights | 400 Regular · 500 Medium · 600 SemiBold · 700 Bold |
| Hint | В идеале не больше 3 весов (400 / 600 / 700); Medium (500) — только для meta |

## Шкала

| Элемент | Size | Weight | Line Height | Color |
|---------|------|--------|-------------|-------|
| Заголовок экрана | 28 px | 700 Bold | 34 px | `#111827` |
| Заголовок раздела | 22 px | 700 Bold | 28 px | `#111827` |
| Название объявления | 16 px | 600 SemiBold | 22 px | `#111827` |
| Описание | 14 px | 400 Regular | 20 px | `#6B7280` |
| Цена | 20 px | 700 Bold | 24 px | `#111827` |
| Дата / Город | 13 px | 500 Medium | 18 px | `#9CA3AF` |
| Категории | 14 px | 500 Medium | 18 px | `#111827` |
| Поиск | 16 px | 400 Regular | 20 px | `#111827` |
| Нижний навбар | 12 px | 500 Medium | 16 px | inactive `#9CA3AF` / active brand |

## Цвета текста

| Роль | HEX |
|------|-----|
| Основной | `#111827` |
| Вторичный (описание) | `#6B7280` |
| Дата и город | `#9CA3AF` |
| Акцент | `#1A56DB` (EKB brand blue) |

## Карточка объявления (ключевой блок)

| Элемент | Size | Weight | Color |
|---------|------|--------|-------|
| Название | 16 px | 600 | `#111827` |
| Описание | 14 px | 400 | `#6B7280` |
| Цена | 20 px | 700 | `#111827` |
| Дата и город | 13 px | 500 | `#9CA3AF` |

## Приёмы хороших приложений
1. **Цена крупнее названия** ~ на 20–25% (20 vs 16).
2. **Описание светлее** — не конкурирует с названием.
3. **Обрезка:** название max 2 строки, описание max 2 строки.
4. **Один шрифт** во всём приложении.
5. **Иерархия цветом**, не только размером.

## Flutter (ориентир)

```dart
// Text
static const Color textPrimary   = Color(0xFF111827);
static const Color textSecondary = Color(0xFF6B7280);
static const Color textMuted     = Color(0xFF9CA3AF);
static const Color brandBlue     = Color(0xFF1A56DB);

// Styles (GoogleFonts.inter)
screenTitle  → 28 / w700 / h34 / textPrimary
sectionTitle → 22 / w700 / h28 / textPrimary
listingTitle → 16 / w600 / h22 / textPrimary   · maxLines: 2
listingDesc  → 14 / w400 / h20 / textSecondary · maxLines: 2
price        → 20 / w700 / h24 / textPrimary
meta         → 13 / w500 / h18 / textMuted     // дата, город
category     → 14 / w500 / h18 / textPrimary
search       → 16 / w400 / h20 / textPrimary
navLabel     → 12 / w500 / h16
```

## Файлы
- `index.html` — живой превью шкалы + карточка
- Flutter: `lib/theme/ekb_typography.dart` — токены
- Подключено: главный экран (`lib/dbdd/dbdd_widget.dart`) + нижний навбар
