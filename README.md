# Maxgram

Гибридный клиент: протокол MAX/OneMe (WebSocket) + UI визуально имитирует Telegram-iOS.

Важно: неофициальный клиент. Логотип/название "Telegram" не используются.
Протокол реализован по открытым наработкам сообщества (python-max-client), без
использования их кода напрямую — endpoint и коды ошибок нуждаются в проверке
на реальном трафике.

## Открытие в Android Studio
1. Распакуйте архив
2. Установите Flutter SDK (https://docs.flutter.dev/get-started/install), если ещё не установлен
3. Откройте файл `android/local.properties` и укажите реальные пути:
   sdk.dir=/путь/к/Android/sdk
   flutter.sdk=/путь/к/flutter
4. В Android Studio: File → Open → выберите корневую папку maxgram (не android/)
5. Android Studio предложит установить Flutter/Dart плагины — подтвердите
6. Дождитесь синхронизации Gradle (первая сборка скачает Gradle 8.4 и зависимости)
7. Запустите через Run ▷ на эмуляторе или подключённом устройстве

## Альтернативный запуск через терминал
flutter pub get
flutter run

## Структура
- lib/theme/ — светлая/тёмная палитры, живое переключение
- lib/models_chat.dart, lib/models_message.dart — модели UI
- lib/widgets/ — аватар, бейдж, строка чата, пузырь, реакции/меню
- lib/screens/ — экран входа, список чатов, переписка, настройки
- lib/max_protocol/ — WebSocket-клиент MAX, модель пакета, репозиторий (парсинг в UI-модели)
- lib/main.dart — точка входа
- android/ — конфигурация Gradle-проекта для Android Studio (applicationId: com.maxgram.app,
  minSdk 21, targetSdk/compileSdk 34, Kotlin, AndroidX)

## Что ещё предстоит проверить
- Реальный WebSocket-endpoint и точные opcode-коды протокола MAX
- Retry-логика при обрыве соединения
- Пагинация истории сообщений (getHistory с курсором)
- App icons (mipmap-*) — сейчас папки пустые, нужно добавить реальные иконки перед релизом
