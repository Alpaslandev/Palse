import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/features/story/model/story_model.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/keys/global_keys.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    final viewModel = context.read<StoryViewModel>();
    final authProvider = context.read<AuthProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _markAsViewed(viewModel, authProvider, widget.initialIndex);
        _startTimer();
      }
    });

    _progressController.addStatusListener((status) {
      if (mounted && status == AnimationStatus.completed) {
        _nextStory();
      }
    });
  }

  void _markAsViewed(
      StoryViewModel viewModel, AuthProvider authProvider, int index) {
    if (index >= widget.stories.length) return;
    final story = widget.stories[index];
    final currentUserId = authProvider.user?.userID;

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
        await viewModel.deleteStory(storyId: story.id, userId: currentUserId);
        // Hikaye silindikten sonra ana sayfadaki hikayeleri yenile
        GlobalKeys.instance.storysViewKey.currentState?.refreshStories();
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(context.tr(
              'story_deletion_error',
            ))),
          );
        }
      }
    }
  }

  void _startTimer() {
    if (!mounted || widget.isCurrentUserStory) return;
    _progressController.forward();
  }

  void _pauseTimer() {
    if (!mounted) return;
    _progressController.stop();
  }

  void _resumeTimer() {
    if (!mounted) return;
    _progressController.forward();
  }

  void _nextStory() {
    if (!mounted) return;
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  void _previousStory() {
    if (!mounted) return;
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildProgressBars() {
    return Row(
      children: List.generate(
        widget.stories.length,
        (index) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: (index == _currentIndex)
                      ? _progressController.value
                      : (index < _currentIndex ? 1.0 : 0.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.5),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  borderRadius: BorderRadius.circular(2),
                );
              },
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.stories.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              _progressController.reset();
              _markAsViewed(viewModel, authProvider, index);
              _startTimer();
            },
            itemBuilder: (context, index) {
              return _StoryPage(
                story: widget.stories[index],
                isOwner:
                    widget.stories[index].userId == authProvider.user?.userID,
                onDelete: () => _deleteStory(viewModel, authProvider, index),
                onNext: _nextStory,
                onPrevious: _previousStory,
                onPause: _pauseTimer,
                onResume: _resumeTimer,
                isSingleStory: widget.isCurrentUserStory,
              );
            },
          ),
          if (!widget.isCurrentUserStory)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 12,
              right: 12,
              child: _buildProgressBars(),
            ),
        ],
      ),
    );
  }
}

// Tek bir hikayeyi ve tüm etkileşimlerini yöneten widget.
class _StoryPage extends StatelessWidget {
  final StoryModel story;
  final bool isOwner;
  final bool isSingleStory;
  final VoidCallback? onDelete;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _StoryPage({
    required this.story,
    required this.isOwner,
    required this.isSingleStory,
    this.onDelete,
    required this.onNext,
    required this.onPrevious,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPause(),
      onTapUp: (_) => onResume(),
      onLongPressStart: (_) => onPause(),
      onLongPressEnd: (_) => onResume(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // 1. Katman: Sonraki/Önceki hikaye için dokunma alanları
              if (!isSingleStory)
                Row(
                  children: [
                    Expanded(
                        child: GestureDetector(
                            onTap: onPrevious,
                            child: Container(color: Colors.transparent))),
                    Expanded(
                        child: GestureDetector(
                            onTap: onNext,
                            child: Container(color: Colors.transparent))),
                  ],
                ),

              // 2. Katman: Hikaye görseli
              Center(
                child: CachedNetworkImage(
                  imageUrl: story.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.white),
                ),
              ),

              // 3. Katman: Üst ve Alt UI elemanları (Header/Footer)
              Column(
                children: [
                  const SizedBox(height: 10),
                  // Header: Kullanıcı bilgisi ve kapatma butonu
                  _buildHeader(context),
                  const Spacer(),
                  // Footer: Görüntüleyenler ve silme butonu (sadece sahipse)
                  if (isOwner) _buildFooter(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      // Gölge ve gradient arka plan
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: isOwner
                  ? null
                  : () {
                      context.pushNamed(friendProfile, extra: story.userId);
                    },
              child: Row(
                children: [
                  // Profil resmi için border efekti
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage:
                          CachedNetworkImageProvider(story.profilePictureUrl),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Kullanıcı adı ve altındaki çizgi
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        story.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Kullanıcı adının altındaki şık çizgi
                      Container(
                        height: 2,
                        width: story.username.length * 8.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.8),
                              Colors.white.withValues(alpha: 0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Kapatma butonu için şık container
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hikaye silme onay dialogunu gösterir
  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            context.tr('delete_story'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            context.tr('delete_story_confirmation'),
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.tr('cancel'),
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onDelete != null) {
                  onDelete!();
                }
              },
              child: Text(
                context.tr('delete'),
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => StoryViewersSheet(viewerIds: story.viewedBy),
        );
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.visibility, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${story.viewedBy.length} ${context.tr('people_viewed')}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            IconButton(
              onPressed: () => _showDeleteConfirmDialog(context),
              icon: const Icon(Icons.delete, color: Colors.red, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}
