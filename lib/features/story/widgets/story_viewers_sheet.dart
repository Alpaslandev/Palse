import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Bir hikayeyi görüntüleyen kullanıcıları listeleyen modal bottom sheet.
class StoryViewersSheet extends StatefulWidget {
  final List<String> viewerIds;

  const StoryViewersSheet({super.key, required this.viewerIds});

  @override
  State<StoryViewersSheet> createState() => _StoryViewersSheetState();
}

class _StoryViewersSheetState extends State<StoryViewersSheet> {
  late Future<List<Customer>> _viewersFuture;
  final CustomerService _customerService = CustomerService();

  @override
  void initState() {
    super.initState();
    // Görüntüleyen kullanıcıların bilgilerini ID'leri ile çek.
    // Firestore 'in' sorgusu en fazla 30 eleman alabildiği için,
    // normalde bu listenin parçalara bölünmesi gerekir. Şimdilik basit tutuyoruz.
    _viewersFuture = _customerService.getUsersByIds(widget.viewerIds);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Görüntüleyenler (${widget.viewerIds.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          FutureBuilder<List<Customer>>(
            future: _viewersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const Center(child: Text('Henüz kimse görmedi.'));
              }

              final viewers = snapshot.data!;

              return Expanded(
                child: ListView.builder(
                  itemCount: viewers.length,
                  itemBuilder: (context, index) {
                    final viewer = viewers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundImage: viewer.profilePictureUrl != null
                            ? CachedNetworkImageProvider(
                                viewer.profilePictureUrl!)
                            : null,
                        child: viewer.profilePictureUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(viewer.nickname ?? 'Bilinmeyen Kullanıcı'),
                      onTap: () {
                        // Sayfayı kapat ve profil sayfasına git.
                        Navigator.of(context).pop();
                        context.pushNamed(friendProfile, extra: viewer.userID);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
