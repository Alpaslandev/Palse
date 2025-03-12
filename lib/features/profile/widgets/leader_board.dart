import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/features/achievement/achievement_service.dart';
import 'package:provider/provider.dart';

class LeaderBoardUser {
  final String nickname;
  final int xp;
  final String userId;

  LeaderBoardUser({required this.nickname, required this.xp, required this.userId});
}

class LeaderBoard extends StatelessWidget {
  const LeaderBoard({super.key});

  Future<List<LeaderBoardUser>> getLeaderBoard() async {
    final response = await FirebaseFirestore.instance.collection('leaderBoard').orderBy('xp', descending: true).get();
    return response.docs.map((doc) => LeaderBoardUser(nickname: doc['nickname'], xp: doc['xp'], userId: doc.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(context.tr('leaderboard')),
          ],
        ),
        leading: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.all(4),
            ),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            )),
      ),
      body: FutureBuilder(
        future: getLeaderBoard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('${context.tr('error')}: ${snapshot.error}');
          } else if (snapshot.hasData) {
            final leaderBoard = snapshot.data!;
            bool isMe = leaderBoard.any((element) => element.userId == user.firebaseUser?.uid);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: leaderBoard.length,
                      //   semanticChildCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        bool isFirstThree = index <= 2;

                        final item = leaderBoard[index];
                        return Column(
                          children: [
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              tileColor: Colors.grey.shade200,
                              title: Text(item.nickname),
                              trailing: _buildListTileTrailing(item.xp, isFirstThree),
                              leading: Text(
                                '${index + 1}.',
                              ),
                            ),
                            SizedBox(height: 8), // ListTile'lar arasına boşluk ekledik
                          ],
                        );
                      },
                    ),
                  ),
                  if (isMe)
                    _buildMe(leaderBoard.indexOf(leaderBoard.firstWhere((element) => element.userId == user.firebaseUser?.uid)), user, context),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMe(int index, AuthProvider user, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      width: double.infinity,
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${context.tr('your_rank')}: ${index + 1}.', style: const TextStyle(color: Colors.white)),
            FutureBuilder<int>(
                future: Provider.of<AchievementService>(context, listen: false).getUserXp(user.user!.userID!),
                builder: (context, snapshot) {
                  return _buildListTileTrailing(snapshot.data ?? 0, false);
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildListTileTrailing(int xp, bool isFirstThree) {
    return Container(
      width: 90,
      height: 30,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$xp XP',
            style: const TextStyle(color: Colors.white),
          ),
          if (isFirstThree) ...[
            const SizedBox(width: 4),
            Text(
              '🥇',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }
}
