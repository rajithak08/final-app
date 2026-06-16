import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapView extends StatefulWidget {
  final String? sourceLocation;
  final String? destinationLocation;

  const GoogleMapView({
    Key? key,
    this.sourceLocation,
    this.destinationLocation,
  }) : super(key: key);

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> {
  GoogleMapController? _mapController;

  // Predefined locations mapping to actual coordinates
  static const Map<String, LatLng> _locationCoords = {
    'IIITS': LatLng(13.5574, 80.0272),
    'Tada': LatLng(13.5735, 80.0276),
    'Sullurupeta': LatLng(13.7008, 80.0209),
    'Gummidipoondi': LatLng(13.4074, 80.1197),
    'Tirupati': LatLng(13.6288, 79.4192),
    'Chennai': LatLng(13.0827, 80.2707),
    'Arambakkam': LatLng(13.4831, 80.1167),
  };

  // Central default location (IIITS Sri City)
  static const LatLng _defaultCenter = LatLng(13.5574, 80.0272);

  @override
  void didUpdateWidget(covariant GoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCameraPosition();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateCameraPosition();
  }

  void _updateCameraPosition() {
    if (_mapController == null) return;

    final sourceLatLng = _locationCoords[widget.sourceLocation];
    final destLatLng = _locationCoords[widget.destinationLocation];

    if (sourceLatLng != null && destLatLng != null) {
      // Both source and destination selected: fit bounds to show both
      final bounds = LatLngBounds(
        southwest: LatLng(
          sourceLatLng.latitude < destLatLng.latitude ? sourceLatLng.latitude : destLatLng.latitude,
          sourceLatLng.longitude < destLatLng.longitude ? sourceLatLng.longitude : destLatLng.longitude,
        ),
        northeast: LatLng(
          sourceLatLng.latitude > destLatLng.latitude ? sourceLatLng.latitude : destLatLng.latitude,
          sourceLatLng.longitude > destLatLng.longitude ? sourceLatLng.longitude : destLatLng.longitude,
        ),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80.0), // Padding of 80px
      );
    } else if (sourceLatLng != null) {
      // Only source selected: center camera there
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(sourceLatLng, 13.5),
      );
    } else if (destLatLng != null) {
      // Only destination selected: center camera there
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(destLatLng, 13.5),
      );
    } else {
      // Default position
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_defaultCenter, 11.5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceLatLng = _locationCoords[widget.sourceLocation];
    final destLatLng = _locationCoords[widget.destinationLocation];

    final Set<Marker> markers = {};
    final Set<Polyline> polylines = {};

    // Source Marker
    if (sourceLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('source_marker'),
          position: sourceLatLng,
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: widget.sourceLocation,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    // Destination Marker
    if (destLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination_marker'),
          position: destLatLng,
          infoWindow: InfoWindow(
            title: 'Dropoff',
            snippet: widget.destinationLocation,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Connect them with a route polyline if both selected
    if (sourceLatLng != null && destLatLng != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_polyline'),
          points: [sourceLatLng, destLatLng],
          color: Colors.blueAccent,
          width: 5,
          geodesic: true,
          jointType: JointType.round,
        ),
      );
    }

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: const CameraPosition(
        target: _defaultCenter,
        zoom: 11.5,
      ),
      markers: markers,
      polylines: polylines,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}
