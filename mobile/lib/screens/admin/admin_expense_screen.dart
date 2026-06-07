import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../services/printing_service.dart';

class AdminExpenseScreen extends StatefulWidget {
  const AdminExpenseScreen({super.key});

  @override
  State<AdminExpenseScreen> createState() => _AdminExpenseScreenState();
}

class _AdminExpenseScreenState extends State<AdminExpenseScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      provider.fetchExpenseCategories();
      provider.fetchUsers();
      _fetchData();
    });
  }

  void _fetchData() {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    final formatter = DateFormat('yyyy-MM-dd');
    provider.fetchExpenses(
      startDate: '${formatter.format(_startDate)}T00:00:00',
      endDate: '${formatter.format(_endDate)}T23:59:59',
    );
  }

  void _showAddExpenseModal(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context, listen: false);
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
        onExpenseSaved: _fetchData,
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

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.dark
                ? const ColorScheme.dark(primary: AppTheme.primary)
                : const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
  }

  Future<void> _exportReport(List<dynamic> filteredExpenses, double total) async {
    final dateRange = '${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}';
    final doc = await PrintingService.buildExpenseReportPdf(filteredExpenses, dateRange, total);
    await Printing.sharePdf(bytes: await doc.save(), filename: 'Expense_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filter expenses locally by category
    final List<dynamic> filteredExpenses = provider.expenses.where((exp) {
      if (_selectedCategory == 'All') return true;
      final catName = exp['category']?['name'] ?? 'Unknown';
      return catName == _selectedCategory;
    }).toList();

    // Calculate total
    double totalAmount = 0;
    for (var exp in filteredExpenses) {
      totalAmount += (exp['amount'] as num?)?.toDouble() ?? 0;
    }

    // Build category list for filter
    final Set<String> catNames = {'All'};
    for (var cat in provider.expenseCategories) {
      if (cat['name'] != null) catNames.add(cat['name']);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            floating: true,
            title: const Text('Expenses Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.printer, size: 20),
                tooltip: 'Export/Print PDF Report',
                onPressed: filteredExpenses.isEmpty ? null : () => _exportReport(filteredExpenses, totalAmount),
              ),
              IconButton(
                icon: const Icon(LucideIcons.tags, size: 20),
                tooltip: 'Manage Categories',
                onPressed: () => _showAddCategoryModal(context),
              ),
            ],
          ),
          // Top Summary Dashboard
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF0C4A6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Expenses', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Icon(LucideIcons.trendingDown, color: Colors.white.withOpacity(0.8), size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TZS ${NumberFormat.decimalPattern().format(totalAmount)}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(LucideIcons.calendar, color: Colors.white.withOpacity(0.8), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        ),
                        const Spacer(),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: _selectDateRange,
                          child: const Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Category Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary(context))),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: catNames.length,
                      itemBuilder: (context, index) {
                        final catName = catNames.elementAt(index);
                        final isSelected = _selectedCategory == catName;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCategory = catName),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primary : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                catName,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textSecondary(context),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expense List
          if (provider.isLoadingExpenses)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (filteredExpenses.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(context, isDark))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final exp = filteredExpenses[index];
                    final catName = exp['category']?['name'] ?? 'Unknown';
                    final amount = (exp['amount'] as num?)?.toDouble() ?? 0;
                    final date = DateTime.tryParse(exp['date'] ?? '') ?? DateTime.now();
                    final desc = exp['description'] ?? '';
                    final paidTo = exp['paidToUser']?['name'];

                    // Determine icon and color based on category
                    IconData icon = LucideIcons.wallet;
                    Color color = AppTheme.primary;
                    final catLower = catName.toLowerCase();
                    if (catLower.contains('salary')) { icon = LucideIcons.users; color = AppTheme.success; }
                    else if (catLower.contains('fuel')) { icon = LucideIcons.fuel; color = AppTheme.error; }
                    else if (catLower.contains('utility') || catLower.contains('electricity')) { icon = LucideIcons.zap; color = Colors.orange; }
                    else if (catLower.contains('maintenance')) { icon = LucideIcons.wrench; color = Colors.blueGrey; }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(catName, style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  if (desc.isNotEmpty) Text(desc, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if (paidTo != null) Text('Paid to: $paidTo', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(DateFormat('MMM dd, yyyy - HH:mm').format(date), style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '-Tsh ${NumberFormat.decimalPattern().format(amount)}',
                              style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: filteredExpenses.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)), // Padding for FAB
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseModal(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.wallet, size: 64, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 16),
          Text('No expenses found for this period', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 16)),
          const SizedBox(height: 8),
          Text('Try changing the filters or add a new expense', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
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
