import 'package:flutter/material.dart';
import 'package:palseapp/core/models/location_model.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/core/services/location_service.dart';
import 'package:palseapp/core/utils/debouncer.dart';

class LocationStep extends StatefulWidget {
  const LocationStep({super.key, required this.viewModel});
  final ProfileSetupViewModel viewModel;
  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  final Debouncer _debouncer = Debouncer(milliseconds: 300);
  List<LocationModel> _suggestions = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Konum seçilip seçilmediğini kontrol et
    final bool isLocationSelected = widget.viewModel.isLocationValid();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık kısmı
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1.0,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Konumunuzu Belirtin',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Şehir, ilçe adını yazın veya mevcut konumunuzu kullanın',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      if (!isLocationSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Zorunlu',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Konum arama ve mevcut konum bölümü
            Column(
              children: [
                _buildSearchField(isLocationSelected),
                const SizedBox(height: 12),
                _buildCurrentLocationButton(isLocationSelected),
              ],
            ),

            // Konum seçilmediğinde uyarı mesajı göster
            if (!isLocationSelected)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red.shade400, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Lütfen bir konum seçin',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Öneriler listesi
            SizedBox(
              height: 200, // Sabit yükseklik
              child: _buildSuggestionsList(),
            ),

            // Seçilen konum bilgisi
            if (isLocationSelected)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Seçilen Konum:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 20, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.viewModel.cityController.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.gps_fixed, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Koordinatlar: ${widget.viewModel.customer.location?.geoPoint?.latitude.toStringAsFixed(4) ?? ''}, ${widget.viewModel.customer.location?.geoPoint?.longitude.toStringAsFixed(4) ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Klavye açıldığında alt kısmın görünmesi için ekstra boşluk
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isLocationSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: isLocationSelected ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.viewModel.cityController,
        textCapitalization: TextCapitalization.words, // Her kelimenin ilk harfi büyük
        decoration: InputDecoration(
          labelText: 'Konum Ara',
          hintText: 'Şehir veya ilçe adı girin',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: !isLocationSelected ? Colors.red : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: !isLocationSelected ? Colors.red : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isLocationSelected ? Colors.green : Theme.of(context).primaryColor,
              width: 2.0,
            ),
          ),
          prefixIcon: Icon(
            Icons.location_on,
            color: isLocationSelected ? Colors.green : null,
          ),
          suffixIcon: _isLoading
              ? Container(
                  padding: const EdgeInsets.all(12),
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.viewModel.cityController.clear();
                    widget.viewModel.districtController.clear();
                    setState(() {
                      _suggestions.clear();
                    });
                  },
                ),
          fillColor: Colors.white,
          filled: true,
        ),
        onChanged: (value) => _searchLocation(value),
      ),
    );
  }

  Widget _buildCurrentLocationButton(bool isLocationSelected) {
    return InkWell(
      onTap: _getCurrentLocation,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLocationSelected ? Colors.green : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.my_location,
              color: isLocationSelected ? Colors.green : Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            const Text(
              'Mevcut Konumumu Kullan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(top: 8),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            leading: const Icon(Icons.location_on),
            title: Text('${suggestion.city}, ${suggestion.district}'),
            subtitle: Text(suggestion.displayName ?? '', style: Theme.of(context).textTheme.bodySmall),
            onTap: () => _selectLocation(suggestion),
          );
        },
      ),
    );
  }

  // Mevcut konumu al
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final locationModel = await LocationService().getCurrentLocationModel();
      if (context.mounted && locationModel != null) {
        widget.viewModel.updateCoordinates(locationModel);
        widget.viewModel.cityController.text = '${locationModel.country}, ${locationModel.city}, ${locationModel.district}';
        setState(() => _suggestions.clear());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Konum alınamadı: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Konum ara
  void _searchLocation(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestions.clear();
        _isLoading = false;
      });
      return;
    }

    if (query.length < 3) return;

    setState(() => _isLoading = true);

    _debouncer.run(() async {
      try {
        final results = await LocationService().searchLocation(query);
        setState(() => _suggestions = results);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Hata: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    });
  }

  // Konum seç
  void _selectLocation(LocationModel suggestion) {
    widget.viewModel.updateLocation(suggestion);
    widget.viewModel.cityController.text = '${suggestion.district}, ${suggestion.city}';
    setState(() {
      _suggestions.clear();
    });
    FocusScope.of(context).unfocus();
  }
}
