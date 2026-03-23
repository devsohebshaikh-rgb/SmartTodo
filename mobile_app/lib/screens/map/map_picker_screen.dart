import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'package:smart_location_todo/utils/constants.dart';
import 'package:smart_location_todo/widgets/gradient_button.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapPickerScreen({super.key, this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLatLng;
  String _selectedCity = '';
  String _selectedAddress = '';
  bool _hasLocationPermission = false;
  bool _isLoadingAddress = false;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  static final LatLng _indiaCenter = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    if (widget.initialLocation != null) {
      _selectedLatLng = widget.initialLocation;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    if (kIsWeb) {
      setState(() => _hasLocationPermission = true);
      return;
    }
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (mounted) {
        setState(() {
          _hasLocationPermission = permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasLocationPermission = false);
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      _mapController.move(latLng, 15);
      _onMapTapped(latLng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onMapTapped(LatLng latLng) {
    setState(() => _selectedLatLng = latLng);
    if (!kIsWeb) _reverseGeocode(latLng);
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    if (kIsWeb) return;
    setState(() => _isLoadingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? '';
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
        setState(() {
          _selectedCity = city;
          _selectedAddress = address;
          _cityController.text = city;
          _addressController.text = address;
          _isLoadingAddress = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingAddress = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final latLng = LatLng(locations.first.latitude, locations.first.longitude);
        _mapController.move(latLng, 14);
        _onMapTapped(latLng);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find that location. Try tapping the map.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Search failed. Tap the map to select a location.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmLocation() {
    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final city = _cityController.text.trim().isEmpty
        ? _selectedCity
        : _cityController.text.trim();
    final address = _addressController.text.trim().isEmpty
        ? _selectedAddress
        : _addressController.text.trim();

    Navigator.pop(context, {
      'city': city,
      'latitude': _selectedLatLng!.latitude,
      'longitude': _selectedLatLng!.longitude,
      'address': address,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // OpenStreetMap via flutter_map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation ?? _indiaCenter,
              initialZoom: widget.initialLocation != null ? 14 : 5,
              onTap: (tapPosition, latLng) => _onMapTapped(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smarttodo.app',
              ),
              if (_selectedLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLatLng!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFF6C63FF),
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Search bar at top
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textDark),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search places...',
                        hintStyle: TextStyle(
                            color: AppColors.textLight, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.primary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded,
                                    color: AppColors.textLight, size: 20),
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        filled: false,
                      ),
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textDark),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _searchPlace,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // My Location FAB
          if (_hasLocationPermission)
            Positioned(
              right: 16,
              bottom: _selectedLatLng != null ? 330 : 32,
              child: FloatingActionButton.small(
                heroTag: 'myLocation',
                onPressed: _goToMyLocation,
                backgroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.my_location_rounded,
                    color: AppColors.primary),
              ),
            ),

          // Bottom location details card
          if (_selectedLatLng != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildLocationCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
              const Text(
                'Selected Location',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildCoordinateChip(Icons.north_rounded,
                      'Lat: ${_selectedLatLng!.latitude.toStringAsFixed(6)}'),
                  const SizedBox(width: 8),
                  _buildCoordinateChip(Icons.east_rounded,
                      'Lng: ${_selectedLatLng!.longitude.toStringAsFixed(6)}'),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City *',
                  labelStyle: const TextStyle(
                      fontSize: 13, color: AppColors.textLight),
                  prefixIcon: const Icon(Icons.location_city_rounded,
                      color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  suffixIcon: _isLoadingAddress
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary)),
                        )
                      : null,
                ),
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: const TextStyle(
                      fontSize: 13, color: AppColors.textLight),
                  prefixIcon: const Icon(Icons.place_rounded,
                      color: AppColors.secondary, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                maxLines: 2,
                minLines: 1,
              ),
              const SizedBox(height: 16),
              GradientButton(
                text: 'Confirm Location',
                icon: Icons.check_circle_outline_rounded,
                onPressed: _confirmLocation,
                colors: const [AppColors.primary, AppColors.primaryDark],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoordinateChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

