.PHONY: help version bump bump-build bump-patch bump-minor bump-major set-version get clean get-deps analyze test build-apk build-appbundle build-ios build-ipa

# Default target
help:
	@echo "Доступные команды Makefile:"
	@echo ""
	@echo "  Управление версиями (pubspec.yaml):"
	@echo "    make version        - Показать текущую версию"
	@echo "    make bump           - Поднять build number (+1) (например, 1.0.1+2 -> 1.0.1+3)"
	@echo "    make bump-build     - Синоним make bump"
	@echo "    make bump-patch     - Поднять patch версию (+1) (например, 1.0.1+2 -> 1.0.2+3)"
	@echo "    make bump-minor     - Поднять minor версию (+1) (например, 1.0.1+2 -> 1.1.0+3)"
	@echo "    make bump-major     - Поднять major версию (+1) (например, 1.0.1+2 -> 2.0.0+3)"
	@echo "    make set-version v=1.2.0+5 - Установить конкретную версию"
	@echo ""
	@echo "  Разработка и сборка Flutter:"
	@echo "    make get            - flutter pub get"
	@echo "    make clean          - flutter clean && flutter pub get"
	@echo "    make analyze        - Запустить статический анализ кода"
	@echo "    make test           - Запустить тесты"
	@echo "    make build-apk      - Собрать релизный APK"
	@echo "    make build-appbundle- Собрать релизный Android App Bundle"
	@echo "    make build-ios      - Собрать iOS проект"
	@echo "    make build-ipa      - Собрать IPA для App Store"

# Команды управления версиями
version:
	@dart run tool/bump_version.dart get

bump:
	@dart run tool/bump_version.dart build

bump-build:
	@dart run tool/bump_version.dart build

bump-patch:
	@dart run tool/bump_version.dart patch

bump-minor:
	@dart run tool/bump_version.dart minor

bump-major:
	@dart run tool/bump_version.dart major

set-version:
	@if [ -z "$(v)" ]; then \
		echo "Ошибка: укажите версию через v=X.Y.Z+N (например, make set-version v=1.2.0+5)"; \
		exit 1; \
	fi
	@dart run tool/bump_version.dart set $(v)

# Flutter команды
get:
	flutter pub get

get-deps: get

clean:
	flutter clean
	flutter pub get

analyze:
	flutter analyze

test:
	flutter test

build-apk:
	flutter build apk --release

build-appbundle:
	flutter build appbundle --release

build-ios:
	flutter build ios --release --no-codesign

build-ipa:
	flutter build ipa --release
