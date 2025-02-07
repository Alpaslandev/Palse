import 'package:flutter/material.dart';

class DetailAppbar extends StatelessWidget implements PreferredSizeWidget {
  const DetailAppbar({
    super.key,
    required this.onBlock,
    required this.onFilter,
    required this.onReport,
  });
  final VoidCallback onBlock;
  final VoidCallback onFilter;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('İlan Detayı'),
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        PopupMenuButton(
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: 'block',
              child: ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Kullanıcıyı Engelle'),
              ),
            ),
            PopupMenuItem(
              value: 'filter',
              child: ListTile(
                leading: const Icon(Icons.filter_list, color: Colors.red),
                title: const Text('İçerik Filtrele'),
              ),
            ),
            PopupMenuItem(
              value: 'report',
              child: ListTile(
                leading: const Icon(Icons.report, color: Colors.red),
                title: const Text('Kötüye Kullanım Bildir'),
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'block':
                _showBlockDialog(context);
                break;
              case 'filter':
                _showFilterDialog(context);
                break;
              case 'report':
                _showReportDialog(context);
                break;
            }
          },
        ),
      ],
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Engellemek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onBlock();
            },
            child: const Text('Engelle'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('İçerik Filtreleme'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onFilter();
            },
            child: const Text('Filtrele'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Kötüye Kullanım Bildir'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onReport();
            },
            child: const Text('Bildir'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
