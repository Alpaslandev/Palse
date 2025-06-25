import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/features/story/model/story_model.dart';
import 'package:palseapp/core/routes/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/features/story/viewmodel/story_view_model.dart';
import 'package:palseapp/features/story/widgets/story_viewers_sheet.dart';
import 'package:provider/provider.dart';

// Birden çok hikayeyi tam ekran gösteren ve aralarında geçiş sağlayan ana widget.
class StoryDisplayView extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final bool isCurrentUserStory;

  const StoryDisplayView({
    super.key,
    required this.stories,
    required this.initialIndex,
    this.isCurrentUserStory = false,
  });

  @override
  State<StoryDisplayView> createState() => _StoryDisplayViewState();
}

class _StoryDisplayViewState extends State<StoryDisplayView>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentIndex = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Progress animation controller - 5 saniye
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    // initState içinde context.read kullanmak güvenlidir.
    final viewModel = context.read<StoryViewModel>();
    final authProvider = context.read<AuthProvider>();

    // Widget oluşturulduktan hemen sonra ilk hikayeyi "görüldü" olarak işaretle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsViewed(viewModel, authProvider, widget.initialIndex);
      _startTimer();
    });

    // Timer bittiğinde otomatik geçiş
    _progressController.addStatusListener((status) {
      if (mounted && status == AnimationStatus.completed && !_isPaused) {
        _nextStory();
      }
    });
  }

  void _markAsViewed(
      StoryViewModel viewModel, AuthProvider authProvider, int index) {
    final story = widget.stories[index];
    final currentUserId = authProvider.user?.userID;

    // Kullanıcı kendi hikayesini görüntülemiş sayılmaz.
    if (currentUserId != null && story.userId != currentUserId) {
      viewModel.markStoryAsViewed(
        storyId: story.id,
        viewerId: currentUserId,
      );
    }
  }

  void _deleteStory(
      StoryViewModel viewModel, AuthProvider authProvider, int index) async {
    final story = widget.stories[index];
    final currentUserId = authProvider.user?.userID;
    if (currentUserId != null) {
      try {
        // Silme işlemini başlat
        await viewModel.deleteStory(storyId: story.id, userId: currentUserId);

        // Silme başarılı olursa ekranı kapat
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        // Hata durumunda kullanıcıya bilgi ver
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hikaye silinirken hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Timer'ı başlatır
  void _startTimer() {
    if (!mounted || widget.isCurrentUserStory) return;
    _progressController.forward();
  }

  // Timer'ı duraklatır
  void _pauseTimer() {
    if (!mounted || _isPaused) return;
    _isPaused = true;
    _progressController.stop();
  }

  // Timer'ı devam ettirir
  void _resumeTimer() {
    if (!mounted || !_isPaused) return;
    _isPaused = false;
    _progressController.forward();
  }

  // Sonraki hikayeye geçer
  void _nextStory() {
    if (!mounted) return; // Widget dispose edilmişse işlem yapma

    if (_currentIndex < widget.stories.length - 1) {
      _currentIndex++;
      _progressController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startTimer();
    } else {
      // Son hikaye, ekranı kapat
      if (mounted) {
        context.pop();
      }
    }
  }

  // Önceki hikayeye geçer
  void _previousStory() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _progressController.reset();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startTimer();
    }
  }

  // Progress bar'ları oluşturur
  Widget _buildProgressBars() {
    return Row(
      children: List.generate(
        widget.stories.length,
        (index) => Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: index == _currentIndex
                ? AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.transparent,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        borderRadius: BorderRadius.circular(2),
                      );
                    },
                  )
                : LinearProgressIndicator(
                    value: index < _currentIndex ? 1.0 : 0.0,
                    backgroundColor: Colors.transparent,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    borderRadius: BorderRadius.circular(2),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<StoryViewModel>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      body: GestureDetector(
        onTapDown: (_) => _pauseTimer(),
        onTapUp: (_) => _resumeTimer(),
        onTapCancel: () => _resumeTimer(),
        onLongPressStart: (_) => _pauseTimer(),
        onLongPressEnd: (_) => _resumeTimer(),
        child: Stack(
          children: [
            // Ana içerik
            widget.isCurrentUserStory
                ? _StoryPage(
                    story: widget.stories[widget.initialIndex],
                    onDelete: () => _deleteStory(
                        viewModel, authProvider, widget.initialIndex),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: widget.stories.length,
                    onPageChanged: (index) {
                      _currentIndex = index;
                      _progressController.reset();
                      _markAsViewed(viewModel, authProvider, index);
                      _startTimer();
                    },
                    itemBuilder: (context, index) {
                      return _StoryPage(
                        story: widget.stories[index],
                        onDelete: () =>
                            _deleteStory(viewModel, authProvider, index),
                      );
                    },
                  ),

            // Progress bar (sadece başkalarının hikayeleri için)
            if (!widget.isCurrentUserStory)
              Positioned(
                top: MediaQuery.of(context).padding.top + 2,
                left: 8,
                right: 8,
                child: _buildProgressBars(),
              ),

            // Sol ve sağ touch alanları (sadece başkalarının hikayeleri için)
            if (!widget.isCurrentUserStory)
              Positioned.fill(
                child: Row(
                  children: [
                    // Sol yarı - önceki hikaye
                    Expanded(
                      child: GestureDetector(
                        onTap: _previousStory,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    // Sağ yarı - sonraki hikaye
                    Expanded(
                      child: GestureDetector(
                        onTap: _nextStory,
                        child: Container(color: Colors.transparent),
                      ),
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

// Tek bir hikayeyi gösteren sayfa widget'ı.
class _StoryPage extends StatelessWidget {
  final StoryModel story;
  final VoidCallback? onDelete;

  const _StoryPage({
    required this.story,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // AuthProvider'dan mevcut kullanıcı ID'sini alarak hikaye sahibini kontrol et.
    final currentUserId = context.read<AuthProvider>().user?.userID;
    final isOwner = story.userId == currentUserId;

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
                  GestureDetector(
                    onTap: isOwner
                        ? null
                        : () {
                            // Mevcut sayfayı kapat ve profil sayfasına git
                            context.pop();
                            context.pushNamed(friendProfile,
                                extra: story.userId);
                          },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: CachedNetworkImageProvider(
                              story.profilePictureUrl),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          story.username,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.pop(),
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
              GestureDetector(
                onTap: () {
                  // Görüntüleyenleri gösteren bottom sheet'i aç.
                  showModalBottomSheet(
                    context: context,
                    builder: (_) =>
                        StoryViewersSheet(viewerIds: story.viewedBy),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.visibility,
                              color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${story.viewedBy.length} kişi tarafından görüldü',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          // Silme mantığı
                          debugPrint('${story.id} hikayesi silinecek.');
                          onDelete?.call();
                        },
                        icon: const Icon(Icons.delete,
                            color: Colors.red, size: 30),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
