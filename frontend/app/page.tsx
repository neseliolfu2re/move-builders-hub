"use client";

import { useCallback, useEffect, useState } from "react";

export default function Page() {
	const [detected, setDetected] = useState<boolean>(false);
	const [address, setAddress] = useState<string>("");
	const [status, setStatus] = useState<string>("Not connected");

	useEffect(() => {
		setDetected(typeof (window as any).aptos !== "undefined");
		const onVis = () => { if (!document.hidden) setDetected(typeof (window as any).aptos !== "undefined"); };
		document.addEventListener("visibilitychange", onVis);
		return () => document.removeEventListener("visibilitychange", onVis);
	}, []);

	const connect = useCallback(async () => {
		try {
			const w = (window as any).aptos;
			if (!w) {
				setStatus("Petra not found");
				window.open("https://petra.app", "_blank");
				return;
			}
			setStatus("Connecting…");
			const res = await w.connect();
			setAddress(res.address);
			setStatus("Connected");
		} catch (e: any) {
			const msg = String(e?.message || e).toLowerCase();
			if (msg.includes("reject")) setStatus("User rejected"); else setStatus(`Failed: ${e?.message || e}`);
		}
	}, []);

	return (
		<main className="min-h-screen grid place-items-center px-4">
			<div className="w-full max-w-xl rounded-2xl border border-zinc-800 bg-zinc-950 p-6">
				<h1 className="text-xl font-semibold">MoveHub</h1>
				<p className="text-zinc-400 mt-1">On-Chain Move Learning • Black/White • Petra only</p>
				<div className="h-px bg-zinc-800 my-4" />
				<div className="flex items-center gap-3">
					<button onClick={connect} className="bg-white text-black font-semibold px-4 py-2 rounded-md border border-white">
						{status === "Connected" ? "Connected" : "Connect Petra Wallet"}
					</button>
					<span className={"text-sm " + (detected ? "text-emerald-400" : "text-amber-300")}>{detected ? "Petra detected" : "Petra not found"}</span>
				</div>
				<p className="text-sm text-zinc-400 mt-3">Status: {status}</p>
				{address && <p className="mt-2 font-mono break-all">Address: {address}</p>}
			</div>
		</main>
	);
}

