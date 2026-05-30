"use client";

import React, { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useBreadcrumbStore } from "@/store/useBreadcrumbStore";
import { Icons8 } from "@/components/ui/icons8";
import { cn, formatCurrency } from "@/lib/utils";
import { apiClient } from "@/lib/apiClient";
import { CategoryModal } from "./CategoryModal";
import { toast } from "sonner";

export interface Category {
  id: string;
  name: string;
  price: number;
}

export default function CategoriesPage() {
  const { setBreadcrumbs } = useBreadcrumbStore();
  const queryClient = useQueryClient();
  const [modalOpen, setModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);

  useEffect(() => {
    setBreadcrumbs([
      { label: "Dashboard", href: "/" },
      { label: "Fleet", href: "/vehicles" },
      { label: "Categories", href: "/vehicles/categories" },
    ]);
  }, [setBreadcrumbs]);

  const { data: categories, isLoading, isError } = useQuery<Category[]>({
    queryKey: ["vehicle-categories"],
    queryFn: async () => {
      const res = await apiClient.get("/api/vehicles/categories");
      return res.data;
    },
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      await apiClient.delete(`/api/vehicles/categories/${id}`);
    },
    onSuccess: () => {
      toast.success("Category deleted successfully");
      queryClient.invalidateQueries({ queryKey: ["vehicle-categories"] });
    },
    onError: (err: any) => {
      toast.error(err.response?.data?.message || "Failed to delete category");
    }
  });

  const handleEdit = (cat: Category) => {
    setEditingCategory(cat);
    setModalOpen(true);
  };

  const handleAdd = () => {
    setEditingCategory(null);
    setModalOpen(true);
  };

  const handleDelete = (id: string) => {
    if (confirm("Are you sure you want to delete this category?")) {
      deleteMutation.mutate(id);
    }
  };

  return (
    <div className="w-full h-full flex flex-col gap-6">
      <div className="flex flex-col md:flex-row items-center justify-between gap-4 w-full">
        <div>
          <h2 className="text-2xl font-black uppercase tracking-widest text-foreground">Categories</h2>
          <p className="text-[12px] font-bold text-muted-foreground mt-1 uppercase tracking-widest">Manage vehicle classifications & pricing</p>
        </div>
        <button 
          onClick={handleAdd}
          className="h-12 px-6 rounded-2xl font-black text-[11px] uppercase tracking-widest flex items-center justify-center gap-2 bg-primary hover:bg-primary/90 text-white shadow-xl shadow-primary/20 transition-all active:scale-95 shrink-0"
        >
          <Icons8 icon="plus" className="w-4 h-4 invert" />
          Add Category
        </button>
      </div>

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="glass border border-border rounded-3xl overflow-hidden shadow-sm flex flex-col min-h-[400px]"
      >
        <div className="overflow-x-auto w-full">
          <table className="w-full text-left border-collapse min-w-[600px]">
            <thead>
              <tr className="border-b border-border/50 bg-secondary/20">
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground">Category Name</th>
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground">Default Price</th>
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {isLoading && (
                Array.from({ length: 3 }).map((_, i) => (
                  <tr key={`skeleton-${i}`} className="border-b border-border/30">
                    <td className="px-6 py-4"><div className="h-6 bg-secondary/50 rounded-xl animate-pulse w-32" /></td>
                    <td className="px-6 py-4"><div className="h-4 bg-secondary/50 rounded animate-pulse w-24" /></td>
                    <td className="px-6 py-4"><div className="h-4 bg-secondary/50 rounded animate-pulse w-16 ml-auto" /></td>
                  </tr>
                ))
              )}

              {isError && !isLoading && (
                <tr>
                    <td colSpan={3} className="p-12 text-center">
                        <div className="flex flex-col items-center justify-center gap-3">
                            <Icons8 icon="error" className="w-12 h-12 text-destructive opacity-50" />
                            <p className="text-[13px] font-bold text-muted-foreground">Failed to load categories.</p>
                        </div>
                    </td>
                </tr>
              )}

              {!isLoading && !isError && categories && categories.length === 0 && (
                <tr>
                    <td colSpan={3} className="p-16 text-center">
                        <p className="text-[12px] font-bold text-muted-foreground uppercase tracking-widest">No Categories Found</p>
                    </td>
                </tr>
              )}

              {!isLoading && !isError && categories && categories.map((cat) => (
                <tr key={cat.id} className="border-b border-border/30 hover:bg-muted/20 transition-colors">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
                        <Icons8 icon="car" className="w-5 h-5" />
                      </div>
                      <span className="text-[14px] font-black uppercase tracking-widest text-foreground">{cat.name}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-[14px] font-black text-emerald-500">
                      {formatCurrency(cat.price)}
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex items-center justify-end gap-4">
                      <button 
                        onClick={() => handleEdit(cat)}
                        className="text-[11px] font-bold text-primary hover:underline uppercase tracking-wider"
                      >
                        Edit
                      </button>
                      <button 
                        onClick={() => handleDelete(cat.id)}
                        disabled={deleteMutation.isPending}
                        className="text-[11px] font-bold text-destructive hover:underline uppercase tracking-wider disabled:opacity-50"
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </motion.div>

      <CategoryModal 
        isOpen={modalOpen} 
        onClose={() => setModalOpen(false)} 
        category={editingCategory} 
      />
    </div>
  );
}
