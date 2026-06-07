"use client";

import React, { createContext, useContext, useEffect, useState } from "react";
import { useTheme } from "next-themes";

type FontSize = "small" | "normal" | "large" | "extra-large";
type FontFamily = "geist" | "inter" | "outfit" | "montserrat";

const fontSizes: Record<FontSize, string> = {
  small: "14px",
  normal: "16px",
  large: "18px",
  "extra-large": "20px",
};

const fontFamilies: Record<FontFamily, string> = {
  geist: "var(--font-geist-sans), sans-serif",
  inter: "var(--font-inter), sans-serif",
  outfit: "var(--font-outfit), sans-serif",
  montserrat: "var(--font-montserrat), sans-serif",
};

const hexToHslValues = (hex: string): string => {
  let r = 0, g = 0, b = 0;
  if (hex.length === 4) {
    r = parseInt(hex[1] + hex[1], 16);
    g = parseInt(hex[2] + hex[2], 16);
    b = parseInt(hex[3] + hex[3], 16);
  } else if (hex.length === 7) {
    r = parseInt(hex.substring(1, 3), 16);
    g = parseInt(hex.substring(3, 5), 16);
    b = parseInt(hex.substring(5, 7), 16);
  }
  r /= 255; g /= 255; b /= 255;
  const max = Math.max(r, g, b), min = Math.min(r, g, b);
  let h = 0, s, l = (max + min) / 2;
  if (max === min) {
    h = s = 0;
  } else {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r: h = (g - b) / d + (g < b ? 6 : 0); break;
      case g: h = (b - r) / d + 2; break;
      case b: h = (r - g) / d + 4; break;
    }
    h /= 6;
  }
  return `${Math.round(h * 360)} ${Math.round(s * 100)}% ${Math.round(l * 100)}%`;
};

type LayoutWidth = "full" | "fixed";

interface AppearanceContextType {
  fontSize: FontSize;
  setFontSize: (size: FontSize) => void;
  fontFamily: FontFamily;
  setFontFamily: (family: FontFamily) => void;
  accentColor: string;
  setAccentColor: (color: string) => void;
  sidebarTheme: "light" | "dark";
  setSidebarTheme: (theme: "light" | "dark") => void;
  layoutWidth: "full" | "fixed";
  setLayoutWidth: (width: "full" | "fixed") => void;
  showCaption: boolean;
  setShowCaption: (show: boolean) => void;
  themeLayout: "ltr" | "rtl";
  setThemeLayout: (layout: "ltr" | "rtl") => void;
  siteName: string;
  setSiteName: (name: string) => void;
  sidebarConfig: SidebarModule[];
  setSidebarConfig: (config: SidebarModule[]) => void;
}

export interface SidebarModule {
  id: string;
  label: string;
  icon: string;
  href: string;
  visible: boolean;
  isGif?: boolean;
  children?: { id: string; label: string; href: string; visible: boolean }[];
}

const defaultSidebarConfig: SidebarModule[] = [
  { id: "dashboard", label: "Dashboard", icon: "dashboard", href: "/", visible: true },
  { id: "surveillance", label: "Surveillance", icon: "security-camera", href: "/surveillance", visible: true },
  { 
    id: "vehicles", 
    label: "Vehicles", 
    icon: "car", 
    href: "/vehicles", 
    visible: true, 
    isGif: true,
    children: [
      { id: "categories", label: "Categories", href: "/vehicles/categories", visible: true }
    ]
  },
  { id: "reports", label: "Reports & Financials", icon: "combo-chart", href: "/reports", visible: true },
  { id: "expenses", label: "Expenses", icon: "wallet", href: "/expenses", visible: true },
  { id: "staff", label: "Staff & Users", icon: "user-male-circle", href: "/staff", visible: true },
  { id: "administration", label: "Administration", icon: "briefcase", href: "/administration", visible: true },
];

const AppearanceContext = createContext<AppearanceContextType | undefined>(undefined);

export function AppearanceProvider({ children }: { children: React.ReactNode }) {
  const { theme, setTheme } = useTheme();
  const [fontSize, setFontSizeState] = useState<FontSize>("normal");
  const [fontFamily, setFontFamilyState] = useState<FontFamily>("geist");
  const [accentColor, setAccentColorState] = useState<string>("#04a9f5");
  const [layoutWidth, setLayoutWidthState] = useState<LayoutWidth>("full");
  const [showCaption, setShowCaptionState] = useState<boolean>(true);
  const [sidebarTheme, setSidebarThemeState] = useState<"light" | "dark">("dark");
  const [themeLayout, setThemeLayoutState] = useState<"ltr" | "rtl">("ltr");
  const [siteName, setSiteNameState] = useState<string>("Parking System");
  const [sidebarConfig, setSidebarConfigState] = useState<SidebarModule[]>(defaultSidebarConfig);

  useEffect(() => {
    // 1. Initial Load from LocalStorage (Instant UI)
    const savedSiteName = localStorage.getItem("parking-site-name");
    if (savedSiteName) setSiteNameState(savedSiteName);

    const savedSidebarConfig = localStorage.getItem("parking-sidebar-config");
    if (savedSidebarConfig) {
      try {
        setSidebarConfigState(JSON.parse(savedSidebarConfig));
      } catch (e) {
        console.error("Failed to parse sidebar config", e);
      }
    }
    const savedSize = localStorage.getItem("font-size") as FontSize;
    if (savedSize && fontSizes[savedSize]) {
      setFontSizeState(savedSize);
      document.documentElement.style.setProperty("--font-size", fontSizes[savedSize]);
    }
    const savedColor = localStorage.getItem("parking-accent-color");
    if (savedColor) {
      setAccentColorState(savedColor);
      document.documentElement.style.setProperty("--primary", savedColor);
      document.documentElement.style.setProperty("--ring", savedColor);
    }
    const savedWidth = localStorage.getItem("parking-layout-width") as LayoutWidth;
    if (savedWidth) setLayoutWidthState(savedWidth);
    const savedCaption = localStorage.getItem("parking-sidebar-caption");
    if (savedCaption !== null) setShowCaptionState(savedCaption === "true");
    const savedFamily = localStorage.getItem("font-family") as FontFamily;
    if (savedFamily && fontFamilies[savedFamily]) {
      setFontFamilyState(savedFamily);
      document.documentElement.style.setProperty("--font-family", fontFamilies[savedFamily]);
    }
    const savedSidebarTheme = localStorage.getItem("parking-sidebar-theme") as "light" | "dark";
    if (savedSidebarTheme) setSidebarThemeState(savedSidebarTheme);
    const savedThemeLayout = localStorage.getItem("parking-theme-layout") as "ltr" | "rtl";
    if (savedThemeLayout) {
      setThemeLayoutState(savedThemeLayout);
      document.documentElement.dir = savedThemeLayout;
    }
  }, []);

  const setFontSize = (size: FontSize) => {
    setFontSizeState(size);
    localStorage.setItem("font-size", size);
    document.documentElement.style.setProperty("--font-size", fontSizes[size]);
  };

  const setFontFamily = (family: FontFamily) => {
    setFontFamilyState(family);
    localStorage.setItem("font-family", family);
    document.documentElement.style.setProperty("--font-family", fontFamilies[family]);
  };

  const setAccentColor = (color: string) => {
    setAccentColorState(color);
    localStorage.setItem("parking-accent-color", color);
    document.documentElement.style.setProperty("--primary", color);
    document.documentElement.style.setProperty("--ring", color);
  };

  const setLayoutWidth = (width: LayoutWidth) => {
    setLayoutWidthState(width);
    localStorage.setItem("parking-layout-width", width);
  };

  const setShowCaption = (show: boolean) => {
    setShowCaptionState(show);
    localStorage.setItem("parking-sidebar-caption", String(show));
  };

  const setSidebarTheme = (theme: "light" | "dark") => {
    setSidebarThemeState(theme);
    localStorage.setItem("parking-sidebar-theme", theme);
  };

  const setThemeLayout = (layout: "ltr" | "rtl") => {
    setThemeLayoutState(layout);
    localStorage.setItem("parking-theme-layout", layout);
    document.documentElement.dir = layout;
  };

const setSiteName = (name: string) => {
    setSiteNameState(name);
    localStorage.setItem("parking-site-name", name);
    document.title = `${name} | Car Services`; 
  };

  const setSidebarConfig = (config: SidebarModule[]) => {
    setSidebarConfigState(config);
    localStorage.setItem("parking-sidebar-config", JSON.stringify(config));
  };

  return (
    <AppearanceContext.Provider value={{
      fontSize, setFontSize,
      fontFamily, setFontFamily,
      accentColor, setAccentColor,
      layoutWidth, setLayoutWidth,
      showCaption, setShowCaption,
      sidebarTheme, setSidebarTheme,
      themeLayout, setThemeLayout,
      siteName, setSiteName,
      sidebarConfig, setSidebarConfig
    }}>
      {children}
    </AppearanceContext.Provider>
  );
}

export const useAppearance = () => {
  const context = useContext(AppearanceContext);
  if (!context) throw new Error("useAppearance must be used within an AppearanceProvider");
  return context;
};
