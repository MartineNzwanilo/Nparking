"use client"

import { useState, useEffect, useRef } from 'react'

interface StickyHeaderProps {
    children: React.ReactNode
    className?: string
}

export function StickyHeader({ children, className = "" }: StickyHeaderProps) {
    const [isScrolled, setIsScrolled] = useState(false)
    const [isMounted, setIsMounted] = useState(false)
    const sentinelRef = useRef<HTMLDivElement>(null)

    useEffect(() => {
        setIsMounted(true)
        const mainElement = document.querySelector('main')
        if (!mainElement) return

        const observer = new IntersectionObserver(
            ([entry]) => {
                // When sentinel is NOT intersecting (scrolled past), set isScrolled to true
                setIsScrolled(!entry.isIntersecting)
            },
            { 
                root: mainElement,
                threshold: 0,
                // Trigger transition slightly after start of scroll
                rootMargin: '-30px 0px 0px 0px' 
            }
        )

        if (sentinelRef.current) {
            observer.observe(sentinelRef.current)
        }
        
        return () => observer.disconnect()
    }, [])

    // Prevent hydration mismatch by rendering static expanded state
    if (!isMounted) {
        return (
            <div className={`sticky top-0 z-50 p-4 lg:p-8 ${className}`}>
                <div className="w-full bg-background/80 backdrop-blur-xl border-b border-border/10 pb-4 shadow-[0_10px_30px_-10px_rgba(0,0,0,0.1)]">
                    {children}
                </div>
            </div>
        )
    }

    return (
        <>
            {/* Stable sentinel - Does not shift with the header */}
            <div ref={sentinelRef} className="h-0 w-full pointer-events-none" aria-hidden="true" />
            
            <div className={`sticky top-[60px] md:top-[70px] z-50 transition-all duration-300 ease-out font-inter ${className}`}>
                <div 
                    className={`transition-all duration-500 ease-[cubic-bezier(0.16,1,0.3,1)] w-full ${
                        isScrolled 
                            ? 'bg-card/90 backdrop-blur-2xl rounded-3xl border border-border/30 shadow-[0_30px_60px_-15px_rgba(0,0,0,0.5)] px-4 md:px-8 py-3 max-w-7xl mx-auto mt-2 md:mt-4' 
                            : 'bg-background/80 backdrop-blur-xl border-b border-border/10 p-4 lg:p-8 pb-6'
                    }`}
                >
                    {children}
                </div>
            </div>
        </>
    )
}
