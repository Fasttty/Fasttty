# Рядом для iPhone

Проект iOS 16+ с приложением SwiftUI, встроенным интерфейсом WebKit и подключением к тому же серверу, что и Android. Приложение требует интернет. Исходники не содержат Apple ID или паролей.

## Сборка с Windows через GitHub Actions

1. Распакуй архив целиком в репозиторий GitHub, включая папку `.github`.
2. Открой вкладку Actions → Build iPhone IPA → Run workflow.
3. После зелёной сборки скачай артефакт Ryadom-iPhone-unsigned и распакуй его.
4. Полученный `.ipa` требуется подписать при установке. На Windows для этого можно использовать AltStore Classic. Инструкция — https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows

Сборка также запускается командой `bash build-ipa.sh` на macOS с Xcode и XcodeGen. Установка на физический iPhone требует проверки. Архив проекта сам по себе не является установщиком.
