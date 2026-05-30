import React, { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Icons8 } from "@/components/ui/icons8";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/apiClient";
import { toast } from "sonner";
import { Category } from "./page";

interface CategoryModalProps {
  isOpen: boolean;
  onClose: () => void;
  category: Category | null;
}

export function CategoryModal({ isOpen, onClose, category }: CategoryModalProps) {
  const queryClient = useQueryClient();
  const [name, setName] = useState("");
  const [price, setPrice] = useState("");

  useEffect(() => {
    if (isOpen) {
      setName(category?.name || "");
      setPrice(category?.price ? String(category.price) : "");
    }
  }, [isOpen, category]);

  const mutation = useMutation({
    mutationFn: async (data: { name: string; price: number }) => {
      if (category) {
        await apiClient.patch(`/api/vehicles/categories/${category.id}`, data);
      } else {
        await apiClient.post(`/api/vehicles/categories`, data);
      }
    },
    onSuccess: () => {
      toast.success(`Category ${category ? "updated" : "created"} successfully`);
      queryClient.invalidateQueries({ queryKey: ["vehicle-categories"] });
      onClose();
    },
    onError: (err: any) => {
      toast.error(err.response?.data?.message || `Failed to ${category ? "update" : "create"} category`);
    }
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return toast.error("Category name is required");
    const parsedPrice = parseFloat(price);
    if (isNaN(parsedPrice) || parsedPrice < 0) return toast.error("Invalid price");

    mutation.mutate({ name: name.trim(), price: parsedPrice });
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-background/80 backdrop-blur-sm z-50"
            onClick={onClose}
          />
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            className="fixed left-[50%] top-[50%] z-50 w-full max-w-md translate-x-[-50%] translate-y-[-50%] p-6"
          >
            <form onSubmit={handleSubmit} className="bg-card border border-border shadow-2xl rounded-3xl overflow-hidden flex flex-col">
              
              <div className="flex items-center justify-between px-8 py-6 border-b border-border/50 bg-secondary/10">
                <h2 className="text-xl font-black uppercase tracking-widest text-foreground">
                  {category ? "Edit Category" : "New Category"}
                </h2>
                <button
                  type="button"
                  onClick={onClose}
                  className="w-8 h-8 rounded-full hover:bg-secondary/80 flex items-center justify-center transition-colors text-muted-foreground"
                >
                  <Icons8 icon="multiply" className="w-4 h-4" />
                </button>
              </div>

              <div className="p-8 flex flex-col gap-6">
                <div>
                  <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground block mb-2">Category Name</label>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="e.g. Sedan, SUV, Bodaboda"
                    className="w-full h-12 px-4 bg-background border border-border rounded-xl text-[13px] font-bold text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                  />
                </div>

                <div>
                  <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground block mb-2">Default Price (RWF)</label>
                  <input
                    type="number"
                    value={price}
                    onChange={(e) => setPrice(e.target.value)}
                    placeholder="e.g. 1000"
                    className="w-full h-12 px-4 bg-background border border-border rounded-xl text-[13px] font-bold text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                  />
                </div>
              </div>

              <div className="p-6 border-t border-border/50 bg-secondary/10 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={onClose}
                  className="px-6 py-2 rounded-xl text-[11px] font-bold uppercase tracking-widest bg-secondary text-muted-foreground hover:bg-secondary/80 hover:text-foreground transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={mutation.isPending}
                  className="px-6 py-2 rounded-xl text-[11px] font-black uppercase tracking-widest bg-primary text-white hover:bg-primary/90 transition-colors disabled:opacity-50"
                >
                  {mutation.isPending ? "Saving..." : "Save Category"}
                </button>
              </div>

            </form>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
