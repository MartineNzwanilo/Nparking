import { cn } from "@/lib/utils";

export const Icons8 = ({ icon, className, isGif = false }: { icon: string, className?: string, isGif?: boolean }) => {
  const ext = isGif ? "gif" : "png";
  
  return (
    <img 
      src={`/icons/${icon}.${ext}`} 
      alt={icon} 
      className={cn("w-6 h-6 object-contain", className)} 
    />
  );
};
