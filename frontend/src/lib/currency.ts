export async function getCurrencySymbol(): Promise<string> {
  return "TSh";
}

export function formatCurrency(amount: number | string, symbol: string): string {
  const numericAmount = typeof amount === "string" ? parseFloat(amount) : amount;
  if (isNaN(numericAmount)) return `${symbol} 0`;
  
  // Format with commas
  const formatted = numericAmount.toLocaleString("en-US", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  });
  
  return `${symbol} ${formatted}`;
}
