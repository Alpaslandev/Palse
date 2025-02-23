import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/features/comment/viewmodel/comment_view_model.dart';
import 'package:palseapp/features/comment/widgets/add_comment_bottom_sheet.dart';
import 'package:palseapp/features/comment/widgets/comment_card.dart';
import 'package:palseapp/features/comment/widgets/empty_comment_view.dart';
import 'package:provider/provider.dart';

// Ana yorum görünümü
class CommentView extends StatelessWidget {
  final Customer customer;
  const CommentView({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CommentViewModel(customer),
      child: Consumer<CommentViewModel>(
        builder: (context, viewModel, child) => _buildScaffold(context, viewModel),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, CommentViewModel viewModel) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(viewModel),
      bottomNavigationBar: _buildBottomBar(context, viewModel),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Yorumlar'),
    );
  }

  Widget _buildBody(CommentViewModel viewModel) {
    if (viewModel.comments.isEmpty) {
      return const EmptyCommentView();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.comments.length,
      itemBuilder: (context, index) => CommentCard(
        comment: viewModel.comments[index],
        customer: customer,
        viewModel: viewModel,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CommentViewModel viewModel) {
    final currentUser = context.read<AuthProvider>().user!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _showAddCommentSheet(context, viewModel, currentUser),
          child: const Text('Yorum Ekle'),
        ),
      ),
    );
  }

  void _showAddCommentSheet(BuildContext context, CommentViewModel viewModel, Customer currentUser) {
    AddCommentBottomSheet.show(
      context,
      viewModel: viewModel,
      currentUserID: currentUser.userID ?? '',
      currentUserName: currentUser.fullName(),
      currentUserProfilePictureUrl: currentUser.profilePictureUrl ?? '',
    );
  }
}
