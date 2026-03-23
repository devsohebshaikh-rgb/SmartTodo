import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'package:smart_location_todo/models/todo_model.dart';
import 'package:smart_location_todo/providers/todo_provider.dart';
import 'package:smart_location_todo/services/geofence_service.dart';
import 'package:smart_location_todo/utils/constants.dart';
import 'package:smart_location_todo/utils/helpers.dart';
import 'package:smart_location_todo/screens/tasks/task_detail_screen.dart';

enum _MapFilter { all, today, upcoming, completed }

class MapTodosScreen extends StatefulWidget {
  const MapTodosScreen({super.key});

  @override
  State<MapTodosScreen> createState() => _MapTodosScreenState();
}

class _MapTodosScreenState extends State<MapTodosScreen> {
  final MapController _mapController = MapController();
  _MapFilter _activeFilter = _MapFilter.all;
  Position? _currentPosition;
  final GeofenceService _geofenceService = GeofenceService();
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  List<TodoModel> _getFilteredTodos(List<TodoModel> todos) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    switch (_activeFilter) {
      case _MapFilter.today:
        return todos.where((t) {
          if (t.location == null) return false;
          final visitDate = t.location!.visitDate;
          return visitDate.isAfter(todayStart) && visitDate.isBefore(todayEnd);
        }).toList();
      case _MapFilter.upcoming:
        return todos.where((t) {
          if (t.location == null) return false;
          return t.location!.visitDate.isAfter(now) && t.status != 'completed';
        }).toList();
      case _MapFilter.completed:
        return todos
            .where((t) => t.status == 'completed' && t.location != null)
            .toList();
      case _MapFilter.all:
        return todos.where((t) => t.location != null).toList();
    }
  }

  Color _getMarkerColor(TodoModel todo) {
    if (todo.status == 'completed') return Colors.green;
    if (todo.location != null &&
        todo.location!.visitDate.isAfter(DateTime.now())) {
      return Colors.blue;
    }
    return Colors.red;
  }

  List<Marker> _buildMarkers(List<TodoModel> todos) {
    return todos.map((todo) {
      final loc = todo.location!;
      final color = _getMarkerColor(todo);
      return Marker(
        point: LatLng(loc.latitude, loc.longitude),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => _showTodoBottomSheet(todo),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 22),
          ),
        ),
      );
    }).toList();
  }

  void _fitAllMarkers(List<TodoModel> todos) {
    final todosWithLocation =
        todos.where((t) => t.location != null).toList();
    if (todosWithLocation.isEmpty) return;

    if (todosWithLocation.length == 1) {
      final loc = todosWithLocation.first.location!;
      _mapController.move(LatLng(loc.latitude, loc.longitude), 14);
      return;
    }

    double minLat = todosWithLocation.first.location!.latitude;
    double maxLat = minLat;
    double minLng = todosWithLocation.first.location!.longitude;
    double maxLng = minLng;

    for (final todo in todosWithLocation) {
      final lat = todo.location!.latitude;
      final lng = todo.location!.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    if (_currentPosition != null) {
      if (_currentPosition!.latitude < minLat)
        minLat = _currentPosition!.latitude;
      if (_currentPosition!.latitude > maxLat)
        maxLat = _currentPosition!.latitude;
      if (_currentPosition!.longitude < minLng)
        minLng = _currentPosition!.longitude;
      if (_currentPosition!.longitude > maxLng)
        maxLng = _currentPosition!.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  void _centerOnMyLocation() async {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15,
      );
    } else {
      await _getCurrentLocation();
      if (_currentPosition != null) {
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get current location'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  double? _calculateDistanceToTodo(TodoModel todo) {
    if (_currentPosition == null || todo.location == null) return null;
    return _geofenceService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      todo.location!.latitude,
      todo.location!.longitude,
    );
  }

  void _showTodoBottomSheet(TodoModel todo) {
    final distance = _calculateDistanceToTodo(todo);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor(todo.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(getStatusIcon(todo.status),
                            size: 14, color: getStatusColor(todo.status)),
                        const SizedBox(width: 4),
                        Text(
                          todo.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: getStatusColor(todo.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    todo.taskTitle,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on_rounded, AppColors.accent,
                      todo.location?.city ?? 'Unknown',
                      subtitle: todo.location?.address),
                  const SizedBox(height: 8),
                  if (todo.location?.visitDate != null)
                    _buildInfoRow(Icons.calendar_today_rounded,
                        AppColors.primary, formatDate(todo.location!.visitDate)),
                  if (distance != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.straighten_rounded,
                        AppColors.secondary, formatDistance(distance)),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.navigation_rounded,
                          label: 'Navigate',
                          color: AppColors.secondary,
                          onTap: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Opening navigation...'),
                                  behavior: SnackBarBehavior.floating),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.check_circle_rounded,
                          label: 'Complete',
                          color: Colors.green.shade600,
                          onTap: todo.status == 'completed'
                              ? null
                              : () {
                                  Provider.of<TodoProvider>(context,
                                          listen: false)
                                      .markComplete(todo.id);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Task marked as completed'),
                                        behavior: SnackBarBehavior.floating),
                                  );
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.info_outline_rounded,
                          label: 'Details',
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetailScreen(todo: todo),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String text,
      {String? subtitle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark)),
              if (subtitle != null && subtitle.isNotEmpty)
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return Material(
      color: isDisabled ? Colors.grey.shade100 : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon,
                  color: isDisabled ? Colors.grey.shade400 : color, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDisabled ? Colors.grey.shade400 : color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, _) {
          final allTodos = todoProvider.todos;
          final filteredTodos = _getFilteredTodos(allTodos);
          final markers = _buildMarkers(filteredTodos);

          // Add current location marker
          final allMarkers = [...markers];
          if (_currentPosition != null) {
            allMarkers.add(
              Marker(
                point: LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude),
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Stack(
            children: [
              // OpenStreetMap
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      LatLng(AppConstants.defaultMapLatitude, AppConstants.defaultMapLongitude),
                  initialZoom: AppConstants.defaultMapZoom,
                  onMapReady: () {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _fitAllMarkers(filteredTodos);
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smarttodo.app',
                  ),
                  MarkerLayer(markers: allMarkers),
                ],
              ),

              // Top bar with title and filters
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.7, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Tasks on Map',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${filteredTodos.length} tasks',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _MapFilter.values.map((filter) {
                                final isActive = _activeFilter == filter;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    selected: isActive,
                                    label: Text(_filterLabel(filter)),
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isActive
                                          ? Colors.white
                                          : AppColors.textDark,
                                    ),
                                    avatar: isActive
                                        ? null
                                        : Icon(_filterIcon(filter),
                                            size: 16,
                                            color: _filterColor(filter)),
                                    selectedColor: _filterColor(filter),
                                    backgroundColor: Colors.white,
                                    elevation: isActive ? 2 : 0,
                                    shadowColor:
                                        _filterColor(filter).withOpacity(0.3),
                                    side: BorderSide(
                                        color: isActive
                                            ? Colors.transparent
                                            : Colors.grey.shade200),
                                    showCheckmark: false,
                                    onSelected: (_) {
                                      setState(
                                          () => _activeFilter = filter);
                                      Future.delayed(
                                        const Duration(milliseconds: 100),
                                        () => _fitAllMarkers(
                                            _getFilteredTodos(allTodos)),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Legend card
              Positioned(
                bottom: 24,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLegendItem(Colors.red, 'Pending'),
                      const SizedBox(height: 4),
                      _buildLegendItem(Colors.blue, 'Upcoming'),
                      const SizedBox(height: 4),
                      _buildLegendItem(Colors.green, 'Completed'),
                      const SizedBox(height: 4),
                      _buildLegendItem(AppColors.primary, 'You'),
                    ],
                  ),
                ),
              ),

              // Empty state
              if (filteredTodos.isEmpty)
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined,
                            size: 48, color: AppColors.textLight),
                        SizedBox(height: 12),
                        Text('No tasks found',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                        SizedBox(height: 4),
                        Text(
                          'Try changing the filter or add tasks with locations',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 13, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),

      // Center on My Location FAB
      floatingActionButton: FloatingActionButton(
        heroTag: 'centerMyLocation',
        onPressed: _centerOnMyLocation,
        backgroundColor: Colors.white,
        elevation: 4,
        child: _isLoadingLocation
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.primary),
              )
            : const Icon(Icons.gps_fixed_rounded, color: AppColors.primary),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark)),
      ],
    );
  }

  String _filterLabel(_MapFilter filter) {
    switch (filter) {
      case _MapFilter.all:
        return 'All';
      case _MapFilter.today:
        return 'Today';
      case _MapFilter.upcoming:
        return 'Upcoming';
      case _MapFilter.completed:
        return 'Completed';
    }
  }

  IconData _filterIcon(_MapFilter filter) {
    switch (filter) {
      case _MapFilter.all:
        return Icons.layers_rounded;
      case _MapFilter.today:
        return Icons.today_rounded;
      case _MapFilter.upcoming:
        return Icons.upcoming_rounded;
      case _MapFilter.completed:
        return Icons.check_circle_rounded;
    }
  }

  Color _filterColor(_MapFilter filter) {
    switch (filter) {
      case _MapFilter.all:
        return AppColors.primary;
      case _MapFilter.today:
        return AppColors.accent;
      case _MapFilter.upcoming:
        return Colors.blue.shade600;
      case _MapFilter.completed:
        return Colors.green.shade600;
    }
  }
}
