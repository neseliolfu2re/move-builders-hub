"use client";

import { useCallback } from "react";
import { useWallet } from "@aptos-labs/wallet-adapter-react";

export default function Page() {
	const { account, connected, connect, disconnect, wallets, isLoading } = useWallet();

	const handleConnect = useCallback(async () => {
		try {
			const petra = wallets.find((w) => w.name === "Petra");
			if (petra) {
				await connect(petra.name);
			} else {
				window.open("https://petra.app", "_blank");
			}
		} catch (e: unknown) {
			console.warn("Connect error:", e);
		}
	}, [connect, wallets]);

	const status = connected ? "Connected" : isLoading ? "Connecting…" : "Not connected";
	const address = account?.address?.toString() ?? "";

	return (
		<main className="min-h-screen grid place-items-center px-4">
			<div className="w-full max-w-xl rounded-2xl border border-zinc-800 bg-zinc-950 p-6">
				<h1 className="text-xl font-semibold">MoveHub</h1>
				<p className="text-zinc-400 mt-1">
					On-Chain Move Learning • Black/White • Petra only
				</p>
				<div className="h-px bg-zinc-800 my-4" />
				<div className="flex items-center gap-3">
					<button
						onClick={connected ? disconnect : handleConnect}
						className="bg-white text-black font-semibold px-4 py-2 rounded-md border border-white disabled:opacity-70"
						disabled={isLoading}
					>
						{status === "Connected" ? "Disconnect" : "Connect Petra Wallet"}
					</button>
					<span
						className={
							"text-sm " +
							(wallets.some((w) => w.name === "Petra")
								? "text-emerald-400"
								: "text-amber-300")
						}
					>
						{wallets.some((w) => w.name === "Petra")
							? "Petra detected"
							: "Petra not found"}
					</span>
				</div>
				<p className="text-sm text-zinc-400 mt-3">Status: {status}</p>
				{address && (
					<p className="mt-2 font-mono break-all text-sm">Address: {address}</p>
				)}
			</div>
		</main>
	);
}
