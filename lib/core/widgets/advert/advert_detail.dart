import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/widgets/advert/helper/detail_appbar.dart';

class AdvertDetail extends StatelessWidget {
  const AdvertDetail({super.key, required this.advert});
  final Advert advert;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DetailAppbar(
        onBlock: () {
          debugPrint('block');
        },
        onFilter: () {
          debugPrint('filter');
        },
        onReport: () {
          debugPrint('report');
        },
      ),
      body: Column(
        children: [
          Image.network(advert.advertImage),
          Text(advert.advertName),
          Text(advert.advertLastUsage),
        ],
      ),
    );
  }
}
