import prisma from "./prisma";

export async function getCurrencySymbol(): Promise<string> {
  try {
    const setting = await prisma.systemSetting.findUnique({
      where: { key: "CURRENCY_SYMBOL" }
    });
    return setting?.value || "TSh";
  } catch (error) {
    console.error("Error fetching currency symbol:", error);
    return "TSh";
  }
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
