import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/advert.dart';

// İlanın başlık ve açıklama gibi detaylarını gösteren widget
class AdvertDetails extends StatefulWidget {
  const AdvertDetails({super.key, required this.advert});

  final Advert advert;

  @override
  State<AdvertDetails> createState() => _AdvertDetailsState();
}

class _AdvertDetailsState extends State<AdvertDetails> {
  final ValueNotifier<bool> _showFullDescription = ValueNotifier<bool>(false);

  // Açıklamanın uzun olup olmadığını kontrol eden yardımcı metod
  bool _isDescriptionLong(String description) {
    // Yaklaşık olarak 5 satırdan uzun olup olmadığını kontrol et
    // Ortalama bir satırda 50 karakter olduğunu varsayalım
    return description.length > 200;
  }

  @override
  void dispose() {
    _showFullDescription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: _showFullDescription,
        builder: (context, showFull, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İlan başlığı
                Text(
                  widget.advert.title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // İlan açıklaması
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.advert.description,
                      style: const TextStyle(fontSize: 12),
                      maxLines: showFull ? null : 5,
                      overflow: showFull
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),

                    // Açıklama 5 satırdan uzunsa "Devamını Gör" butonu göster
                    if (_isDescriptionLong(widget.advert.description))
                      GestureDetector(
                        onTap: () {
                          _showFullDescription.value =
                              !_showFullDescription.value;
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            showFull
                                ? context.tr('show_less')
                                : context.tr('show_more'),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        });
  }
}
