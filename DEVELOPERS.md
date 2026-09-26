# Developers

## Setup

### Local setup

1. Clone the repository:
   ```bash
   git clone git@github.com:televator-apps/vimari.git
   ```
2. Open `Vimari.xcodeproj` with Xcode.
3. [Set your signing team](https://help.apple.com/xcode/mac/current/#/dev23aab79b4) for both targets (Vimari and Vimari Extension).
4. Run the project (<kbd>⌘</kbd>+<kbd>R</kbd>).

You might have to reload the website you had open for the changes to take effect. Also check your configuration file as it currently does not get upgraded automatically.

### Linting & Formatting

Code linting and formatting will be implemented in [#193](https://github.com/televator-apps/vimari/pull/193).

## Universal macOS builds

Release builds use Xcode's standard architectures with `ONLY_ACTIVE_ARCH=NO`
for both the app and its embedded Safari extension. Build once with Xcode;
do not combine separately signed bundles with `lipo`. Debug builds still use
the active architecture. The existing Intel deployment target, bundle IDs,
entitlements, and configuration location are unchanged.

The **Universal macOS build** workflow uses macOS 15 and Xcode 16.4. It builds
without distribution signing credentials, packages the app with `ditto`, and
checks the extracted archive with `make verify-universal APP=/absolute/path/to/Vimari.app`.
The check requires both `arm64` and `x86_64` in the app, extension, and other
native components, and matching app/extension version and build numbers.

Legacy Swift back-deployment libraries are an exception: Xcode can embed
Intel-only Swift 5.0 libraries for older macOS versions, while Apple Silicon
uses the system Swift runtime. The check accepts these only in the app's
Frameworks directory when the selected Xcode toolchain contains the same
Intel-only legacy library. Do not remove these libraries or raise the Intel
deployment target just to make the architecture check pass.

CI's `Vimari-universal-unsigned` artifact is for inspection only. It is **not**
a notarized release and must never be used by the Homebrew cask.

## Publishing a universal release

### Distribution prerequisites

- Use a Mac with Xcode 16.4 and a Developer ID Application certificate and its
  private key available in Keychain. Install any provisioning profiles required
  by the signing team for **both** targets.
- Obtain authorization to use the existing signing identity and bundle IDs.
  Changing the signing team can affect Safari registration and access to the
  existing sandbox; do not assume preserving bundle IDs alone preserves an
  upgrade. If the original identity is unavailable, resolve and test migration
  before publishing or changing the tap.
- Keep signing credentials out of the repository and untrusted CI jobs. A
  successful unsigned CI build does not satisfy this prerequisite.
- Select an unused release version and build number, and set matching values
  for the app and extension in both configurations. Do not replace an existing
  release asset in place. Version 2.1.1 is present in this source tree, but that
  alone does not mean a downloadable release exists.

### Archive, sign, and notarize

1. Select the release commit and run the existing JavaScript tests. With a
   current npm, use `npm ci` followed by
   `make test NPM_BIN="$PWD/node_modules/.bin"` from the repository root.
2. Open the project in Xcode, select the Vimari scheme and the generic Mac
   destination (not a single-architecture destination), and archive the Release
   configuration. Both targets must use standard architectures and build all
   architectures, not just the active one.
3. In Organizer, distribute the archive using **Developer ID**, with the
   authorized signing team. Keep hardened runtime enabled and sign all embedded
   code, including the extension and Swift libraries. Use Xcode's export flow
   rather than recursively re-signing with `codesign --deep`.
4. Export the signed `Vimari.app`. Run
   `make verify-universal APP=/absolute/path/to/export/Vimari.app` using the same
   Xcode toolchain as the build. Verify signatures using
   `codesign --verify --deep --strict --verbose=2 /absolute/path/to/export/Vimari.app`.
5. If Organizer has not already notarized the app, package it for submission
   with `ditto -c -k --sequesterRsrc --keepParent`, and submit that ZIP with
   `xcrun notarytool submit /absolute/path/to/submission.zip --keychain-profile PROFILE --wait`.
   Create the notarytool Keychain profile interactively beforehand; never put
   passwords in source files. Continue only when the submission is **Accepted**.
6. Staple the ticket to the exported app with `xcrun stapler staple`, then run
   `xcrun stapler validate` and `spctl --assess --type execute --verbose=2` against
   that app. Do not bypass Gatekeeper or remove quarantine to make a test pass.
7. Create the **final** `Vimari.app.zip` from the stapled app using
   `ditto -c -k --sequesterRsrc --keepParent`. Extract it into a fresh directory
   and repeat architecture, version, signature, ticket, and Gatekeeper checks.
   Calculate `shasum -a 256` on this final ZIP, not the pre-notarization archive.

### Release acceptance and Homebrew handoff

Before making the release public:

- On Apple Silicon without Rosetta, install the final downloaded archive,
  launch the app, enable its extension, and confirm both processes run natively.
- Test link hints, scrolling, tab navigation, normal/insert mode, opening and
  editing configuration, and persistence after restarting Safari.
- Smoke-test Intel, including the oldest macOS version claimed by the release.
  Test upgrading from 2.1.0 with an existing customized configuration on both
  architectures; do not uninstall or reset configuration to mask migration
  problems.

Publish the tested ZIP and its SHA-256 as assets of a versioned GitHub release
in the repository responsible for distributing the build. The root of the ZIP
must contain `Vimari.app`. Verify the public asset URL and checksum after upload.

The tap change is a **separate change in `vladdoster/homebrew-formulae`**:
update the Vimari cask's version, SHA-256, download repository/URL, and livecheck
source together. A single universal ZIP does not need architecture-specific
cask URLs. Do not bump the cask until that exact signed artifact is available.
Run the tap's cask style/audit checks and test both a fresh Homebrew install and
an upgrade on Apple Silicon and Intel before closing issue #5.

### Existing distribution diagnosis

The 2.1.0 `Vimari.app.zip` referenced by the tap has SHA-256
`8bea73f879d70a9e7567d192980d18da449be40342dd6a1d8faf3399c998ca25`.
Inspection found that its app executable, Safari extension executable, and all
16 bundled Swift dylibs contain only `x86_64`. Updating cask metadata alone
cannot add the missing native app and extension slices.

## Contributing

If you'd like to contribute to the development of Vimari you can help us out through several means:

1. Create bug reports for issues you encounter, or look trough existing bug reports and try to reproduce their problems.
2. Try out the latest beta version (if there is one) and report issues back to us.
3. Contribute ideas, if you'd like something to be added to Vimari you can create an issue describing exactly what you have in mind. Together we can help form the idea and get it into Vimari.
4. Contribute code, if you find a bug or issue that you think you can help us solve you are more than welcome to do so.

### Contributing Code

If you want to contribute to Vimari through coding you have to start by selecting an issue to work on. If you'd like to contribute something new, make an issue first to discuss the idea.

You can fork the Vimari source code and make the changes to implement your feature or solve a bug. Once finished you can create a pull request back into the Vimari repository where it can be reviewed.

After a successful review your code will be merged with the master branch and released to Vimari users in the next release. Pretty cool!
