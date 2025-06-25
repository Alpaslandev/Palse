import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/features/story/model/story_model.dart';
import 'package:palseapp/features/story/viewmodel/story_view_model.dart';
import 'package:provider/provider.dart';

// Hikayeleri listeleyen ve yeni hikaye ekleme butonu sunan ana widget.
class StorysView extends StatelessWidget {
  const StorysView({super.key});

  @override
  Widget build(BuildContext context) {
    // ViewModel'i ve AuthProvider'ı sağlamak için.
    return ChangeNotifierProvider(
      create: (_) => StoryViewModel(),
      // Navigator'ı doğru context'te bulmak için Builder kullanıyoruz.
      child: Builder(builder: (context) {
        return const _StorysViewContent();
      }),
    );
  }
}

// FutureBuilder ve ListView'ı içeren esas UI widget'ı.
class _StorysViewContent extends StatelessWidget {
  const _StorysViewContent();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final viewModel = context.read<StoryViewModel>();

    // AuthProvider'dan kullanıcı bilgilerini ve takip listesini al.
    final currentUser = authProvider.user;
    if (currentUser == null) {
      // Kullanıcı yoksa boş bir görünüm döndür.
      return const SizedBox(height: 102);
    }
    final followingIds = currentUser.followings ?? [];

    return Container(
      height: 102,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FutureBuilder<List<StoryModel>>(
        future: viewModel.fetchStories(
          currentUserId: currentUser.userID!,
          followingIds: followingIds,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingSkeleton();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            // Hata durumunda sadece 'Hikaye Ekle' butonunu göster.
            return _buildAddStoryItem(context);
          }

          final stories = snapshot.data!;

          // Mevcut kullanıcının hikayesini diğerlerinden ayır.
          StoryModel? myStory;
          final otherStories = stories.where((story) {
            if (story.userId == authProvider.user!.userID!) {
              myStory = story;
              return false; // Kendi hikayeni diğerleri listesine ekleme
            }
            return true;
          }).toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: otherStories.length +
                1, // +1 ilk item için (benim hikayem veya ekle butonu)
            itemBuilder: (context, index) {
              // İlk eleman ya kullanıcının kendi hikayesi ya da ekleme butonu olacak.
              if (index == 0) {
                return myStory != null
                    ? GestureDetector(
                        onTap: () {
                          // Tıklanan hikayeyi ve diğerlerini görüntüleyiciye gönder
                          final List<StoryModel> allVisibleStories = [
                            ...otherStories
                          ];
                          if (myStory != null) {
                            allVisibleStories.insert(0, myStory!);
                          }

                          context.pushNamed(
                            storyDisplay,
                            extra: {
                              'stories': allVisibleStories,
                              'initialIndex': 0,
                            },
                          );
                        },
                        child: _buildStoryItem(context, myStory!,
                            isCurrentUser: true),
                      )
                    : _buildAddStoryItem(context);
              }
              // Diğer elemanlar
              final story = otherStories[index - 1];
              return GestureDetector(
                onTap: () {
                  final List<StoryModel> allVisibleStories = [...otherStories];
                  if (myStory != null) {
                    allVisibleStories.insert(0, myStory!);
                  }
                  // Tıklanan hikayenin birleştirilmiş listedeki index'ini bul
                  final tappedIndex = allVisibleStories.indexOf(story);

                  context.pushNamed(
                    storyDisplay,
                    extra: {
                      'stories': allVisibleStories,
                      'initialIndex': tappedIndex,
                    },
                  );
                },
                child: _buildStoryItem(context, story),
              );
            },
          );
        },
      ),
    );
  }

  // Yükleme sırasında gösterilecek iskelet (skeleton) widget'ı.
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 10,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        );
      },
    );
  }

  // Hikaye ekleme butonu widget'ı.
  Widget _buildAddStoryItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => context.pushNamed(addStory),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor, width: 2),
                color: Theme.of(context).cardColor,
              ),
              child:
                  const Icon(Icons.add, size: 32, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 4),
            const Text('Hikaye Ekle',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // Sunucudan gelen her bir hikaye için item widget'ı.
  Widget _buildStoryItem(BuildContext context, StoryModel story,
      {bool isCurrentUser = false}) {
    // Burada gerçek kullanıcı verileri kullanılabilir.
    // isCurrentUser bayrağı, kullanıcının kendi hikayesi için farklı bir çerçeve vs. yapmak için kullanılabilir.
    final borderColor = isCurrentUser ? Colors.grey : Colors.purple;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => debugPrint('${story.id} hikayesi açıldı'),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [borderColor, borderColor.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(story.imageUrl),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                isCurrentUser
                    ? 'Hikayen'
                    : 'Kullanıcı Adı', // `story.userId` ile kullanıcı bilgisi çekilebilir
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
