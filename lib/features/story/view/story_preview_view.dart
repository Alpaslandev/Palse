import 'dart:io';
import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/keys/global_keys.dart';
import 'package:palseapp/features/story/viewmodel/story_view_model.dart';
import 'package:provider/provider.dart';

// Seçilen bir fotoğrafı tam ekran gösteren ve paylaşım seçenekleri sunan widget.
class StoryPreviewView extends StatelessWidget {
  final File imageFile;
  final String heroTag;

  const StoryPreviewView({
    super.key,
    required this.imageFile,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    // ViewModel'i sağlamak için ChangeNotifierProvider kullanıyoruz.
    return ChangeNotifierProvider(
      create: (_) => StoryViewModel(),
      child: _StoryPreviewViewContent(
        imageFile: imageFile,
        heroTag: heroTag,
      ),
    );
  }
}

// Esas UI mantığını içeren özel widget.
class _StoryPreviewViewContent extends StatefulWidget {
  final File imageFile;
  final String heroTag;

  const _StoryPreviewViewContent({
    required this.imageFile,
    required this.heroTag,
  });

  @override
  State<_StoryPreviewViewContent> createState() =>
      __StoryPreviewViewContentState();
}

class __StoryPreviewViewContentState extends State<_StoryPreviewViewContent> {
  bool _isPublic = true; // Varsayılan olarak herkese açık

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StoryViewModel>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Hero(
            tag: widget.heroTag,
            child: Image.file(widget.imageFile),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Herkese Açık / Takipçilere Özel seçeneği
              Row(
                children: [
                  Switch(
                    value: _isPublic,
                    onChanged: viewModel.isLoading
                        ? null // Yükleme sırasında deaktif
                        : (value) {
                            setState(() {
                              _isPublic = value;
                            });
                          },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPublic ? context.tr('public') : context.tr('private'),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              // Paylaş butonu
              viewModel.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton.icon(
                      onPressed: () async {
                        final currentUser = authProvider.user;
                        if (currentUser == null) return;

                        final success = await viewModel.uploadStory(
                          imageFile: widget.imageFile,
                          userId: currentUser.userID!,
                          username: currentUser.nickname!,
                          profilePictureUrl: currentUser.profilePictureUrl!,
                          isPublic: _isPublic,
                        );

                        if (success && mounted) {
                          // Hikaye başarıyla yüklendikten sonra ana sayfadaki hikayeleri yenile
                          GlobalKeys.instance.storysViewKey.currentState
                              ?.refreshStories();
                          // Başarılı olursa tüm ekranları kapatıp ana ekrana dön
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        } else if (mounted) {
                          // Hata olursa kullanıcıya bilgi ver
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(context.tr('story_upload_error'))),
                          );
                        }
                      },
                      icon: const Icon(Icons.send),
                      label: Text(context.tr('share')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
