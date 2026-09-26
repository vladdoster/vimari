.PHONY: all test test-watch verify-universal

NPM=$(shell which npm)
NPM_BIN=$(shell npm bin)

all: deps

deps:
	@$(NPM) install

test:
	@$(NPM_BIN)/jest tests

test-watch:
	@$(NPM_BIN)/jest --watch tests

verify-universal: SHELL := /bin/bash
verify-universal:
	@test -n "$(APP)" || { echo 'Set APP to the absolute path of Vimari.app'; exit 1; }
	@set -euo pipefail; \
	app="$(APP)"; \
	extension="$$app/Contents/PlugIns/Vimari Extension.appex"; \
	for bundle in "$$app" "$$extension"; do \
		executable=$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$$bundle/Contents/Info.plist"); \
		xcrun lipo -verify_arch arm64 x86_64 "$$bundle/Contents/MacOS/$$executable"; \
	done; \
	for key in CFBundleShortVersionString CFBundleVersion; do \
		app_version=$$(/usr/libexec/PlistBuddy -c "Print :$$key" "$$app/Contents/Info.plist"); \
		extension_version=$$(/usr/libexec/PlistBuddy -c "Print :$$key" "$$extension/Contents/Info.plist"); \
		test -n "$$app_version" && test "$$app_version" = "$$extension_version" || \
			{ echo "App/extension $$key mismatch"; exit 1; }; \
	done; \
	while IFS= read -r -d '' binary; do \
		if file -b "$$binary" | grep -q 'Mach-O'; then \
			echo "$$binary"; \
			xcrun lipo -verify_arch arm64 x86_64 "$$binary"; \
		fi; \
	done < <(find "$$app" -type f -print0)
