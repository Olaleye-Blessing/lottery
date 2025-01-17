import type { Metadata } from 'next';

// TODO: Update this
const siteUrl = ``;

export const appDescription = '';

export const metadata: Metadata = {
	title: {
		default: 'Decentralized Lottery — Leto',
		template: '%s | Crowdchain',
	},
	description: appDescription,
	keywords: ['Decentralized Lottery', 'Smart Contract Lottery'],
	authors: [
		{ name: 'Blessing Olaleye', url: 'https://www.blessingolaleye.xyz' },
	],
	creator: 'Blessing Olaleye',
	publisher: 'Blessing Olaleye',

	openGraph: {
		type: 'website',
		locale: 'en_US',
		url: siteUrl,
		title: 'Decentralized Lottery — Leto',
		description: appDescription,
		siteName: 'Leto',
		images: [],
	},

	twitter: {
		card: 'summary_large_image',
		title: 'Decentralized Lottery — Leto',
		description: appDescription,
		creator: '@_jongbo',
		images: ['/android-chrome-512x512.png'],
	},

	icons: {
		other: [],
	},
	manifest: '',
};
