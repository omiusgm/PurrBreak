# PurrBreak Companion

MVP браузерного расширения, которое делает YouTube и Instagram менее липкими.

PurrBreak делает осознанные паузы. Companion убирает интерфейсные крючки, которые тянут к следующему ролику.

Лендинг: <https://omiusgm.github.io/PurrBreak/companion/>

Short English version: PurrBreak Companion hides Shorts, recommendations, comments, autoplay, and experimental Instagram Reels hooks.

## Что уже есть

YouTube:

- Hide Shorts.
- Hide homepage.
- Hide sidebar / recommendations.
- Hide comments.
- Hide end wall.
- Disable autoplay.
- Focus mode.

Instagram, экспериментально:

- Hide Reels.
- Hide Explore.
- Hide suggested accounts.

## Установка локально

Для Chrome, Yandex Browser, Arc, Brave, Edge, Opera, Vivaldi и Chromium:

1. Скачай и распакуй `PurrBreak-Companion-*.zip` из GitHub Release или собери архив командой `./scripts/package-companion.sh`.
2. Открой страницу расширений браузера, например `chrome://extensions`.
3. Включи developer mode.
4. Нажми `Load unpacked`.
5. Выбери распакованную папку `purrbreak-companion`.

Safari и iPhone потребуют отдельную Safari Web Extension-обертку позже.

## Заметки

- YouTube и Instagram часто меняют разметку, поэтому CSS-селекторы иногда нужно будет чинить.
- Instagram-поддержка намеренно помечена как экспериментальная.
- Расширение не собирает и не отправляет данные.
