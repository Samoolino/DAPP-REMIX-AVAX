import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'io.samoolino.avaxcontrol',
  appName: 'Avalanche Flashloan Control Plane',
  webDir: '../frontend',
  server: {
    url: 'https://dapp-remix-avax.vercel.app',
    cleartext: false
  },
  android: {
    allowMixedContent: false
  },
  ios: {
    contentInset: 'automatic'
  }
};

export default config;
