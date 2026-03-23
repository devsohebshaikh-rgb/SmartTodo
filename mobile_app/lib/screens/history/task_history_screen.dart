import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_location_todo/providers/todo_provider.dart';
import 'package:smart_location_todo/models/todo_model.dart';
import 'package:smart_location_todo/utils/constants.dart';
import 'package:smart_location_todo/utils/helpers.dart';
import 'package:smart_location_todo/screens/tasks/task_detail_screen.dart';

class TaskHistoryScreen extends StatefulWidget {
  const TaskHistoryScreen({super.key});

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Task History'),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<TodoProvider>(
        builder: (context, provider, _) {
          final completed = provider.todos
              .where((t) => t.status == 'completed')
              .toList();
          final missed = provider.todos
              .where((t) => t.status == 'missed')
              .toList();
          final upcoming = provider.upcomingTodos;

          return Column(
            children: [
              // Summary Stats
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    _buildStatCard(
                      label: 'Completed',
                      count: completed.length,
                      color: AppColors.secondary,
                      icon: Icons.check_circle_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      label: 'Missed',
                      count: missed.length,
                      color: AppColors.accent,
                      icon: Icons.cancel_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      label: 'Upcoming',
                      count: upcoming.length,
                      color: AppColors.primary,
                      icon: Icons.upcoming_rounded,
                    ),
                  ],
                ),
              ),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textLight,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Completed'),
                    Tab(text: 'Missed'),
                    Tab(text: 'Upcoming'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(completed, 'completed'),
                    _buildTaskList(missed, 'missed'),
                    _buildTaskList(upcoming, 'upcoming'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<TodoModel> todos, String type) {
    if (todos.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return _buildHistoryCard(todo, type);
      },
    );
  }

  Widget _buildHistoryCard(TodoModel todo, String type) {
    final statusColor = getStatusColor(todo.status);
    final statusIcon = getStatusIcon(todo.status);

    // Determine the relevant date label
    String dateLabel;
    DateTime dateValue;
    switch (type) {
      case 'completed':
        dateLabel = 'Completed';
        dateValue = todo.updatedAt;
        break;
      case 'missed':
        dateLabel = 'Missed';
        dateValue = todo.updatedAt;
        break;
      default:
        dateLabel = 'Visit Date';
        dateValue = todo.location?.visitDate ?? todo.createdAt;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(todo: todo),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 90,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(statusIcon, size: 20, color: statusColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todo.taskTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 13, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  todo.location?.city ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 13, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Text(
                                '$dateLabel: ${formatDate(dateValue)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: AppColors.textLight, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    final config = {
      'completed': {
        'icon': Icons.emoji_events_rounded,
        'message': 'No completed tasks yet',
        'subtitle': 'Complete tasks to see your achievements',
      },
      'missed': {
        'icon': Icons.sentiment_satisfied_rounded,
        'message': 'No missed tasks',
        'subtitle': 'Great job staying on track!',
      },
      'upcoming': {
        'icon': Icons.event_note_rounded,
        'message': 'No upcoming tasks',
        'subtitle': 'Plan ahead by adding new tasks',
      },
    };

    final data = config[type]!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(data['icon'] as IconData,
                size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            data['message'] as String,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data['subtitle'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
