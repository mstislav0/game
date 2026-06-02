# Ассеты, референсы и приёмы (чтобы не переделывать по 10 раз)

Этот файл — «память проекта» по графике и геймдизайну. Перед тем как добавлять
что-то новое, сверяйся отсюда: проверенные источники, лицензии и грабли Godot.

## Лицензии — что можно брать

Берём только **CC0** (можно всё, без указания автора) или **CC-BY**
(можно всё, но указать автора). Всё, что используем, фиксируем ниже.

## Используемые ассеты

| Что | Источник | Лицензия | Где в проекте |
|-----|----------|----------|---------------|
| Космос-кит (ракета, бочки, антенна) | [Kenney Space Kit](https://kenney.nl/assets/space-kit) | CC0 | `assets/kenney_space/` |
| Sci-Fi интерьер (мебель ракеты) | [Quaternius Sci-Fi Essentials](https://quaternius.com/packs/scifiessentialskit.html) | CC0 | `assets/quaternius_scifi/` |
| Текстуры домиков (ретро-фэнтези) | [Kenney Retro Textures Fantasy](https://kenney.nl/assets/retro-textures-fantasy) | CC0 | `assets/textures/retro_fantasy/` |
| Земля (брусчатка PBR) | [ambientCG PavingStones009](https://ambientcg.com/view?id=PavingStones009) | CC0 | `assets/textures/paving_stones/` |
| Музыка «Cosmic Priest» | [OpenGameArt — Centurion_of_war](https://opengameart.org/content/cosmic-priest) | CC0 | `assets/audio/` |
| Анимированный кот (Walk/Idle/Jump) | [poly.pizza — Quaternius Cat](https://poly.pizza/m/2f54vbV0In) | CC0 | `assets/cats/cat.glb` |

### Хорошие источники на будущее
- [Quaternius Ultimate Animated Animals](https://quaternius.com/packs/ultimateanimatedanimals.html) — 12 зверей, 12+ анимаций, CC0
- [Kenney — всё](https://kenney.nl/assets) — CC0, единый стиль
- [poly.pizza](https://poly.pizza) — поиск отдельных моделей, есть прямой GLB-скачивание
- [ambientCG](https://ambientcg.com) — PBR-текстуры CC0
- [OpenGameArt](https://opengameart.org) — музыка/звуки (фильтровать по CC0/CC-BY)
- [Godot demo-projects](https://github.com/godotengine/godot-demo-projects) — официальные примеры (3D платформер, навигация)

## Грабли Godot 4 (проверено на практике)

1. **Невидимые модели Kenney** — у их GLB цвет в vertex colors + внутренний
   оффсет узла `[2,0,1.5]`. Решение: пропатчили GLB-файлы (translation → 0) и
   `generate_lods=false` в `[importer_defaults]` (project.godot). Не возвращать LOD.
2. **`.import` и `.uid` файлы — НЕ коммитим** (в .gitignore). Godot их
   регенерирует. Иначе конфликты при git pull на втором компе.
3. **Чёрный экран** = ошибка в `_ready` до активации камеры. Всегда спауним
   игрока ПЕРВЫМ делом, рискованную логику — в конце / через `call_deferred`.
4. **Строгая типизация** — `var x := abs(sin(...))` падает. Использовать
   `absf()`, `clampf()` и явные `: float`.
5. **Масштаб GLB** — у Quaternius/анимированных моделей армотюр со scale 100
   внутри; Godot импортирует ок, но свой scale задавать на корневом инстансе.
6. **Полноэкранный режим** — `window/size/mode=3` (maximized) в project.godot,
   F11 переключает fullscreen.

## Приёмы «живого мира»

- **Далёкие горы**: кольцо низкополигональных конусов на радиусе ~250–350 м,
  голубовато-серый материал, читаются сквозь туман → ощущение масштаба.
- **Облака**: плоские белые меши высоко, медленно дрейфуют по X, заворачиваются.
- **Туман**: `fog_density ~0.002–0.004` — прячет край карты, даёт глубину.
- **Glow/Bloom** + видимый диск солнца (`DirectionalLight.sky_mode=0`).
- **Бродячие NPC** (коты): random target в радиусе от «дома», Walk-анимация
  при движении, Idle на месте, периодические «Мяу!» — мир кажется обитаемым.
- **Процедурная анимация шага** для статичных моделей (астронавт Kenney без
  скелета): bob по Y + наклон по Z пропорционально скорости.

## План доведения уровня 1 (Земля) до играбельности

1. ✅ Вернуть ракету + стартовые фермы (gantry).
2. ✅ Вернуть вход в ракету + интерьер-кокпит + кнопку запуска.
3. ✅ Вернуть NPC: Профессор (квест инструменты), Механик (квест топливо).
4. ✅ Вернуть собираемые предметы: 3 ящика, 3 бочки + антенна.
5. ✅ Связать запуск: 3 квеста готовы → зайти в ракету → ПУСК → катсцена → космос.
6. ✅ Живой мир: далёкие горы, дрейфующие облака.
7. ✅ 4 бродячих кота (рыжий, чёрный, серый, бенгал) с анимацией и «Мяу!».
8. ⏳ Дальше: звук шагов/мяу, выбор внешности игрока, миссия 2 (космос).
