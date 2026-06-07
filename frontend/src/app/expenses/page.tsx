"use client";

import React, { useState, useEffect } from "react";
import { apiClient as api } from "@/lib/apiClient";
import { format } from "date-fns";
import { Icons8 } from "@/components/ui/icons8";
import { Container } from "@/components/layout/Container";
import { StickyHeader } from "@/components/layout/StickyHeader";
import { toast } from "sonner";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";

interface Expense {
  id: string;
  amount: number;
  description?: string;
  date: string;
  category: { id: string; name: string };
  paidToUser?: { id: string; name: string };
}

interface Category {
  id: string;
  name: string;
}

interface User {
  id: string;
  name: string;
  role: string;
}

export default function ExpensesPage() {
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Filters
  const [startDate, setStartDate] = useState<string>(() => {
    const d = new Date();
    d.setDate(d.getDate() - 30);
    return format(d, "yyyy-MM-dd");
  });
  const [endDate, setEndDate] = useState<string>(() => format(new Date(), "yyyy-MM-dd"));
  const [selectedCategory, setSelectedCategory] = useState<string>("All");

  // Modals
  const [isAddExpenseOpen, setIsAddExpenseOpen] = useState(false);
  const [isAddCategoryOpen, setIsAddCategoryOpen] = useState(false);
  const [isPrintModalOpen, setIsPrintModalOpen] = useState(false);

  useEffect(() => {
    fetchData();
    fetchCategories();
    fetchUsers();
  }, [startDate, endDate]);

  const fetchData = async () => {
    setIsLoading(true);
    try {
      const { data } = await api.get(
        `/api/expenses?startDate=${startDate}T00:00:00&endDate=${endDate}T23:59:59`
      );
      setExpenses(data);
    } catch (err) {
      toast.error("Failed to load expenses");
    } finally {
      setIsLoading(false);
    }
  };

  const fetchCategories = async () => {
    try {
      const { data } = await api.get("/api/expenses/categories");
      setCategories(data);
    } catch (err) {
      console.error(err);
    }
  };

  const fetchUsers = async () => {
    try {
      const { data } = await api.get("/api/users");
      setUsers(data);
    } catch (err) {
      console.error(err);
    }
  };

  const filteredExpenses = expenses.filter((exp) => {
    if (selectedCategory === "All") return true;
    return exp.category?.name === selectedCategory;
  });

  const totalAmount = filteredExpenses.reduce((acc, curr) => acc + curr.amount, 0);

  const handlePrint = () => {
    setIsPrintModalOpen(true);
  };

  return (
    <Container className="p-4 md:p-8 max-w-7xl mx-auto space-y-6">
      <StickyHeader>
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 w-full">
          <h1 className="text-2xl font-bold">Expenses Dashboard</h1>
          <div className="flex items-center gap-2 print:hidden">
            <Button variant="outline" size="sm" onClick={() => setIsAddCategoryOpen(true)}>
              <Icons8 icon="tags" className="w-4 h-4 mr-2" />
              Manage Categories
            </Button>
            <Button variant="outline" size="sm" onClick={handlePrint}>
              <Icons8 icon="printer" className="w-4 h-4 mr-2" />
              Export / Print
            </Button>
            <Button size="sm" onClick={() => setIsAddExpenseOpen(true)}>
              <Icons8 icon="plus" className="w-4 h-4 mr-2 text-white" />
              Add Expense
            </Button>
          </div>
        </div>
      </StickyHeader>

      {/* Pro Dashboard Layout - Summary Card */}
      <div className="bg-gradient-to-br from-primary to-[#0C4A6E] rounded-3xl p-6 md:p-8 text-white shadow-xl shadow-primary/20 relative overflow-hidden">
        <div className="absolute right-0 top-0 opacity-10 pointer-events-none scale-150 transform translate-x-1/4 -translate-y-1/4">
          <Icons8 icon="wallet" className="w-64 h-64" />
        </div>
        <div className="relative z-10 flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
          <div>
            <p className="text-white/80 text-sm font-medium mb-1">Total Expenses</p>
            <h1 className="text-4xl md:text-5xl font-bold">TZS {totalAmount.toLocaleString()}</h1>
          </div>

          <div className="flex flex-col sm:flex-row items-end sm:items-center gap-3 bg-black/20 p-2 rounded-2xl print:hidden">
            <div className="flex items-center bg-white/10 rounded-xl px-3 py-2 border border-white/10">
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="bg-transparent text-sm text-white focus:outline-none placeholder-white/50"
              />
            </div>
            <span className="text-white/60">to</span>
            <div className="flex items-center bg-white/10 rounded-xl px-3 py-2 border border-white/10">
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className="bg-transparent text-sm text-white focus:outline-none placeholder-white/50"
              />
            </div>
          </div>
        </div>
      </div>

      {/* Category Filters */}
      <div className="print:hidden">
        <h3 className="text-sm font-bold text-muted-foreground mb-3 uppercase tracking-wider">Filter by Category</h3>
        <div className="flex items-center gap-2 overflow-x-auto pb-2 custom-scrollbar">
          <button
            onClick={() => setSelectedCategory("All")}
            className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all whitespace-nowrap ${
              selectedCategory === "All"
                ? "bg-primary text-primary-foreground shadow-md"
                : "bg-muted text-muted-foreground hover:bg-muted/80"
            }`}
          >
            All Categories
          </button>
          {categories.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setSelectedCategory(cat.name)}
              className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all whitespace-nowrap ${
                selectedCategory === cat.name
                  ? "bg-primary text-primary-foreground shadow-md"
                  : "bg-muted text-muted-foreground hover:bg-muted/80"
              }`}
            >
              {cat.name}
            </button>
          ))}
        </div>
      </div>

      {/* Print Only Header Info */}
      <div className="hidden print:block mb-8">
        <h2 className="text-2xl font-bold mb-2">Expense Report</h2>
        <p className="text-sm text-gray-500">
          Period: {format(new Date(startDate), "MMM dd, yyyy")} - {format(new Date(endDate), "MMM dd, yyyy")}
        </p>
        <p className="text-sm text-gray-500">Category Filter: {selectedCategory}</p>
        <p className="text-sm text-gray-500">Generated on: {format(new Date(), "MMM dd, yyyy HH:mm:ss")}</p>
        <hr className="mt-4 border-gray-300" />
      </div>

      {/* Expense List */}
      <div className="space-y-3">
        {isLoading ? (
          <div className="flex justify-center p-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
          </div>
        ) : filteredExpenses.length === 0 ? (
          <div className="flex flex-col items-center justify-center p-12 text-muted-foreground bg-card rounded-3xl border border-border">
            <Icons8 icon="wallet" className="w-16 h-16 opacity-20 mb-4" />
            <p className="font-medium text-lg">No expenses found</p>
            <p className="text-sm">Try adjusting your filters or record a new expense.</p>
          </div>
        ) : (
          filteredExpenses.map((exp) => {
            const dateStr = format(new Date(exp.date), "MMM dd, yyyy - HH:mm");
            let icon = "wallet";
            let iconBg = "bg-primary/10 text-primary";
            const catLower = exp.category?.name?.toLowerCase() || "";
            if (catLower.includes("salary")) {
              icon = "user-male-circle";
              iconBg = "bg-green-500/10 text-green-500";
            } else if (catLower.includes("fuel")) {
              icon = "gas-station";
              iconBg = "bg-red-500/10 text-red-500";
            } else if (catLower.includes("utility") || catLower.includes("electricity")) {
              icon = "flash-on";
              iconBg = "bg-orange-500/10 text-orange-500";
            }

            return (
              <div
                key={exp.id}
                className="flex items-center justify-between bg-card p-4 rounded-2xl border border-border/50 hover:border-primary/30 transition-all shadow-sm group"
              >
                <div className="flex items-center gap-4">
                  <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${iconBg}`}>
                    <Icons8 icon={icon} className="w-6 h-6" />
                  </div>
                  <div>
                    <h4 className="font-bold text-foreground">{exp.category?.name || "Unknown"}</h4>
                    {exp.description && (
                      <p className="text-sm text-muted-foreground truncate max-w-[200px] md:max-w-[400px]">
                        {exp.description}
                      </p>
                    )}
                    {exp.paidToUser && (
                      <p className="text-xs font-semibold text-primary mt-0.5">Paid to: {exp.paidToUser.name}</p>
                    )}
                    <p className="text-[11px] text-muted-foreground mt-1">{dateStr}</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="font-bold text-red-500">-TZS {exp.amount.toLocaleString()}</p>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Add Category Modal */}
      <AddCategoryModal
        open={isAddCategoryOpen}
        onOpenChange={setIsAddCategoryOpen}
        onSaved={fetchCategories}
      />

      {/* Add Expense Modal */}
      <AddExpenseModal
        open={isAddExpenseOpen}
        onOpenChange={setIsAddExpenseOpen}
        categories={categories}
        users={users}
        onSaved={fetchData}
      />
      {/* Print Options Modal */}
      <PrintOptionsModal
        open={isPrintModalOpen}
        onOpenChange={setIsPrintModalOpen}
        expenses={filteredExpenses}
        totalAmount={totalAmount}
      />
    </Container>
  );
}

// ----------------------------------------------------------------------------
// Modals
// ----------------------------------------------------------------------------

function AddCategoryModal({ open, onOpenChange, onSaved }: { open: boolean, onOpenChange: (open: boolean) => void, onSaved: () => void }) {
  const [name, setName] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    setLoading(true);
    try {
      await api.post("/api/expenses/categories", { name: name.trim() });
      toast.success("Category added successfully");
      onSaved();
      onOpenChange(false);
      setName("");
    } catch (err) {
      toast.error("Failed to add category");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Add Expense Category</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4 mt-4">
          <div className="space-y-2">
            <label className="text-sm font-medium">Category Name</label>
            <Input
              autoFocus
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Fuel, Utilities"
              required
            />
          </div>
          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>Cancel</Button>
            <Button type="submit" disabled={loading}>{loading ? "Saving..." : "Add Category"}</Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function AddExpenseModal({ open, onOpenChange, categories, users, onSaved }: { open: boolean, onOpenChange: (open: boolean) => void, categories: Category[], users: User[], onSaved: () => void }) {
  const [amount, setAmount] = useState("");
  const [description, setDescription] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [paidToUserId, setPaidToUserId] = useState("");
  const [loading, setLoading] = useState(false);

  // Reset form when opened
  useEffect(() => {
    if (open) {
      setAmount("");
      setDescription("");
      setCategoryId("");
      setPaidToUserId("");
    }
  }, [open]);

  const selectedCategory = categories.find((c) => c.id === categoryId);
  const isSalary = selectedCategory?.name?.toLowerCase() === "salary";

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!categoryId) return toast.error("Please select a category");
    if (isSalary && !paidToUserId) return toast.error("Please select an employee for salary");
    
    setLoading(true);
    try {
      await api.post("/api/expenses", {
        amount: Number(amount),
        description: description.trim() || undefined,
        categoryId,
        paidToUserId: isSalary ? paidToUserId : undefined,
      });
      toast.success("Expense recorded successfully");
      onSaved();
      onOpenChange(false);
    } catch (err) {
      toast.error("Failed to record expense");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Record Expense</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4 mt-2">
          
          <div className="space-y-2">
            <label className="text-sm font-medium">Category</label>
            <div className="flex flex-wrap gap-2">
              {categories.map((cat) => (
                <button
                  key={cat.id}
                  type="button"
                  onClick={() => {
                    setCategoryId(cat.id);
                    setPaidToUserId("");
                  }}
                  className={`px-3 py-1.5 rounded-lg text-sm transition-all border ${
                    categoryId === cat.id 
                      ? "bg-primary text-primary-foreground border-primary" 
                      : "bg-muted text-muted-foreground border-transparent hover:border-border"
                  }`}
                >
                  {cat.name}
                </button>
              ))}
              {categories.length === 0 && <span className="text-sm text-muted-foreground">No categories available. Add one first.</span>}
            </div>
          </div>

          {isSalary && (
            <div className="space-y-2">
              <label className="text-sm font-medium text-green-600">Employee (Salary Recipient)</label>
              <select
                className="flex h-10 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm"
                value={paidToUserId}
                onChange={(e) => setPaidToUserId(e.target.value)}
                required
              >
                <option value="" disabled>Select an employee...</option>
                {users.map((u) => (
                  <option key={u.id} value={u.id}>{u.name} ({u.role})</option>
                ))}
              </select>
            </div>
          )}

          <div className="space-y-2">
            <label className="text-sm font-medium">Amount (TZS)</label>
            <Input
              type="number"
              min="0"
              step="any"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="0.00"
              required
            />
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium">Description (Optional)</label>
            <Input
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Additional details..."
            />
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>Cancel</Button>
            <Button type="submit" disabled={loading || !categoryId}>{loading ? "Saving..." : "Save Expense"}</Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function PrintOptionsModal({ open, onOpenChange, expenses, totalAmount }: { open: boolean, onOpenChange: (open: boolean) => void, expenses: any[], totalAmount: number }) {
  const [printers, setPrinters] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (open) {
      const saved = localStorage.getItem('network_printers_list');
      if (saved) {
        try { setPrinters(JSON.parse(saved)); } catch (e) {}
      }
    }
  }, [open]);

  const handleSystemPrint = () => {
    onOpenChange(false);
    setTimeout(() => window.print(), 100);
  };

  const handleNetworkPrint = async (printer: any) => {
    setLoading(true);
    try {
      let text = "=== EXPENSES REPORT ===\n";
      text += `Total: TZS ${totalAmount.toLocaleString()}\n`;
      text += "-----------------------\n";
      expenses.forEach(exp => {
        text += `${exp.category?.name || 'Unknown'}: -TZS ${exp.amount.toLocaleString()}\n`;
      });
      text += "=======================\n\n\n\n\n";

      await api.post("/api/printer/print", {
        ip: printer.ip,
        port: printer.port || 9100,
        data: text,
      });
      toast.success(`Printed to ${printer.name}`);
      onOpenChange(false);
    } catch (err) {
      toast.error("Failed to print to network printer");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[400px]">
        <DialogHeader>
          <DialogTitle>Print Options</DialogTitle>
        </DialogHeader>
        <div className="space-y-3 mt-4">
          <Button variant="outline" className="w-full justify-start h-12" onClick={handleSystemPrint}>
            <Icons8 icon="printer" className="w-5 h-5 mr-3" />
            Standard Print (A4)
          </Button>
          
          {printers.length > 0 && (
            <div className="pt-4 pb-2">
              <h4 className="text-xs font-bold text-muted-foreground uppercase tracking-widest mb-2">Network Thermal Printers</h4>
              <div className="space-y-2">
                {printers.map(p => (
                  <Button key={p.id} variant="secondary" className="w-full justify-start h-12 relative" disabled={loading} onClick={() => handleNetworkPrint(p)}>
                    <Icons8 icon="box" className="w-5 h-5 mr-3" />
                    <div className="flex flex-col items-start">
                      <span>{p.name}</span>
                      <span className="text-[10px] opacity-70 font-mono">{p.ip}:{p.port}</span>
                    </div>
                    {p.isDefault && <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[9px] bg-primary/20 text-primary px-2 py-0.5 rounded-md">Default</span>}
                  </Button>
                ))}
              </div>
            </div>
          )}
          
          {printers.length === 0 && (
            <p className="text-xs text-muted-foreground mt-4 text-center">
              No thermal printers configured.<br/>Add them in Settings &gt; Printers.
            </p>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
