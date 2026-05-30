"use client"

import * as React from "react"
import { cn } from "@/lib/utils"

interface SwitchProps {
    checked?: boolean
    defaultChecked?: boolean
    onCheckedChange?: (checked: boolean) => void
    disabled?: boolean
    className?: string
    id?: string
}

const Switch = React.forwardRef<HTMLButtonElement, SwitchProps>(
    ({ checked, defaultChecked, onCheckedChange, disabled, className, id }, ref) => {
        const [internalChecked, setInternalChecked] = React.useState(defaultChecked ?? false)
        const isControlled = checked !== undefined
        const isChecked = isControlled ? checked : internalChecked

        const handleClick = () => {
            if (disabled) return
            if (!isControlled) {
                setInternalChecked(prev => !prev)
            }
            onCheckedChange?.(!isChecked)
        }

        return (
            <button
                ref={ref}
                id={id}
                type="button"
                role="switch"
                aria-checked={isChecked}
                disabled={disabled}
                onClick={handleClick}
                className={cn(
                    "relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center rounded-full border-2 border-transparent transition-colors duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50",
                    isChecked ? "bg-primary" : "bg-secondary",
                    className
                )}
            >
                <span
                    className={cn(
                        "pointer-events-none block h-4 w-4 rounded-full bg-white shadow-lg ring-0 transition-transform duration-200",
                        isChecked ? "translate-x-5" : "translate-x-0.5"
                    )}
                />
            </button>
        )
    }
)
Switch.displayName = "Switch"

export { Switch }
