import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../auth/services/auth_service.dart';
import '../../location/models/delivery_location.dart';
import '../../location/screens/location_setup_screen.dart';
import '../widgets/profile_page_header.dart';

class ProfileAddressScreen extends StatefulWidget {
  const ProfileAddressScreen({
    super.key,
    required this.initialLocation,
    required this.onLocationChanged,
  });

  final DeliveryLocation? initialLocation;
  final ValueChanged<DeliveryLocation> onLocationChanged;

  @override
  State<ProfileAddressScreen> createState() => _ProfileAddressScreenState();
}

class _ProfileAddressScreenState extends State<ProfileAddressScreen> {
  final _authService = AuthService();
  DeliveryLocation? _location;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation;
    if (_location == null) _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() => _loading = true);
    try {
      final location = await _authService.getDeliveryLocation();
      if (mounted) setState(() => _location = location);
    } catch (_) {
      // The empty state remains available if the address cannot be loaded.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editAddress() async {
    final updated = await Navigator.push<DeliveryLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSetupScreen(initialLocation: _location),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() => _location = updated);
    widget.onLocationChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profilePageBackground,
      body: Column(
        children: [
          ProfilePageHeader(
            title: 'MY ADDRESS',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.red),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
                    children: [
                      const Text(
                        'DELIVERY LOCATION',
                        style: TextStyle(
                          color: profilePageInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Your rider will use this address for every delivery.',
                        style: TextStyle(
                          color: profilePageMuted,
                          fontSize: 11.5,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (_location == null)
                        _EmptyAddressCard(onAdd: _editAddress)
                      else
                        _SavedAddressCard(
                          location: _location!,
                          onEdit: _editAddress,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  const _SavedAddressCard({required this.location, required this.onEdit});

  final DeliveryLocation location;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE6EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1247657A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  color: AppColors.blush,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  location.label.toLowerCase() == 'work'
                      ? Icons.work_outline_rounded
                      : Icons.home_outlined,
                  color: AppColors.red,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.label.toUpperCase(),
                      style: const TextStyle(
                        color: profilePageInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location.area,
                      style: const TextStyle(
                        color: profilePageMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
                child: const Text(
                  'EDIT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFE3EAF0)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: profilePageBlue,
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  location.formattedAddress,
                  style: const TextStyle(
                    color: profilePageInk,
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (location.latitude != null && location.longitude != null) ...[
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.my_location_rounded,
                    color: profilePageBlue,
                    size: 16,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Precise map location saved',
                    style: TextStyle(
                      color: profilePageBlue,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyAddressCard extends StatelessWidget {
  const _EmptyAddressCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE6EC)),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: AppColors.blush,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_location_alt_outlined,
              color: AppColors.red,
              size: 30,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'No delivery address yet',
            style: TextStyle(
              color: profilePageInk,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Add your location so checkout is faster and your rider can find you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: profilePageMuted,
              fontSize: 11,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            onPressed: onAdd,
            icon: Icons.add_rounded,
            label: 'ADD ADDRESS',
          ),
        ],
      ),
    );
  }
}
