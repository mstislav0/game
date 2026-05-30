# 🚀 Не туда полетели — Space Hitchhikers

Кооперативный браузерный 3D-квест для детей и семейной аудитории.

## Структура проекта

```
space-hitchhikers/
├── godot_project/       ← Godot 4 проект
│   ├── project.godot
│   ├── scenes/
│   │   ├── main_menu.tscn
│   │   ├── player.tscn
│   │   └── game_world.tscn
│   └── scripts/
│       ├── network_manager.gd   ← WebSocket клиент
│       ├── main_menu.gd         ← Меню + создание комнаты
│       ├── player.gd            ← Управление персонажем
│       └── game_world.gd        ← Мир + синхронизация
└── server/
    ├── server.js        ← Node.js WebSocket relay
    ├── package.json
    └── deploy.sh        ← Деплой на VPS
```

## Шаг 1: Запуск сервера локально (для тестирования)

```bash
cd server
npm install
npm start
# Сервер на ws://localhost:8765
```

В `scripts/network_manager.gd` временно поменяйте:
```gdscript
const SERVER_URL = "ws://localhost:8765"
```

## Шаг 2: Установка Godot 4

1. Скачать Godot 4 (стандартная версия): https://godotengine.org/download
2. Открыть `godot_project/project.godot`
3. Запустить игру (F5)

## Шаг 3: Тест мультиплеера

1. Запустить два экземпляра игры (или один браузерный + один в редакторе)
2. В первом: ввести имя → «Создать комнату» → запомнить код
3. Во втором: ввести имя → вставить код → «Войти в комнату»
4. Оба персонажа должны появиться на карте и видеть друг друга

## Шаг 4: Деплой сервера на VPS

```bash
cd server
./deploy.sh
```

После деплоя вернуть в `network_manager.gd`:
```gdscript
const SERVER_URL = "ws://194.85.251.132:8765"
```

## Шаг 5: Сборка браузерной версии

В Godot Editor:
- Project → Export → Web (HTML5)
- Настроить путь экспорта
- Нажать Export Project

## Управление

| Клавиша | Действие |
|---------|----------|
| WASD / Стрелки | Движение |
| E | Взаимодействие |
| Мышь | (камера — в следующей версии) |

## Следующие шаги

- [ ] Вращение камеры мышью
- [ ] Анимации персонажа (бег, стояние)
- [ ] Выбор внешнего вида (мальчик/девочка, цвет)
- [ ] Первая локация: Земля + ракета
- [ ] NPC с диалогами
- [ ] Система заданий
