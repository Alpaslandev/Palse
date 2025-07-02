import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/widgets/premium_overlay.dart';
import 'package:palseapp/features/story/view/story_preview_view.dart';
import 'package:photo_manager/photo_manager.dart';

// Kullanıcının hikaye eklemek için galeri ve kamera seçeneklerini gördüğü ekran.
class AddStoryView extends StatefulWidget {
  const AddStoryView({super.key});

  @override
  State<AddStoryView> createState() => _AddStoryViewState();
}

// Galeriden veya kameradan fotoğraf seçmek için yardımcı method.
Future<File?> pickImage(ImageSource source) async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: source);
  if (image != null) {
    return File(image.path);
  }
  return null;
}

class _AddStoryViewState extends State<AddStoryView> {
  List<AssetEntity> _mediaList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  // Cihaz galerisinden fotoğrafları çeker.
  Future<void> _fetchMedia() async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (!permitted.isAuth) {
      // İzin verilmediyse kullanıcıya bir uyarı gösterilebilir.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('gallery_permission_denied'))),
      );
      setState(() => _isLoading = false);
      return;
    }

    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final recentAlbum = albums.first;
    final media = await recentAlbum.getAssetListRange(start: 0, end: 100);

    if (mounted) {
      setState(() {
        _mediaList = media;
        _isLoading = false;
      });
    }
  }

  // Kamerayı açmak için kullanılan buton.
  Widget _buildCameraButton() {
    return GestureDetector(
      onTap: () async {
        final file = await pickImage(ImageSource.camera);
        if (file != null && mounted) {
          // Kameradan çekilen fotoğrafı önizleme ekranına gönder.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StoryPreviewView(
                imageFile: file,
                heroTag: 'camera_hero', // Kamera için sabit bir tag
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(
            Icons.camera_alt,
            size: 40,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  // Galerideki her bir fotoğraf için widget.
  Widget _buildMediaItem(AssetEntity asset) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailData,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.connectionState == ConnectionState.done && data != null) {
          return Hero(
            tag: asset.id, // Her görsel için benzersiz bir tag
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                data,
                fit: BoxFit.cover,
              ),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('add_story')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: PremiumOverlay(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _mediaList.isEmpty
                ? Center(
                    child: Text(
                      context.tr('no_images_found'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 3 / 4,
                    ),
                    itemCount: _mediaList.length + 1, // +1 kamera butonu için
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildCameraButton();
                      }
                      final asset = _mediaList[index - 1];
                      return GestureDetector(
                        onTap: () async {
                          final file = await asset.file;
                          if (file != null && mounted) {
                            // Galeriden seçilen fotoğrafı önizleme ekranına gönder.
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StoryPreviewView(
                                  imageFile: file,
                                  heroTag: asset.id,
                                ),
                              ),
                            );
                          }
                        },
                        child: _buildMediaItem(asset),
                      );
                    },
                  ),
      ),
    );
  }
}
