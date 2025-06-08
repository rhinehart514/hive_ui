import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'HIVE - Build Your Campus Community',
  description: 'The sophisticated platform where students create, connect, and cultivate meaningful campus experiences through customizable spaces and intelligent tools.',
  keywords: ['campus', 'community', 'students', 'university', 'collaboration', 'social'],
  authors: [{ name: 'HIVE Team' }],
  creator: 'HIVE',
  openGraph: {
    title: 'HIVE - Build Your Campus Community',
    description: 'The sophisticated platform where students create, connect, and cultivate meaningful campus experiences.',
    url: 'https://hive.university',
    siteName: 'HIVE',
    images: [
      {
        url: '/images/og-image.jpg',
        width: 1200,
        height: 630,
        alt: 'HIVE - Campus Community Platform',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'HIVE - Build Your Campus Community',
    description: 'The sophisticated platform where students create, connect, and cultivate meaningful campus experiences.',
    images: ['/images/twitter-image.jpg'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  viewport: {
    width: 'device-width',
    initialScale: 1,
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="scroll-smooth">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap"
          rel="stylesheet"
        />
        <meta name="theme-color" content="#0D0D0D" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
      </head>
      <body className="font-sf antialiased bg-hive-black text-white selection:bg-hive-gold selection:text-hive-black">
        {children}
      </body>
    </html>
  )
} 