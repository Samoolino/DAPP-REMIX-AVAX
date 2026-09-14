# iOS build

## Prerequisites

- macOS
- Node.js LTS
- Xcode
- Apple Developer signing configuration for device/App Store distribution

## Prepare

From `mobile/`:

```bash
npm install
npx cap add ios
npx cap sync ios
npx cap open ios
```

Select a simulator or signed physical device in Xcode and build/test.

## Wallet testing

A generic iOS WebView is not guaranteed to expose a wallet provider. Validate wallet behavior with the wallet's supported browser/deep-link flow or implement and test an explicit WalletConnect/native wallet bridge before claiming native in-app signing support.

## Release gate

Do not ship a release as mainnet-ready until wallet signing, Remix interaction, contract manifests and all execution assurance gates have been tested. The mobile wrapper must never custody private keys.
