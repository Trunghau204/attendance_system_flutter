import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import 'history_tab.dart';
import '../schedule/schedule_tab.dart';

/// ========================================
/// CALENDAR TAB - Gộp Lịch sử + Lịch làm việc
/// ========================================
class CalendarTab extends StatefulWidget {
  final int userId;

  const CalendarTab({super.key, required this.userId});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Lịch làm việc'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Lịch sử chấm công', icon: Icon(Icons.history)),
            Tab(text: 'Lịch làm việc', icon: Icon(Icons.calendar_month)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HistoryTab(userId: widget.userId),
          ScheduleTab(userId: widget.userId),
        ],
      ),
    );
  }
}
