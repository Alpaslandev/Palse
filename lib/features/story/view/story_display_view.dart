import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palseapp/features/story/model/story_model.dart';

// Birden çok hikayeyi tam ekran gösteren ve aralarında geçiş sağlayan ana widget.
class StoryDisplayView extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryDisplayView({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryDisplayView> createState() => _StoryDisplayViewState();
}

class _StoryDisplayViewState extends State<StoryDisplayView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.stories.length,
        itemBuilder: (context, index) {
          return _StoryPage(story: widget.stories[index]);
        },
      ),
    );
  }
}

// Tek bir hikayeyi gösteren sayfa widget'ı.
class _StoryPage extends StatelessWidget {
  final StoryModel story;
  const _StoryPage({required this.story});

  @override
  Widget build(BuildContext context) {
    // Bu kısım daha sonra mevcut kullanıcı kontrolü ile zenginleştirilecek.
    const isOwner = true; // Geçici olarak true varsayalım

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Üst Kısım: Zaman çizelgesi, kullanıcı bilgisi ve kapatma butonu
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    // backgroundImage: NetworkImage(story.userProfileUrl), // Kullanıcı profili için
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Kullanıcı Adı', // story.username
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Ana İçerik: Hikaye görseli
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: CachedNetworkImage(
                  imageUrl: story.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
            // Alt Kısım: Sadece hikaye sahibine gösterilecek bölüm
            if (isOwner)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${story.viewedBy.length} kişi tarafından görüldü',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    IconButton(
                      onPressed: () {
                        // Silme mantığı
                        debugPrint('${story.id} hikayesi silinecek.');
                      },
                      icon:
                          const Icon(Icons.delete, color: Colors.red, size: 30),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
