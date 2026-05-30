"use client"

import React from "react";
import { useAppearance } from "@/providers/AppearanceProvider";
import { cn } from "@/lib/utils";

interface ContainerProps {
  children: React.ReactNode;
  className?: string;
  isHeader?: boolean;
}

export function Container({ children, className, isHeader = false }: ContainerProps) {
  const { layoutWidth } = useAppearance();

  return (
    <div 
      className={cn(
        "w-full transition-all duration-300",
        layoutWidth === "fixed" ? "max-w-7xl mx-auto" : "max-w-full",
        className
      )}
    >
      {children}
    </div>
  );
}
