# PurrBreak: переезд на новый компьютер

Этот файл фиксирует состояние проекта на 2026-08-07. Он нужен, чтобы продолжить разработку на новом Mac без восстановления контекста по памяти.

## Коротко

- Репозиторий: <https://github.com/omiusgm/PurrBreak>
- Главная ветка: `main`.
- Текущий коммит: `d0f7123` (`Pause YouTube when breaks start`).
- Рабочее дерево на момент создания файла было чистым и синхронизированным с `origin/main`.
- Файл версии: `VERSION` = `0.2.1`.
- Последний опубликованный тег: `v0.2.1`.
- В `main` уже есть два коммита после `v0.2.1`: `2c74dec` и `d0f7123`. Следующий публичный релиз должен быть `0.2.2`, когда последние изменения будут проверены вручную.

## Что перенести

Исходники уже находятся на GitHub, поэтому на новом Mac достаточно клонировать репозиторий. Полезно отдельно перенести этот рабочий каталог, если в нем есть локальные, еще не закоммиченные эксперименты.

Для обычной разработки понадобится macOS 13+ и Xcode Command Line Tools:

```zsh
xcode-select --install
git clone git@github.com:omiusgm/PurrBreak.git
cd PurrBreak
swift build
./scripts/build-app.sh
open .build/PurrBreak.app
```

Если на новом Mac еще не настроен SSH для GitHub, можно сначала клонировать по HTTPS:

```zsh
git clone https://github.com/omiusgm/PurrBreak.git
```

Текущий `origin` в старом checkout использует локальный SSH-алиас `github.com-hermes`. На новом компьютере проще настроить собственный SSH-ключ и использовать обычный адрес:

```zsh
git remote set-url origin git@github.com:omiusgm/PurrBreak.git
```

## Установка приложения на новом Mac

```zsh
./scripts/install-app.sh
```

Скрипт установит `PurrBreak.app` в `/Applications` или `~/Applications`, зарегистрирует его в LaunchServices и сделает ярлык на рабочем столе. После установки на новом Mac нужно заново:

- разрешить Automation для браузера в `System Settings -> Privacy & Security -> Automation`;
- включить автозапуск, если он нужен;
- установить PurrBreak Companion в каждый Chromium-браузер, где он используется.

Эти разрешения и установленное расширение не переезжают между Mac автоматически.

## Локальные настройки приложения

PurrBreak хранит лимиты, выбранную заставку, язык и дневную статистику локально через `UserDefaults`. У собранного приложения bundle identifier: `local.purrbreak.app`.

Если нужно перенести эти настройки, на старом Mac при закрытом PurrBreak можно сделать экспорт в файл, перенести его вместе с проектом и импортировать на новом Mac:

```zsh
defaults export local.purrbreak.app PurrBreak-settings.plist
```

На новом Mac сначала один раз запусти установленное приложение, затем при закрытом PurrBreak:

```zsh
defaults import local.purrbreak.app PurrBreak-settings.plist
```

Этот файл содержит личные локальные настройки и статистику, поэтому его не стоит коммитить в Git.

## Устройство проекта

| Что | Где | Смысл |
| --- | --- | --- |
| Нативное приложение | `Sources/PurrBreak/main.swift` | Один Swift-файл с моделью, мониторингом браузеров, окнами перерыва и SwiftUI-интерфейсом. |
| Кото-ассеты | `Sources/PurrBreak/Resources/` | Иконка и sprite sheets четырех заставок. |
| Сборка `.app` | `scripts/build-app.sh` | Собирает release-бинарник, ресурсы, `Info.plist` и ad-hoc подпись. |
| Установка | `scripts/install-app.sh` | Копирует приложение в Applications и регистрирует его в macOS. |
| Релиз | `scripts/package-release.sh`, `.github/workflows/release.yml` | Тег `v*` на GitHub собирает архив приложения и Companion, затем создает GitHub Release. |
| Companion | `extensions/purrbreak-companion/` | Chromium-расширение для очистки YouTube и экспериментального Instagram. |
| Лендинги | `docs/index.html`, `docs/companion/index.html` | Двуязычные GitHub Pages-страницы. |
| Идеи | `docs/idea-chest.md` | Сундук идей и отложенных решений. |
| Тесты | `docs/manual-test-checklist.md` | Ручной сценарий проверки перед релизом. |

В `main.swift` полезно ориентироваться на такие блоки:

- `PurrSettings` и `PurrModel`: настройки, счетчики и дневная статистика;
- `BrowserDescriptor` и `BrowserURLReader`: список браузеров и чтение URL активной вкладки через AppleScript;
- `BrowserVideoController`: попытка поставить активное YouTube-видео на паузу перед настоящим перерывом;
- `YouTubeMonitor`: посекундный учет обычного YouTube и Shorts;
- `BreakManager`: оверлей на все дисплеи, тестовый режим, таймер паузы и мурчание;
- SwiftUI views: настройки, справка, браузерный onboarding и экран после паузы;
- `AppDelegate`: menu bar, окна приложения и запуск сервисов.

## Что готово

- macOS menu-bar приложение на Swift/AppKit/SwiftUI, минимальная версия macOS 13.
- Учет только активной вкладки YouTube в Safari, Chrome, Yandex Browser, Brave, Edge, Arc, Chromium, Vivaldi и Opera.
- Отдельные лимиты: обычный YouTube 20 минут, Shorts 5 минут; новая установка получает 3-минутную паузу по умолчанию.
- Настоящий перерыв останавливает активное YouTube-видео, блокирует ввод и показывает заставку на всех дисплеях. Тест заставки не блокирует клики и закрывается через `Esc`.
- Четыре темы с котом, мурчанием, меню-баром с обратным отсчетом и вариантами отображения.
- RU/EN интерфейс, onboarding проверки браузеров, справка, автозапуск, дневная статистика и ссылка на GitHub Issues.
- PurrBreak Companion: Hide Shorts, homepage, sidebar/recommendations, comments, end wall, autoplay, Focus mode; Instagram Reels/Explore/suggested accounts пока экспериментальны.
- Двуязычные GitHub Pages-лендинги для приложения и Companion.

## Ограничения, которые важно помнить

- Приложение видит активный URL, а не факт реального просмотра кадр за кадром. YouTube-музыка в фоне тоже считается; это честно описано в справке.
- Firefox пока отображается в списке, но URL его активной вкладки этим AppleScript-подходом не читается.
- Остановка видео через JavaScript/Automation best-effort: браузер должен разрешить PurrBreak Automation. Если браузер блокирует команду, сам перерыв все равно покажется.
- Companion пока рассчитан на Chromium-браузеры. Safari Web Extension и iPhone — будущая отдельная работа.
- Приложение ad-hoc подписано, без Apple notarization. На первом запуске macOS может попросить открыть его через правый клик -> `Open`.
- GitHub Pages публикуются workflow из `docs`. Если страница отдает `404`, в настройках репозитория надо выбрать `Settings -> Pages -> Build and deployment -> GitHub Actions`.

## Ближайший безопасный план

1. На двух дисплеях вручную проверить последний коммит: запуск заставки, паузу YouTube-видео, кнопки/ввод, `Esc` в preview и окончание паузы.
2. Если все хорошо, поменять `VERSION` на `0.2.2`, обновить release notes/README при необходимости, закоммитить и создать тег `v0.2.2`.
3. Проверить, что GitHub Actions прикрепил оба архива к релизу: приложение и Companion.
4. Следующей большой функцией сделать подсчет количества Shorts/Reels через Companion Extension, а не пытаться угадывать его только по URL в macOS-приложении.
5. После этого строить недельный дашборд поверх локальных агрегатов, без хранения URL, названий роликов или истории просмотров.

Подробная история решений из чата: [`chat-summary.md`](chat-summary.md).
