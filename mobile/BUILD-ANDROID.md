# Android build

## Prerequisites

- Node.js LTS
- Java 17
- Android Studio with Android SDK and build tools
- An Android signing key for release distribution

## Prepare

From `mobile/`:

```bash
npm install
npx cap add android
npx cap sync android
npx cap open android
```

Build a debug APK from Android Studio for device testing. Configure a release keystore only for an actual release build.

## Wallet testing

Test first in the target wallet's supported in-app browser or with the wallet integration explicitly supported by the DApp. Do not assume a generic WebView exposes `window.ethereum`.

## Release gate

Before distribution, verify:

1. App opens the production control plane over HTTPS.
2. Wallet connection behavior is explicitly tested on the target wallet/device.
3. Remix launch/import flow works.
4. No seed phrase/private key is stored by the app.
5. Execution state remains gated and no scanner can submit automatically.
6. Mainnet contract addresses, routers, tokens and fee assumptions are independently verified.
