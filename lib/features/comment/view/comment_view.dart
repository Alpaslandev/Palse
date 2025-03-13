import 'package:flutter/material.dart';
import 'package:palseapp/core/models/comment_model.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/features/comment/viewmodel/comment_view_model.dart';
import 'package:palseapp/features/comment/widgets/add_comment_bottom_sheet.dart';
import 'package:palseapp/features/comment/widgets/comment_card.dart';
import 'package:palseapp/features/comment/widgets/empty_comment_view.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/core/localization/app_localizations.dart';

// Ana yorum görünümü
class CommentView extends StatelessWidget {
  final Customer customer;
  const CommentView({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().user!;

    return ChangeNotifierProvider(
      create: (context) => CommentViewModel(customer),
      child: Consumer<CommentViewModel>(
        builder: (context, viewModel, child) => _buildScaffold(context, viewModel, currentUser),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, CommentViewModel viewModel, Customer currentUser) {
    debugPrint('viewModel.comments: ${viewModel.comments}');
    bool isMe = currentUser.userID == customer.userID;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('comments')),
      ),
      body: _buildBody(context, viewModel),
      bottomNavigationBar: isMe ? null : _buildBottomBar(context, viewModel, currentUser),
    );
  }

  Widget _buildBody(BuildContext context, CommentViewModel viewModel) {
    if (viewModel.comments.isEmpty) {
      return const EmptyCommentView();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.comments.length,
      itemBuilder: (context, index) => CommentCard(
        comment: viewModel.comments[index],
        onDeleteTap: () => viewModel.deleteComment(viewModel.comments[index]),
        onReportTap: () => viewModel.reportComment(viewModel.comments[index]),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CommentViewModel viewModel, Customer currentUser) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => _showAddCommentSheet(context, viewModel, currentUser),
          child: Text(context.tr('add_comment')),
        ),
      ),
    );
  }

  void _showAddCommentSheet(BuildContext context, CommentViewModel viewModel, Customer currentUser) async {
    final commentMap = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddCommentBottomSheet();
      },
    );

    if (commentMap != null) {
      final Comment comment = Comment(
        comment: commentMap['comment'],
        rating: commentMap['rating'],
        commenterID: currentUser.userID ?? '',
        commenterName: currentUser.fullName(),
        commenterProfilePictureUrl: currentUser.profilePictureUrl ?? '',
        commentDate: DateTime.now(),
      );
      debugPrint('Alınan yorum: ${comment.toString()}');

      // Kullanıcı ID'sini de geçirerek yorum ekleme işlemini başlat
      viewModel.addComment(comment, currentUser.userID ?? '');
    } else {
      debugPrint('Yorum eklenmedi');
    }
  }
}
