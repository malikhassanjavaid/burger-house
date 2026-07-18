import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/widgets/auth_loading_overlay.dart';
import '../models/delivery_location.dart';

class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({
    this.initialLocation,
    this.firstTime = false,
    this.destinationAfterSave,
    super.key,
  });

  final DeliveryLocation? initialLocation;
  final bool firstTime;
  final Widget? destinationAfterSave;

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  late final TextEditingController _area;
  late final TextEditingController _address;
  late final TextEditingController _landmark;
  late String _label;
  bool _saving = false;
  bool _findingLocation = true;
  String? _locationError;
  LatLng? _selectedPoint;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    final location = widget.initialLocation;
    _area = TextEditingController(text: location?.area ?? '');
    _address = TextEditingController(text: location?.addressLine ?? '');
    _landmark = TextEditingController(text: location?.landmark ?? '');
    _label = location?.label ?? 'Home';
    if (location?.latitude != null && location?.longitude != null) {
      _selectedPoint = LatLng(location!.latitude!, location.longitude!);
      _findingLocation = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
  }

  @override
  void dispose() {
    _area.dispose();
    _address.dispose();
    _landmark.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final location = DeliveryLocation(
      label: _label,
      area: _area.text.trim(),
      addressLine: _address.text.trim(),
      landmark: _landmark.text.trim(),
      latitude: _selectedPoint?.latitude,
      longitude: _selectedPoint?.longitude,
    );

    setState(() => _saving = true);
    try {
      await _authService.saveDeliveryLocation(location);
      if (!mounted) return;
      final destination = widget.destinationAfterSave;
      if (destination != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => destination),
          (route) => false,
        );
      } else {
        Navigator.pop(context, location);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyAuthError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _findingLocation = true;
      _locationError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationServiceDisabledException();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is required to find your address.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 18),
        ),
      );
      await _selectPoint(LatLng(position.latitude, position.longitude));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _findingLocation = false;
        _locationError = error is LocationServiceDisabledException
            ? 'Turn on Location/GPS, then try again.'
            : error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _selectPoint(LatLng point) async {
    if (!mounted) return;
    setState(() {
      _selectedPoint = point;
      _findingLocation = true;
      _locationError = null;
    });
    _mapController.move(point, 16);
    try {
      final places = await Geocoding().placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (!mounted || places.isEmpty) return;
      final place = places.first;
      final area = <String?>[place.subLocality, place.locality]
          .map((value) => value?.trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toSet()
          .join(', ');
      final address = <String?>[place.street, place.subThoroughfare]
          .map((value) => value?.trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toSet()
          .join(', ');
      setState(() {
        if (area.isNotEmpty) _area.text = area;
        if (address.isNotEmpty) _address.text = address;
      });
    } catch (_) {
      // Keep the selected coordinates; the address can still be entered manually.
    } finally {
      if (mounted) setState(() => _findingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.firstTime,
      child: AuthLoadingOverlay(
        loading: _saving,
        message: 'Saving your delivery location...',
        child: Scaffold(
          backgroundColor: const Color(0xFFFFF9F4),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: !widget.firstTime,
            title: Text(
              widget.firstTime ? 'Delivery location' : 'Edit location',
            ),
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              children: [
                _LocationMap(
                  point: _selectedPoint,
                  controller: _mapController,
                  loading: _findingLocation,
                  error: _locationError,
                  onCurrentLocation: _useCurrentLocation,
                  onPointSelected: _selectPoint,
                ),
                const SizedBox(height: 26),
                Text(
                  widget.firstTime
                      ? 'Where should we deliver?'
                      : 'Update your delivery spot',
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add clear details so your rider can find you quickly.',
                  style: TextStyle(color: AppColors.muted, fontSize: 15),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Save this place as',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: ['Home', 'Work', 'Other'].map((label) {
                    final selected = label == _label;
                    final icon = label == 'Home'
                        ? Icons.home_rounded
                        : label == 'Work'
                        ? Icons.work_rounded
                        : Icons.location_on_rounded;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: label == 'Other' ? 0 : 9,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () => setState(() => _label = label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.orange : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: selected
                                    ? AppColors.orange
                                    : const Color(0xFFE9DED5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icon,
                                  size: 18,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.dark,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.dark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _area,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Area or neighbourhood',
                          hintText: 'e.g. DHA Phase 6',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        validator: (value) => (value ?? '').trim().length < 3
                            ? 'Enter your area or neighbourhood'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _address,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Complete address',
                          hintText: 'House, street and block',
                          prefixIcon: Icon(Icons.signpost_outlined),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) => (value ?? '').trim().length < 6
                            ? 'Enter a complete delivery address'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _landmark,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Nearby landmark (optional)',
                          hintText: 'e.g. Opposite City School',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.location_on_rounded),
                  label: Text(
                    widget.firstTime
                        ? 'Save & start ordering'
                        : 'Save location',
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: AppColors.muted,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Your address is only used for delivery',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationMap extends StatelessWidget {
  const _LocationMap({
    required this.point,
    required this.controller,
    required this.loading,
    required this.error,
    required this.onCurrentLocation,
    required this.onPointSelected,
  });

  final LatLng? point;
  final MapController controller;
  final bool loading;
  final String? error;
  final VoidCallback onCurrentLocation;
  final ValueChanged<LatLng> onPointSelected;

  @override
  Widget build(BuildContext context) {
    final fallback = point ?? const LatLng(31.5204, 74.3587);
    return Container(
      height: 245,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE2),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: fallback,
                initialZoom: point == null ? 11 : 16,
                onTap: (_, tappedPoint) => onPointSelected(tappedPoint),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.burgerhouse.customer',
                ),
                if (point != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point!,
                        width: 58,
                        height: 68,
                        alignment: Alignment.topCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 12,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Positioned(
            right: 14,
            bottom: 14,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              elevation: 5,
              child: IconButton(
                tooltip: 'Use my current location',
                onPressed: loading ? null : onCurrentLocation,
                icon: const Icon(Icons.my_location_rounded),
                color: AppColors.orange,
              ),
            ),
          ),
          if (loading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white70,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Finding your location...',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (error != null && !loading)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Material(
                color: AppColors.dark,
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_off_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onCurrentLocation,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tap map to adjust pin',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
