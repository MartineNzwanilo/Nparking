import type { Metadata } from "next";
import { Geist, Geist_Mono, Inter, Outfit, Montserrat, Public_Sans } from "next/font/google";
import "./globals.css";
import QueryProvider from "@/providers/QueryProvider";
import { ThemeProvider } from "@/providers/ThemeProvider";
import { AppearanceProvider } from "@/providers/AppearanceProvider";
import { Shell } from "@/components/layout/Shell";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

const outfit = Outfit({
  variable: "--font-outfit",
  subsets: ["latin"],
});

const montserrat = Montserrat({
  variable: "--font-montserrat",
  subsets: ["latin"],
});

const publicSans = Public_Sans({
  variable: "--font-public-sans",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Smart Parking Management",
  description: "Enterprise Parking System",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning className={`${geistSans.variable} ${geistMono.variable} ${inter.variable} ${outfit.variable} ${montserrat.variable} ${publicSans.variable}`}>
       <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (function() {
                try {
                  var size = localStorage.getItem('font-size');
                  var family = localStorage.getItem('font-family');
                  
                  var fontSizes = { small: '14px', normal: '16px', large: '18px', 'extra-large': '20px' };
                  var fontFamilies = {
                    geist: 'var(--font-geist-sans), sans-serif',
                    inter: 'var(--font-inter), sans-serif',
                    outfit: 'var(--font-outfit), sans-serif',
                    montserrat: 'var(--font-montserrat), sans-serif',
                    public: 'var(--font-public-sans), sans-serif'
                  };

                  if (size && fontSizes[size]) {
                    document.documentElement.style.setProperty('--font-size', fontSizes[size]);
                  }
                  
                  var defaultFamily = fontFamilies.public;
                  if (family && fontFamilies[family]) {
                    document.documentElement.style.setProperty('--font-family', fontFamilies[family]);
                  } else {
                    document.documentElement.style.setProperty('--font-family', defaultFamily);
                  }
                } catch (e) {}
              })();
            `,
          }}
        />
      </head>
      <body className="antialiased bg-background text-foreground min-h-screen">
        <ThemeProvider attribute="class" defaultTheme="dark" enableSystem>
          <AppearanceProvider>
            <QueryProvider>
              <Shell>{children}</Shell>
            </QueryProvider>
          </AppearanceProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
