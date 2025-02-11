import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';

class FriendProfileView extends StatelessWidget {
  const FriendProfileView({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ListTile(
            title: Text('${customer.firstName!} (${customer.age.toString()})'),
            subtitle: Text(customer.email!),
            leading: CircleAvatar(
              child: Image.network(customer.profilePictureUrl!),
            ),
            trailing: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }
}
