import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { WalletProvider } from '../components/WalletProvider'

const inter = Inter({ subsets: ['latin'] })

export const metadata = { title: "MoveHub", description: "On-Chain Move Learning" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
	return (
		<html lang="tr">
			<body className="bg-black text-white antialiased">
				{children}
			</body>
		</html>
	);
}

