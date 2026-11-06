import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/distance_calculator.dart';
import '../../models/match_model.dart';
import '../../providers/map_provider.dart';
import '../../widgets/match_marker_sheet.dart';

class AdventureMapScreen extends ConsumerStatefulWidget {
  const AdventureMapScreen({super.key});

  @override
  ConsumerState<AdventureMapScreen> createState() => _AdventureMapScreenState();
}

class _AdventureMapScreenState extends ConsumerState<AdventureMapScreen> {
  final MapController _mapController = MapController();

  void _onMatchTapped(MatchModel match, String distanceText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MatchMarkerSheet(
        match: match,
        distanceText: distanceText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final mapNotifier = ref.read(mapProvider.notifier);

    final userLoc = mapState.currentUserLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adventure Map & Radar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => mapNotifier.initMap(),
            tooltip: 'Refresh Map & Nearby Matches',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Interactive Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLoc,
              initialZoom: 14.2,
              minZoom: 4,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.roamora.app',
              ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // Current User "YOU" Marker
                  Marker(
                    point: userLoc,
                    width: 70,
                    height: 70,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                            ],
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.coralGradient,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.coral.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.person, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Feature 16: Consented Mutual Match Markers with Live Distances
                  ...mapState.matchLocations.map((match) {
                    final matchLat = match.latitude ?? 28.5620;
                    final matchLon = match.longitude ?? 77.2010;
                    final distanceText = DistanceCalculator.formatDistance(
                      lat1: userLoc.latitude,
                      lon1: userLoc.longitude,
                      lat2: matchLat,
                      lon2: matchLon,
                    );

                    return Marker(
                      point: LatLng(matchLat, matchLon),
                      width: 100,
                      height: 85,
                      child: GestureDetector(
                        onTap: () => _onMatchTapped(match, distanceText),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Distance Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.coral,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                                ],
                              ),
                              child: Text(
                                distanceText,
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Match Avatar Marker
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: match.image != null && match.image!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: match.image!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: AppColors.coralSoft),
                                        errorWidget: (_, __, ___) => _buildInitials(match.name),
                                      )
                                    : _buildInitials(match.name),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Drops & Quests Markers
                  ...mapState.drops.map((drop) {
                    return Marker(
                      point: LatLng(drop.latitude, drop.longitude),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _showDropDialog(drop, mapNotifier),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6),
                            ],
                          ),
                          child: const Center(child: Text('🎁', style: TextStyle(fontSize: 18))),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. Floating "Locate Me" Button
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'locate_me_fab',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.coral,
                  onPressed: () async {
                    await mapNotifier.locateMe();
                    _mapController.move(ref.read(mapProvider).currentUserLocation, 14.5);
                  },
                  tooltip: 'Center on my location',
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(String name) {
    return Container(
      color: AppColors.coral,
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'M',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  void _showDropDialog(dynamic drop, MapNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🎁 '),
            Expanded(child: Text(drop.title as String, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Text(drop.description as String, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await notifier.collectDrop(drop.id as String);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? '🎉 Quest reward collected!' : 'Could not collect drop.')),
                );
              }
            },
            child: const Text('Claim Reward'),
          ),
        ],
      ),
    );
  }
}
