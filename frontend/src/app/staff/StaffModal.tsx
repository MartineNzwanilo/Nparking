import React, { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Icons8 } from "@/components/ui/icons8";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/apiClient";
import { toast } from "sonner";

interface StaffModalProps {
  isOpen: boolean;
  onClose: () => void;
  staff: any | null;
}

export function StaffModal({ isOpen, onClose, staff }: StaffModalProps) {
  const queryClient = useQueryClient();
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [role, setRole] = useState("WATCHMAN");
  const [siteId, setSiteId] = useState("");
  const [autoPrint, setAutoPrint] = useState(true);
  const [autoSendEmail, setAutoSendEmail] = useState(false);
  const [autoSendSms, setAutoSendSms] = useState(false);

  const { data: sites } = useQuery({
    queryKey: ["parking-sites"],
    queryFn: async () => {
      const res = await apiClient.get("/api/sites");
      return res.data;
    },
    enabled: isOpen,
  });

  useEffect(() => {
    if (isOpen) {
      setName(staff?.name || "");
      setPhone(staff?.phone || "");
      setEmail(staff?.email || "");
      setPassword("");
      setRole(staff?.role || "WATCHMAN");
      setSiteId(staff?.siteId || "");
      setAutoPrint(staff?.autoPrint !== undefined ? staff.autoPrint : true);
      setAutoSendEmail(staff?.autoSendEmail !== undefined ? staff.autoSendEmail : false);
      setAutoSendSms(staff?.autoSendSms !== undefined ? staff.autoSendSms : false);
    }
  }, [isOpen, staff]);

  const mutation = useMutation({
    mutationFn: async (data: any) => {
      if (staff?.id) {
        await apiClient.patch(`/api/users/${staff.id}`, data);
      } else {
        await apiClient.post(`/api/users`, data);
      }
    },
    onSuccess: () => {
      toast.success(`Staff member ${staff ? "updated" : "added"} successfully`);
      queryClient.invalidateQueries({ queryKey: ["staff-users"] });
      onClose();
    },
    onError: (err: any) => {
      toast.error(err.response?.data?.message || `Failed to ${staff ? "update" : "add"} staff`);
    }
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !phone.trim() || !role) {
      return toast.error("Please fill in all required fields");
    }

    const payload: any = {
      name: name.trim(),
      phone: phone.trim(),
      role,
      autoPrint,
      autoSendEmail,
      autoSendSms,
      siteId: siteId || null,
    };
    if (email.trim()) payload.email = email.trim();
    if (password) payload.password = password;

    mutation.mutate(payload);
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
                  {staff ? "Edit Staff" : "Add Staff"}
                </h2>
                <button
                  type="button"
                  onClick={onClose}
                  className="w-8 h-8 rounded-full hover:bg-secondary/80 flex items-center justify-center transition-colors text-muted-foreground"
                >
                  <Icons8 icon="multiply" className="w-4 h-4" />
                </button>
              </div>

              <div className="p-8 flex flex-col gap-5 max-h-[60vh] overflow-y-auto">
                <div>
                  <label htmlFor="staff-name" className="text-[10px] font-black uppercase tracking-widest text-muted-foreground block mb-2">Full Name</label>
                  <input
                    id="staff-name"
                    name="name"
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="e.g. John Doe"
                    className="w-full h-12 px-4 bg-background border border-border rounded-xl text-[13px] font-bold text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                  />
                </div>

                <div>
                  <label htmlFor="staff-email" className="text-[10px] font-black uppercase tracking-widest text-muted-foreground block mb-2">Email Address (Optional)</label>
                  <input
                    id="staff-email"
                    name="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="e.g. john@company.com"
                    className="w-full h-12 px-4 bg-background border border-border rounded-xl text-[13px] font-bold text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                  />
                </div>

                <div>
                  <label htmlFor="staff-phone" className="text-[10px] font-black uppercase tracking-widest text-muted-foreground block mb-2">Phone Number</label>
                  <input
                    id="staff-phone"
                    name="phone"
                    type="text"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="e.g. +254 712 345 678"
                    className="w-full h-12 px-4 bg-background border border-border rounded-xl text-[13px] font-bold text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                  />
                </div>

                <div>
                  <label htmlFor="staff-password" className="text-[10px] font-black uppercase tracking-widest text-muted-foreground block mb-2">
                    {staff ? "New Password (Optional)" : "Password"}
                  </label>
                  <input
                    id="staff-password"
                    name="password"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full h-12 px-4 bg-background border border-border rounded-xl text-[13px] font-bold text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label htmlFor="staff-role" className="text-[10px] font-black uppercase tracking-widest text-muted-foreground block mb-2">Role</label>
                    <select
                      id="staff-role"
                      name="role"
                      value={role}
                      onChange={(e) => setRole(e.target.value)}
                      className="w-full h-12 px-4 bg-background border border-border rounded-xl text-[13px] font-bold text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all appearance-none"
                    >
                      <option value="WATCHMAN">Watchman</option>
                      <option value="LODGEMAN">Lodgeman</option>
                      <option value="ADMIN">Admin</option>
                    </select>
                  </div>

                  <div>
                    <label htmlFor="staff-site" className="text-[10px] font-black uppercase tracking-widest text-muted-foreground block mb-2">Assigned Site</label>
                    <select
                      id="staff-site"
                      name="siteId"
                      value={siteId}
                      onChange={(e) => setSiteId(e.target.value)}
                      className="w-full h-12 px-4 bg-background border border-border rounded-xl text-[13px] font-bold text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all appearance-none"
                    >
                      <option value="">Global (No Site)</option>
                      {sites?.map((site: any) => (
                        <option key={site.id} value={site.id}>{site.name}</option>
                      ))}
                    </select>
                  </div>
                </div>

                {role === "WATCHMAN" && (
                  <div className="border border-border/60 bg-secondary/5 p-5 rounded-2xl flex flex-col gap-4 mt-2">
                    <h3 className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Watchman Shift Defaults</h3>
                    
                    <div className="flex items-center justify-between animate-fadeIn">
                      <div className="flex flex-col gap-0.5">
                        <span className="text-[12px] font-bold text-foreground">Auto-Print Entry Ticket</span>
                        <span className="text-[10px] text-muted-foreground">Instantly print QR slip on check-in</span>
                      </div>
                      <button
                        type="button"
                        onClick={() => setAutoPrint(!autoPrint)}
                        className={`w-11 h-6 rounded-full transition-colors relative flex items-center px-1 focus:outline-none ${
                          autoPrint ? "bg-primary" : "bg-muted"
                        }`}
                      >
                        <span
                          className={`w-4 h-4 rounded-full bg-white shadow-sm transition-transform ${
                            autoPrint ? "translate-x-5" : "translate-x-0"
                          }`}
                        />
                      </button>
                    </div>

                    <div className="flex items-center justify-between animate-fadeIn">
                      <div className="flex flex-col gap-0.5">
                        <span className="text-[12px] font-bold text-foreground">Auto-Send Email Ticket</span>
                        <span className="text-[10px] text-muted-foreground">Deliver HTML receipts to drivers</span>
                      </div>
                      <button
                        type="button"
                        onClick={() => setAutoSendEmail(!autoSendEmail)}
                        className={`w-11 h-6 rounded-full transition-colors relative flex items-center px-1 focus:outline-none ${
                          autoSendEmail ? "bg-primary" : "bg-muted"
                        }`}
                      >
                        <span
                          className={`w-4 h-4 rounded-full bg-white shadow-sm transition-transform ${
                            autoSendEmail ? "translate-x-5" : "translate-x-0"
                          }`}
                        />
                      </button>
                    </div>

                    <div className="flex items-center justify-between animate-fadeIn">
                      <div className="flex flex-col gap-0.5">
                        <span className="text-[12px] font-bold text-foreground">Auto-Send Beem SMS</span>
                        <span className="text-[10px] text-muted-foreground">Send dynamic details via unverified INFO</span>
                      </div>
                      <button
                        type="button"
                        onClick={() => setAutoSendSms(!autoSendSms)}
                        className={`w-11 h-6 rounded-full transition-colors relative flex items-center px-1 focus:outline-none ${
                          autoSendSms ? "bg-primary" : "bg-muted"
                        }`}
                      >
                        <span
                          className={`w-4 h-4 rounded-full bg-white shadow-sm transition-transform ${
                            autoSendSms ? "translate-x-5" : "translate-x-0"
                          }`}
                        />
                      </button>
                    </div>
                  </div>
                )}
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
                  {mutation.isPending ? "Saving..." : "Save Staff"}
                </button>
              </div>

            </form>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
