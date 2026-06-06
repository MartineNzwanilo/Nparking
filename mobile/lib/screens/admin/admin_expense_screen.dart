import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';

class AdminExpenseScreen extends StatefulWidget {
  const AdminExpenseScreen({super.key});

  @override
  State<AdminExpenseScreen> createState() => _AdminExpenseScreenState();
}

class _AdminExpenseScreenState extends State<AdminExpenseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      provider.fetchExpenseCategories();
      provider.fetchExpenses();
      provider.fetchUsers();
    });
  }

  void _showAddExpenseModal(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    // Pass a SNAPSHOT of categories and users — not live provider references
    final categories = List<Map<String, dynamic>>.from(
      provider.expenseCategories.map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final users = List<Map<String, dynamic>>.from(
      provider.users.map((e) => Map<String, dynamic>.from(e as Map)),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddExpenseModal(
        categories: categories,
        users: users,
        onExpenseSaved: () {
          provider.fetchExpenses();
        },
      ),
    );
  }

  void _showAddCategoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddCategoryModal(
        onCategorySaved: () {
          Provider.of<AdminProvider>(context, listen: false).fetchExpenseCategories();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenses = provider.expenses;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Expense Management',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.tags, size: 20),
            tooltip: 'Manage Categories',
            onPressed: () => _showAddCategoryModal(context),
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () {
              provider.fetchExpenseCategories();
              provider.fetchExpenses();
            },
          ),
        ],
      ),
      body: provider.isLoadingExpenses
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
              ? _buildEmptyState(context, isDark)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final exp = expenses[index];
                    final catName = exp['category']?['name'] ?? 'Unknown';
                    final amount = (exp['amount'] as num?)?.toDouble() ?? 0;
                    final date =
                        DateTime.tryParse(exp['date'] ?? '') ?? DateTime.now();
                    final desc = exp['description'] ?? '';
                    final paidTo = exp['paidToUser']?['name'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.error.withOpacity(0.15),
                          child: const Icon(LucideIcons.arrowDownRight,
                              color: AppTheme.error, size: 20),
                        ),
                        title: Text(
                          catName,
                          style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              desc.isNotEmpty ? desc : 'No description',
                              style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (paidTo != null) ...[
                              const SizedBox(height: 4),
                              Text('Paid to: $paidTo',
                                  style: TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, yyyy - HH:mm').format(date),
                              style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 11),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '-Tsh ${NumberFormat.decimalPattern().format(amount)}',
                          style: const TextStyle(
                              color: AppTheme.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseModal(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Add Expense',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.wallet,
              size: 64, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 16),
          Text(
            'No expenses recorded yet',
            style: TextStyle(
                color: AppTheme.textSecondary(context), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + Add Expense to get started',
            style: TextStyle(
                color: AppTheme.textSecondary(context), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Add Expense Modal ──────────────────────────────────────────────────────
// Uses local state for categories/users so provider rebuilds can't reset the form

class _AddExpenseModal extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> users;
  final VoidCallback onExpenseSaved;

  const _AddExpenseModal({
    required this.categories,
    required this.users,
    required this.onExpenseSaved,
  });

  @override
  State<_AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<_AddExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedUser;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _isSalary =>
      _selectedCategory?['name']?.toString().toLowerCase() == 'salary';

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_isSalary && _selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee for salary')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      final data = <String, dynamic>{
        'amount': double.parse(_amountController.text.trim()),
        'categoryId': _selectedCategory!['id']?.toString(),
      };
      if (_descController.text.trim().isNotEmpty) {
        data['description'] = _descController.text.trim();
      }
      if (_isSalary && _selectedUser != null) {
        data['paidToUserId'] = _selectedUser!['id']?.toString();
      }

      await provider.createExpense(data);
      widget.onExpenseSaved();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense recorded successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Record Expense',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Category — tappable chip list (avoids DropdownButtonFormField issues)
                  Text('Category',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary(context))),
                  const SizedBox(height: 8),
                  widget.categories.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: fillColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'No categories available. Tap the 🏷 icon to add one.',
                            style: TextStyle(
                                color: AppTheme.textSecondary(context),
                                fontSize: 13),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.categories.map((cat) {
                            final isSelected = _selectedCategory?['id'] == cat['id'];
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedCategory = cat;
                                _selectedUser = null; // reset user when category changes
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : fillColor,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  cat['name']?.toString() ?? '',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimary(context),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 16),

                  // Employee picker — only visible for Salary
                  if (_isSalary) ...[
                    Text('Employee (Salary recipient)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary(context))),
                    const SizedBox(height: 8),
                    widget.users.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: fillColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('No employees found',
                                style: TextStyle(
                                    color: AppTheme.textSecondary(context))),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: fillColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Map<String, dynamic>>(
                                value: _selectedUser,
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                borderRadius: BorderRadius.circular(12),
                                dropdownColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                hint: Text('Select employee',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary(context),
                                        fontSize: 14)),
                                items: widget.users
                                    .map((u) => DropdownMenuItem<Map<String, dynamic>>(
                                          value: u,
                                          child: Text(
                                            '${u['name']} (${u['role']})',
                                            style: TextStyle(
                                                color: AppTheme.textPrimary(context),
                                                fontSize: 14),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedUser = val),
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                  ],

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (Tsh)',
                      filled: true,
                      fillColor: fillColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      prefixIcon: const Icon(LucideIcons.banknote),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Enter an amount';
                      }
                      if (double.tryParse(val.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      filled: true,
                      fillColor: fillColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Save Expense',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Add Category Modal ─────────────────────────────────────────────────────

class _AddCategoryModal extends StatefulWidget {
  final VoidCallback onCategorySaved;
  const _AddCategoryModal({required this.onCategorySaved});

  @override
  State<_AddCategoryModal> createState() => _AddCategoryModalState();
}

class _AddCategoryModalState extends State<_AddCategoryModal> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await Provider.of<AdminProvider>(context, listen: false)
          .createExpenseCategory(name);
      widget.onCategorySaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('New Expense Category',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Category Name (e.g. Fuel, Utilities)',
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Add Category',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
