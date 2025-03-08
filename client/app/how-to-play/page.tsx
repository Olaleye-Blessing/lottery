import Link from "next/link";

export default function HowToPlay() {
	return (
		<main className="layout">
			<header className="my-10 text-center">
				<h1 className="text-5xl font-bold mb-1">How to Play</h1>
				<p className="text-xl text-gray-400">
					Everything you need to know about our decentralized lottery
				</p>
			</header>

			<section className="bg-gray-800/50 rounded-lg my-8 p-6 backdrop-blur-sm">
				<h2 className="text-3xl font-bold mb-6 text-primary">
					Lottery Basics
				</h2>

				<div className="space-y-6">
					<div>
						<h3 className="text-2xl font-semibold mb-2">
							Getting Started
						</h3>
						<p className="text-gray-200">
							Our decentralized lottery runs on blockchain
							technology, ensuring complete transparency and
							fairness. Each round lasts for 7 days, with the
							possibility of extension if not enough tickets are
							sold.
						</p>
					</div>

					<div>
						<h3 className="text-2xl font-semibold mb-2">
							Ticket Price
						</h3>
						<p className="text-gray-200">
							Each ticket costs 0.002 ETH. You can purchase
							multiple tickets to increase your chances of
							winning.
						</p>
					</div>

					<div>
						<h3 className="text-2xl font-semibold mb-2">
							Selecting Numbers
						</h3>
						<p className="text-gray-200">
							Choose 6 unique numbers between 1 and 99 for each
							ticket. Make sure to select different numbers as
							duplicates are not allowed.
						</p>
					</div>
				</div>
			</section>

			<section className="bg-gray-800/50 rounded-lg my-8 p-6 backdrop-blur-sm">
				<h2 className="text-3xl font-bold mb-6 text-primary">
					Lottery Rounds
				</h2>

				<div className="space-y-8">
					<div className="relative pl-8 border-l-2 border-indigo-500">
						<div className="absolute -left-3 top-0 w-6 h-6 bg-indigo-500 rounded-full flex items-center justify-center">
							<span className="font-bold text-xs">1</span>
						</div>
						<h3 className="text-xl font-semibold mb-2">
							Active Round
						</h3>
						<p className="text-gray-200">
							During the active phase, you can purchase as many
							tickets as you wish. Each round starts immediately
							after the previous one ends.
						</p>
					</div>

					<div className="relative pl-8 border-l-2 border-indigo-500">
						<div className="absolute -left-3 top-0 w-6 h-6 bg-indigo-500 rounded-full flex items-center justify-center">
							<span className="font-bold text-xs">2</span>
						</div>
						<h3 className="text-xl font-semibold mb-2">
							Drawing Phase
						</h3>
						<p className="text-gray-200">
							Once the active period ends, the contract requests
							random numbers from Chainlink VRF to determine the
							winning numbers. This ensures fair and verifiable
							randomness.
						</p>
					</div>

					<div className="relative pl-8 border-l-2 border-indigo-500">
						<div className="absolute -left-3 top-0 w-6 h-6 bg-indigo-500 rounded-full flex items-center justify-center">
							<span className="font-bold text-xs">3</span>
						</div>
						<h3 className="text-xl font-semibold mb-2">
							Register Winning Tickets
						</h3>
						<p className="text-gray-200">
							After the winning numbers are drawn, there&apos;s a
							3-hour window where winners must register their
							winning tickets. You need to check your tickets and
							register any winners during this time.
						</p>
					</div>

					<div className="relative pl-8 border-l-2 border-indigo-500">
						<div className="absolute -left-3 top-0 w-6 h-6 bg-indigo-500 rounded-full flex items-center justify-center">
							<span className="font-bold text-xs">4</span>
						</div>
						<h3 className="text-xl font-semibold mb-2">
							Claiming Prizes
						</h3>
						<p className="text-gray-200">
							Once the registration period ends, the prize pool
							becomes claimable. Winners can claim their portion
							of the prize pool. If there are no winners, the
							prize rolls over to the next round.
						</p>
					</div>
				</div>
			</section>

			<section className="bg-gray-800/50 rounded-lg my-8 p-6 backdrop-blur-sm">
				<h2 className="text-3xl font-bold mb-6 text-primary">
					Winning Mechanics
				</h2>

				<div className="space-y-6">
					<div>
						<h3 className="text-2xl font-semibold mb-2">
							How Winners Are Determined
						</h3>
						<p className="text-gray-200">
							You win if all six numbers on your ticket match the
							six winning numbers drawn, regardless of order. The
							random numbers are generated using Chainlink VRF for
							true randomness.
						</p>
					</div>

					<div>
						<h3 className="text-2xl font-semibold mb-2">
							Prize Distribution
						</h3>
						<p className="text-gray-200">
							The prize pool consists of all ticket purchases for
							the round, minus a small 1% fee. If there are
							multiple winners, the prize is distributed equally
							among all winning tickets that have been registered.
						</p>
					</div>

					<div>
						<h3 className="text-2xl font-semibold mb-2">
							Important: Don&apos;t Miss Registration!
						</h3>
						<p className="text-gray-200">
							Even if you have winning numbers, you must register
							your ticket during the registration period (3 hours
							after drawing) to be eligible for prizes. Set
							reminders to check your tickets when the drawing
							phase begins.
						</p>
					</div>
				</div>
			</section>

			<section className="bg-gray-800/50 rounded-lg my-8 p-6 backdrop-blur-sm">
				<h2 className="text-3xl font-bold mb-6 text-primary">FAQ</h2>

				<div className="space-y-6">
					<div>
						<h3 className="text-2xl font-semibold mb-2">
							What happens if not enough tickets are sold?
						</h3>
						<p className="text-gray-200">
							If the minimum number of tickets isn&apos;t reached
							by the end of the round, the round will be
							automatically extended by 3 days.
						</p>
					</div>

					<div>
						<h3 className="text-2xl font-semibold mb-2">
							Can I see my previous tickets?
						</h3>
						<p className="text-gray-200">
							Yes, you can view all your tickets from current and
							previous rounds in the &quot;My Tickets&quot;
							section.
						</p>
					</div>

					<div>
						<h3 className="text-2xl font-semibold mb-2">
							How do I know if I won?
						</h3>
						<p className="text-gray-200">
							After winning numbers are drawn, check your tickets
							in the &quot;My Tickets&quot; section. Winning
							tickets will be highlighted. Remember to register
							your winning tickets within the 3-hour registration
							window.
						</p>
					</div>

					<div>
						<h3 className="text-2xl font-semibold mb-2">
							What if no one wins?
						</h3>
						<p className="text-gray-200">
							If no winning tickets are registered in a round, the
							entire prize pool rolls over to the next round,
							creating a bigger jackpot.
						</p>
					</div>
				</div>
			</section>

			<div className="text-center mb-5">
				<Link
					href="/buy-ticket"
					className="inline-block px-8 py-4 bg-primary text-white font-bold text-lg rounded-full hover:bg-primary/70 transition-colors duration-300"
				>
					Ready to Play? Buy Tickets Now
				</Link>
			</div>
		</main>
	);
}
