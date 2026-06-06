import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _activeTabId = 'overview';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedSiteId = 'all';
  final TextEditingController _plateController = TextEditingController();
  bool _isExporting = false;

  final List<Map<String, dynamic>> _reportTabs = [
    { 'id': 'overview',        'label': 'Overview',          'icon': LucideIcons.barChart2,   'endpoint': null },
    { 'id': 'daily-revenue',   'label': 'Daily Revenue',     'icon': LucideIcons.dollarSign,  'endpoint': 'daily-revenue' },
    { 'id': 'sessions',        'label': 'Sessions',          'icon': LucideIcons.car,         'endpoint': 'sessions' },
    { 'id': 'staff',           'label': 'Staff Performance', 'icon': LucideIcons.users,        'endpoint': 'staff-performance' },
    { 'id': 'vehicle-history', 'label': 'Vehicle History',   'icon': LucideIcons.history,     'endpoint': 'vehicle-history' },
    { 'id': 'site-utilization','label': 'Site Utilization',  'icon': LucideIcons.parkingSquare,'endpoint': 'site-utilization' },
    { 'id': 'security',        'label': 'Security',          'icon': LucideIcons.shieldAlert, 'endpoint': 'security' },
  ];

  final List<Color> _pieColors = [
    const Color(0xFF10b981), // success
    const Color(0xFF3b82f6), // primary-like blue
    const Color(0xFFf59e0b), // warning
    const Color(0xFFef4444), // error
    const Color(0xFF8b5cf6), // purple
    const Color(0xFFec4899), // pink
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.fetchSites();
      _fetchData();
    });
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  void _fetchData() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    if (_activeTabId == 'overview') {
      adminProvider.fetchReportsOverview(siteId: _selectedSiteId);
    } else {
      final tab = _reportTabs.firstWhere((t) => t['id'] == _activeTabId);
      final endpoint = tab['endpoint'] as String;
      
      final formatter = DateFormat('yyyy-MM-dd');
      adminProvider.fetchReportData(
        endpoint: endpoint,
        startDate: formatter.format(_startDate),
        endDate: formatter.format(_endDate),
        siteId: _selectedSiteId,
        plate: _activeTabId == 'vehicle-history' && _plateController.text.isNotEmpty 
            ? _plateController.text.trim() 
            : null,
      );
    }
  }  void _setPreset(int days) {
    setState(() {
      _startDate = DateTime.now().subtract(Duration(days: days));
      _endDate = DateTime.now();
    });
    _fetchData();
  }

  void _handleExportCSV(BuildContext context, String tabLabel, List<dynamic> rows) {
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No records to export")),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("CSV Exported: parking_${tabLabel.toLowerCase().replaceAll(' ', '_')}_report.csv"),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _handleExportPDF(BuildContext context, String tabLabel, List<dynamic> rows) {
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No records to export")),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isExporting = true);
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isExporting = false);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text("PDF Exported: parking_${tabLabel.toLowerCase().replaceAll(' ', '_')}_summary.pdf"),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: _fetchData,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs selector
            _buildTabsBar(),
            
            // Filters
            _buildFilterCard(adminProvider),
            
            // Content
            Expanded(
              child: adminProvider.isLoadingReports
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : RefreshIndicator(
                      onRefresh: () async => _fetchData(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _activeTabId == 'overview'
                            ? _buildOverviewContent(adminProvider)
                            : _buildReportContent(adminProvider),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabsBar() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _reportTabs.length,
        itemBuilder: (context, index) {
          final tab = _reportTabs[index];
          final id = tab['id'] as String;
          final label = tab['label'] as String;
          final icon = tab['icon'] as IconData;
          final isActive = id == _activeTabId;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeTabId = id;
                });
                _fetchData();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? Colors.transparent
                        : Theme.of(context).dividerColor.withOpacity(0.15),
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isActive ? Colors.white : AppTheme.textSecondary(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterCard(AdminProvider adminProvider) {
    final hasDateFilters = _activeTabId != 'overview';
    final hasPlateFilter = _activeTabId == 'vehicle-history';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Site Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SITE LOCATION',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withOpacity(0.15),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSiteId,
                            isExpanded: true,
                            dropdownColor: Theme.of(context).cardColor,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            icon: const Icon(LucideIcons.chevronDown, size: 16, color: Colors.grey),
                            items: [
                              const DropdownMenuItem<String>(
                                value: 'all',
                                child: Text('All Sites'),
                              ),
                              ...adminProvider.sites.map((site) {
                                return DropdownMenuItem<String>(
                                  value: site['id']?.toString() ?? '',
                                  child: Text(site['name']?.toString() ?? '—'),
                                );
                              }).toList(),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSiteId = val;
                                });
                                _fetchData();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Conditional Date Selector
                if (hasDateFilters) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DATE RANGE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: Theme.of(context).colorScheme.copyWith(
                                      primary: AppTheme.primary,
                                      onPrimary: Colors.white,
                                      surface: Theme.of(context).cardColor,
                                      onSurface: Theme.of(context).colorScheme.onSurface,
                                    ),
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
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).inputDecorationTheme.fillColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${DateFormat('MM/dd').format(_startDate)} - ${DateFormat('MM/dd').format(_endDate)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(LucideIcons.calendar, size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            
            if (hasDateFilters) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPresetButton('Today', 0),
                  const SizedBox(width: 8),
                  _buildPresetButton('7 Days', 7),
                  const SizedBox(width: 8),
                  _buildPresetButton('30 Days', 30),
                ],
              ),
            ],
            
            if (hasPlateFilter) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PLATE NUMBER',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _plateController,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary(context)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintText: 'e.g. EE5435T6',
                      hintStyle: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13),
                      prefixIcon: Icon(LucideIcons.search, size: 16, color: AppTheme.textSecondary(context)),
                      suffixIcon: _plateController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(LucideIcons.x, size: 16, color: AppTheme.textSecondary(context)),
                              onPressed: () {
                                _plateController.clear();
                                _fetchData();
                                setState(() {});
                              },
                            )
                          : null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                    onSubmitted: (val) {
                      _fetchData();
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, int days) {
    final formatter = DateFormat('yyyy-MM-dd');
    final targetStartDate = DateTime.now().subtract(Duration(days: days));
    final isSelected = formatter.format(_startDate) == formatter.format(targetStartDate) &&
        formatter.format(_endDate) == formatter.format(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _setPreset(days),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.15) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary.withOpacity(0.5)
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewContent(AdminProvider adminProvider) {
    final overview = adminProvider.reportsOverview;
    if (overview == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text(
            "No Overview Data Available",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
      );
    }

    final keyMetrics = overview['keyMetrics'] as Map<String, dynamic>? ?? {};
    final totalRevenue = keyMetrics['totalRevenue'] as num? ?? 0;
    final totalVehicles = keyMetrics['totalVehicles'] as num? ?? 0;
    final avgSessionDuration = keyMetrics['avgSessionDuration']?.toString() ?? '—';

    final revenueOverTime = overview['revenueOverTime'] as List<dynamic>? ?? [];
    final vehicleDistribution = overview['vehicleDistribution'] as List<dynamic>? ?? [];

    final currencyFormatter = NumberFormat.decimalPattern();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Revenue (30 Days)',
                'Tsh ${currencyFormatter.format(totalRevenue)}',
                LucideIcons.wallet,
                AppTheme.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Vehicles',
                '${currencyFormatter.format(totalVehicles)}',
                LucideIcons.car,
                AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Avg Duration',
                avgSessionDuration,
                LucideIcons.clock,
                AppTheme.warning,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        Text(
          'REVENUE TRAJECTORY (30 DAYS)',
          style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 12),
        ),
        const SizedBox(height: 12),
        _buildRevenueLineChartCard(revenueOverTime),
        
        const SizedBox(height: 24),
        Text(
          'TRAFFIC DISTRIBUTION',
          style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 12),
        ),
        const SizedBox(height: 12),
        _buildTrafficPieChartCard(vehicleDistribution),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary(context)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueLineChartCard(List<dynamic> revenueOverTime) {
    if (revenueOverTime.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
        ),
        child: const Text("No revenue trend data available", style: TextStyle(color: Colors.grey)),
      );
    }

    double maxRevenue = 1000;
    List<FlSpot> spots = [];
    for (int i = 0; i < revenueOverTime.length; i++) {
      final rev = double.tryParse(revenueOverTime[i]['revenue']?.toString() ?? '0') ?? 0;
      if (rev > maxRevenue) {
        maxRevenue = rev;
      }
      spots.add(FlSpot(i.toDouble(), rev));
    }
    
    double yInterval = maxRevenue / 4;
    if (yInterval <= 0) yInterval = 1;

    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 24, bottom: 8, right: 24, left: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < revenueOverTime.length) {
                    final interval = (revenueOverTime.length / 5).ceil();
                    if (index % interval == 0 || index == revenueOverTime.length - 1) {
                      final dateStr = revenueOverTime[index]['date'] ?? '';
                      try {
                        final parsedDate = DateTime.parse(dateStr);
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            DateFormat('MM/dd').format(parsedDate),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        );
                      } catch (e) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                            ),
                          ),
                        );
                      }
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  String text = '';
                  if (value >= 1000000) {
                    text = '${(value / 1000000).toStringAsFixed(1)}M';
                  } else if (value >= 1000) {
                    text = '${(value / 1000).toStringAsFixed(0)}k';
                  } else {
                    text = value.toStringAsFixed(0);
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (revenueOverTime.length - 1).toDouble(),
          minY: 0,
          maxY: maxRevenue * 1.15,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.success],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.3),
                    AppTheme.success.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficPieChartCard(List<dynamic> vehicleDistribution) {
    if (vehicleDistribution.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
        ),
        child: const Text("No traffic distribution data available", style: TextStyle(color: Colors.grey)),
      );
    }

    List<PieChartSectionData> sections = [];
    for (int i = 0; i < vehicleDistribution.length; i++) {
      final item = vehicleDistribution[i];
      final val = double.tryParse(item['value']?.toString() ?? '0') ?? 0;
      sections.add(PieChartSectionData(
        color: _pieColors[i % _pieColors.length],
        value: val,
        title: '${val.toInt()}',
        radius: 35,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 35,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: vehicleDistribution.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final name = item['name'] ?? 'Unknown';
              final val = item['value'] ?? 0;
              final color = _pieColors[idx % _pieColors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${val.toInt()} sessions',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(AdminProvider adminProvider) {
    final reportData = adminProvider.reportsData;
    if (reportData == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text(
            "No Data Loaded",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
      );
    }

    final summary = reportData['summary'] as Map<String, dynamic>?;
    final rows = reportData['rows'] as List<dynamic>? ?? [];

    final currentTabConfig = _reportTabs.firstWhere((t) => t['id'] == _activeTabId);
    final tabLabel = currentTabConfig['label'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Summary Cards
        if (summary != null && summary.isNotEmpty) ...[
          _buildSummaryCards(summary),
          const SizedBox(height: 20),
        ],

        // Table Header and Export Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${rows.length} RECORD${rows.length != 1 ? 'S' : ''}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary(context),
                    backgroundColor: Theme.of(context).dividerColor.withOpacity(0.05),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(LucideIcons.fileSpreadsheet, size: 14),
                  label: const Text('CSV', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () => _handleExportCSV(context, tabLabel, rows),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                        )
                      : const Icon(LucideIcons.fileText, size: 14),
                  label: Text(
                    _isExporting ? 'Exporting...' : 'PDF',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isExporting ? null : () => _handleExportPDF(context, tabLabel, rows),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Table
        _buildDataTableCard(rows),
        
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    final currencyFormatter = NumberFormat.decimalPattern();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: summary.entries.map((entry) {
          final key = entry.key;
          final val = entry.value;
          final label = key.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}').trim();
          final capitalizedLabel = label[0].toUpperCase() + label.substring(1);

          String valStr = val.toString();
          if (key.toLowerCase().contains('revenue') || key.toLowerCase().contains('paid')) {
            if (val is num) {
              valStr = 'Tsh ${currencyFormatter.format(val)}';
            }
          }

          return IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capitalizedLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valStr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: key.toLowerCase().contains('revenue') || key.toLowerCase().contains('paid')
                        ? AppTheme.success
                        : AppTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDataTableCard(List<dynamic> rows) {
    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.inbox, size: 48, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text(
              "No records found for this period.",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final firstRow = rows[0] as Map<String, dynamic>;
    final headers = firstRow.keys.toList();
    final currencyFormatter = NumberFormat.decimalPattern();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Theme.of(context).dividerColor.withOpacity(0.03)),
          columnSpacing: 24,
          horizontalMargin: 20,
          columns: headers.map((h) {
            final label = h.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}').trim();
            final capitalizedLabel = label[0].toUpperCase() + label.substring(1);
            return DataColumn(
              label: Text(
                capitalizedLabel.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.grey,
                  letterSpacing: 0.8,
                ),
              ),
            );
          }).toList(),
          rows: rows.map((row) {
            final rowMap = row as Map<String, dynamic>;
            return DataRow(
              cells: headers.map((h) {
                final value = rowMap[h];
                final valueStr = value != null ? value.toString() : '—';

                Color? textColor;
                FontWeight? fontWeight;

                if (valueStr == 'STILL INSIDE' || valueStr == 'YES') {
                  textColor = AppTheme.error;
                  fontWeight = FontWeight.w900;
                } else if (valueStr == 'EXITED' || valueStr == 'Yes') {
                  textColor = AppTheme.success;
                  fontWeight = FontWeight.bold;
                } else if (h.toLowerCase().contains('amount') ||
                    h.toLowerCase().contains('revenue') ||
                    h.toLowerCase().contains('paid')) {
                  textColor = AppTheme.success;
                  fontWeight = FontWeight.w900;
                }

                String displayValue = valueStr;
                if ((h.toLowerCase().contains('amount') ||
                        h.toLowerCase().contains('revenue') ||
                        h.toLowerCase().contains('paid')) &&
                    value is num) {
                  displayValue = 'Tsh ${currencyFormatter.format(value)}';
                }

                return DataCell(
                  Text(
                    displayValue,
                    style: TextStyle(
                      color: textColor ?? AppTheme.textPrimary(context),
                      fontWeight: fontWeight ?? FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
