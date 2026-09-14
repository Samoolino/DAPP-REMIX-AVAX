# Avalanche Flashloan Control Plane — Android / iOS Wrapper

This directory defines the native mobile shipment around the responsive web DApp.

## Architecture

The mobile app is a thin Capacitor shell around the deployed web control plane. It does not contain private keys, custody funds, or bypass the wallet signer.

`Mobile shell → Web DApp → Remix → Wallet → Avalanche C-Chain`

The web DApp remains the single responsive interface for desktop, tablet and mobile. There are no separate mobile UI pages.

## Current production web target

`https://dapp-remix-avax.vercel.app`

If the production alias changes, update `mobile/capacitor.config.ts` before building.

## Important wallet limitation

A generic native WebView does not automatically provide the same injected `window.ethereum` provider that a wallet's in-app browser provides. Therefore this wrapper must not claim universal native wallet connectivity until an explicit WalletConnect/native wallet bridge is implemented and tested.

For signing and contract deployment, the authoritative flow remains the supported wallet environment and Remix. Never place a seed phrase or private key in this project.

## Build outputs

- Android: unsigned/debug APK or signed release AAB/APK after Android SDK + signing configuration.
- iOS: simulator/device build and signed IPA after Xcode + Apple signing configuration.

This repository ships the source wrapper and build instructions, not a falsely represented pre-signed APK/IPA.

## Safety state

The mobile shell does not change execution gates. Scanner actions remain non-submitting. `OBSERVE → CONFIGURE → CONTROLLED TEST → READY → LIVE` remains enforced by the control-plane architecture.
