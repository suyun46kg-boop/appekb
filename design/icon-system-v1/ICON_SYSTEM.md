# EKB Icon System v1 — «Marketplace Outline» (Blue)

## Концепт
Monoline outline-система в духе Kleinanzeigen, но в **синей палитре EKB** — связь с шапкой и брендом приложения.

## Палитра (pro)

| Роль | HEX | Зачем |
|------|-----|--------|
| **Tile surface** | `#EEF3FF` | Мягкий blue-50, не конкурирует с белым фоном экрана |
| **Icon stroke** | `#1A56DB` | Brand primary — узнаваемый EKB-синий |
| **Stroke dark** *(alt)* | `#1341B0` | Для мелких размеров, если нужен контраст |

> Как у Kleinanzeigen: фон tile — **очень светлый** оттенок, линия — **насыщенный** тон того же семейства.

## Принципы
| Параметр | Значение |
|----------|----------|
| Контейнер | Squircle, rx=15 на 64×64 |
| Stroke width | 2.25 |
| Стиль | Monoline, rounded caps/joins |
| Fill | None (кроме точек-акцентов) |

## Категории → символ
| ID | RU | Symbol |
|----|-----|--------|
| apartment | квартира | House |
| job | работа | Briefcase |
| border | граница | Minivan side |
| auto | авто | Car front |
| ticket | билеты | Two tickets |
| services | услуги | Hammer |
| sale | куплю/продам | Shopping bag |
| parttime | подработка | Clock |

## Файлы
- `svg/category_*.svg` — мастер (синяя палитра)
- `category_*_v1.png` — PNG preview

Не подключены к приложению.
