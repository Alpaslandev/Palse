import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/features/story/model/story_model.dart';
import 'package:palseapp/features/story/viewmodel/story_view_model.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Hikayeleri listeleyen ve yeni hikaye ekleme butonu sunan ana widget.
class StorysView extends StatefulWidget {
  const StorysView({super.key});

  @override
  State<StorysView> createState() => StorysViewState();
}

class StorysViewState extends State<StorysView> {
  late StoryViewModel _viewModel;
  Future<List<StoryModel>>? _storiesFuture;

  @override
  void initState() {
    super.initState();
    _viewModel = StoryViewModel();
    _loadStories();
  }

  void _loadStories() {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;
    if (currentUser != null) {
      final followingIds = currentUser.followings ?? [];
      setState(() {
        _storiesFuture = _viewModel.fetchStories(
          currentUserId: currentUser.userID!,
          followingIds: followingIds,
        );
      });
    }
  }

  // Hikayeleri yeniler
  void refreshStories() {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;
    if (currentUser != null) {
      final followingIds = currentUser.followings ?? [];
      setState(() {
        _storiesFuture = _viewModel
            .refreshStories(
              currentUserId: currentUser.userID!,
              followingIds: followingIds,
            )
            .then((_) => _viewModel.fetchStories(
                  currentUserId: currentUser.userID!,
                  followingIds: followingIds,
                  forceRefresh: true,
                ));
      });
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: _StorysViewContent(storiesFuture: _storiesFuture),
    );
  }
}

// FutureBuilder ve ListView'ı içeren esas UI widget'ı.
class _StorysViewContent extends StatelessWidget {
  final Future<List<StoryModel>>? storiesFuture;

  const _StorysViewContent({required this.storiesFuture});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final viewModel = context.read<StoryViewModel>();

    // AuthProvider'dan kullanıcı bilgilerini ve takip listesini al.
    final currentUser = authProvider.user;
    if (currentUser == null || storiesFuture == null) {
      // Kullanıcı yoksa boş bir görünüm döndür.
      return const SizedBox(height: 102);
    }

    return Container(
      height: 102,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FutureBuilder<List<StoryModel>>(
        future: storiesFuture,
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
                    ? _buildStoryItem(context, myStory!, stories, viewModel,
                        isCurrentUser: true)
                    : _buildAddStoryItem(context);
              }
              // Diğer elemanlar
              final story = otherStories[index - 1];
              return _buildStoryItem(context, story, stories, viewModel);
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
            Text(context.tr('add_story'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // Sunucudan gelen her bir hikaye için item widget'ı.
  Widget _buildStoryItem(BuildContext context, StoryModel story,
      List<StoryModel> allStories, StoryViewModel viewModel,
      {bool isCurrentUser = false}) {
    final borderColor = isCurrentUser ? Colors.grey : Colors.purple;

    return GestureDetector(
      onTap: () {
        // Eğer kendi hikayemizi açıyorsak, sadece kendi hikayemizi göster
        // Eğer başkasının hikayesini açıyorsak, kendi hikayemizi listeden çıkar
        List<StoryModel> displayStories;
        int displayIndex;

        if (isCurrentUser) {
          // Kendi hikayemizi açıyorsak sadece kendi hikayemizi göster
          displayStories = [story];
          displayIndex = 0;
        } else {
          // Başkasının hikayesini açıyorsak kendi hikayemizi listeden çıkar
          final authProvider = context.read<AuthProvider>();
          final currentUserId = authProvider.user?.userID;
          displayStories =
              allStories.where((s) => s.userId != currentUserId).toList();
          displayIndex = displayStories.indexOf(story);
        }

        // StoryModel'leri GoRouter için JSON'a çevir
        final storiesJson =
            displayStories.map((s) => s.toRouterJson()).toList();

        context.pushNamed(
          storyDisplay,
          extra: {
            'stories': storiesJson,
            'initialIndex': displayIndex,
            'isCurrentUserStory': isCurrentUser,
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Hero(
              tag: story.id, // Animasyon için benzersiz tag
              child: Container(
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
                  backgroundImage:
                      CachedNetworkImageProvider(story.profilePictureUrl),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                isCurrentUser ? context.tr('my_story') : story.username,
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
