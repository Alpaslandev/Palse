import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

/// Konum örnek sayfası
/// Bu sayfa, konum servisini kullanarak konum bilgilerini gösterir
class LocationExamplePage extends StatefulWidget {
  const LocationExamplePage({super.key});

  @override
  State<LocationExamplePage> createState() => _LocationExamplePageState();
}

class _LocationExamplePageState extends State<LocationExamplePage> {
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Örneği'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Konum bilgilerini göster
              if (_currentPosition != null) ...[
                Text(
                  'Enlem: ${_currentPosition!.latitude}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Boylam: ${_currentPosition!.longitude}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (_currentAddress != null)
                  Text(
                    'Adres: $_currentAddress',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
              ] else if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Konum bilgileri alınıyor...'),
              ] else ...[
                const Text(
                  'Konum bilgisi henüz alınmadı.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
              const SizedBox(height: 32),
              // Konum alma butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _getLocation,
                child: const Text('Konumu Al'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Konum bilgilerini alır
  Future<void> _getLocation() async {
    setState(() {
      _isLoading = true;
    });

    // Konum izinlerini kontrol et ve gerekirse iste
    bool hasPermission = await LocationService.checkAndRequestPermission(context);

    if (hasPermission) {
      // Konum bilgilerini al
      Position? position = await LocationService.getCurrentLocation();

      if (position != null) {
        // Adres bilgilerini al
        String? address = await LocationService.getAddressFromPosition(position);

        setState(() {
          _currentPosition = position;
          _currentAddress = address;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum bilgileri alınamadı.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
