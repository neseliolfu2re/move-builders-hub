"use client";

import { AptosWalletAdapterProvider } from "@aptos-labs/wallet-adapter-react";
import { Network } from "@aptos-labs/ts-sdk";
import { type ReactNode } from "react";

export function WalletProvider({ children }: { children: ReactNode }) {
	return (
		<AptosWalletAdapterProvider
			autoConnect={true}
			dappConfig={{
				network: Network.TESTNET,
			}}
			optInWallets={["Petra"]}
			onError={(error) => console.warn("Wallet error:", error)}
		>
			{children}
		</AptosWalletAdapterProvider>
	);
}
