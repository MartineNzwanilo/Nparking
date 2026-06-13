"use client"

import React, { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query"
import { useBreadcrumbStore } from "@/store/useBreadcrumbStore"
import { Icons8 } from "@/components/ui/icons8"
import { cn } from "@/lib/utils"
import { apiClient } from "@/lib/apiClient"
import { toast } from "sonner"
import { StaffModal } from "./StaffModal"
import { useSiteStore } from "@/store/useSiteStore"

export default function StaffPage() {
  const { setBreadcrumbs } = useBreadcrumbStore()
  const queryClient = useQueryClient()
  const { activeSiteId } = useSiteStore()
  
  const [modalOpen, setModalOpen] = useState(false)
  const [editingStaff, setEditingStaff] = useState<any | null>(null)

  useEffect(() => {
    setBreadcrumbs([
      { label: "Dashboard", href: "/" },
      { label: "Staff & Users", href: "/staff" }
    ])
  }, [setBreadcrumbs])

  const { data: staff, isLoading, isError } = useQuery({
    queryKey: ["staff-users", activeSiteId],
    queryFn: async () => {
      const res = await apiClient.get(`/api/users?siteId=${activeSiteId}`)
      return res.data
    }
  })

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      await apiClient.delete(`/api/users/${id}`)
    },
    onSuccess: () => {
      toast.success("Staff member terminated successfully")
      queryClient.invalidateQueries({ queryKey: ["staff-users"] })
    },
    onError: (err: any) => {
      toast.error(err.response?.data?.message || "Failed to terminate staff")
    }
  })

  const handleAdd = () => {
    setEditingStaff(null)
    setModalOpen(true)
  }

  const handleEdit = (user: any) => {
    setEditingStaff(user)
    setModalOpen(true)
  }

  const handleDelete = (id: string) => {
    if (confirm("Are you sure you want to terminate this staff member's access?")) {
      deleteMutation.mutate(id)
    }
  }

  return (
    <div className="w-full h-full flex flex-col gap-6">

      <div className="w-full flex justify-end">
        <button 
          onClick={handleAdd}
          className="h-10 px-8 rounded-xl font-black text-[11px] uppercase tracking-widest flex items-center gap-2 bg-emerald-500 hover:bg-emerald-600 text-white shadow-xl shadow-emerald-500/20 transition-all active:scale-95"
        >
          <Icons8 icon="plus" className="w-4 h-4 invert" />
          Add Staff Member
        </button>
      </div>

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="glass border border-border rounded-3xl overflow-hidden shadow-sm"
      >
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border/50 bg-secondary/20">
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground">User</th>
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground">Role</th>
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground">Assigned Site</th>
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground">Phone</th>
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-[12px] font-bold text-muted-foreground">
                    <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-2"></div>
                    Loading staff directory...
                  </td>
                </tr>
              ) : isError ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-[12px] font-bold text-muted-foreground">
                    Failed to load staff directory.
                  </td>
                </tr>
              ) : staff?.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-[12px] font-bold text-muted-foreground">
                    No active staff members found.
                  </td>
                </tr>
              ) : (
                staff?.map((user: any) => (
                  <tr key={user.id} className="border-b border-border/30 hover:bg-muted/20 transition-colors group">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center overflow-hidden shrink-0">
                          <Icons8 icon={user.role === 'ADMIN' ? 'briefcase' : user.role === 'LODGEMAN' ? 'home' : 'road-worker'} className="w-5 h-5 text-primary" />
                        </div>
                        <span className="text-[13px] font-black uppercase tracking-widest text-foreground">{user.name}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className={cn(
                        "px-3 py-1 rounded-full text-[9px] font-black uppercase tracking-widest border",
                        user.role === 'ADMIN' ? "bg-amber-500/10 text-amber-500 border-amber-500/20" : 
                        user.role === 'LODGEMAN' ? "bg-emerald-500/10 text-emerald-500 border-emerald-500/20" :
                        "bg-blue-500/10 text-blue-500 border-blue-500/20"
                      )}>
                        {user.role}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-[12px] font-bold text-muted-foreground flex items-center gap-2">
                        {user.site ? (
                          <>
                            <Icons8 icon="parking" className="w-3 h-3" />
                            {user.site.name}
                          </>
                        ) : (
                          "Global (All Sites)"
                        )}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-[12px] font-bold text-muted-foreground">{user.phone}</td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button 
                          onClick={() => handleEdit(user)}
                          className="w-8 h-8 rounded-xl bg-secondary text-primary hover:bg-primary hover:text-white flex items-center justify-center transition-colors"
                        >
                          <Icons8 icon="edit" className="w-4 h-4" />
                        </button>
                        <button 
                          onClick={() => handleDelete(user.id)}
                          disabled={deleteMutation.isPending}
                          className="w-8 h-8 rounded-xl bg-secondary text-destructive hover:bg-destructive hover:text-white flex items-center justify-center transition-colors disabled:opacity-50"
                        >
                          <Icons8 icon="trash" className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </motion.div>

      <StaffModal 
        isOpen={modalOpen} 
        onClose={() => setModalOpen(false)} 
        staff={editingStaff} 
      />
    </div>
  )
}
