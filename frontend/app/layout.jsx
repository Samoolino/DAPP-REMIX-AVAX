import './globals.css';
import PWARegister from '../components/PWARegister';

export const metadata = {
  title: 'Avalanche Flashloan Control Plane',
  description: 'Contract archive, wallet console, Remix workspace and gated Avalanche C-Chain execution control plane.',
  manifest: '/manifest.webmanifest',
  themeColor: '#070b12'
};

export const viewport = {
  width: 'device-width',
  initialScale: 1,
  viewportFit: 'cover'
};

export default function RootLayout({ children }) {
  return <html lang="en"><body><PWARegister />{children}</body></html>;
}
