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
	swift_libs="$$(dirname "$$(dirname "$$(xcrun --find swiftc)")")/lib/swift-5.0/macosx"; \
	for bundle in "$$app" "$$extension"; do \
		executable=$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$$bundle/Contents/Info.plist"); \
		xcrun lipo "$$bundle/Contents/MacOS/$$executable" -verify_arch arm64 x86_64; \
	done; \
	for key in CFBundleShortVersionString CFBundleVersion; do \
		app_version=$$(/usr/libexec/PlistBuddy -c "Print :$$key" "$$app/Contents/Info.plist"); \
		extension_version=$$(/usr/libexec/PlistBuddy -c "Print :$$key" "$$extension/Contents/Info.plist"); \
		if [[ -z "$$app_version" || "$$app_version" != "$$extension_version" ]]; then \
			echo "App/extension $$key mismatch"; exit 1; \
		fi; \
	done; \
	while IFS= read -r -d '' binary; do \
		if file -b "$$binary" | grep -q 'Mach-O'; then \
			echo "$$binary"; \
			if xcrun lipo "$$binary" -verify_arch arm64 x86_64; then \
				continue; \
			fi; \
			legacy="$$swift_libs/$${binary##*/}"; \
			if [[ "$$binary" == "$$app/Contents/Frameworks/libswift"*.dylib ]] && \
				[[ -f "$$legacy" ]] && \
				! xcrun lipo "$$legacy" -verify_arch arm64; then \
				xcrun lipo "$$binary" -verify_arch x86_64; \
				echo 'Intel-only Swift back-deployment runtime (Apple Silicon uses system Swift)'; \
			else \
				echo "Missing required architecture: $$binary"; \
				exit 1; \
			fi; \
		fi; \
	done < <(find "$$app" -type f -print0)
