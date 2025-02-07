import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/widgets/advert/advert_card.dart';
import 'package:palseapp/features/home/viewmodel/home_view_model.dart';
import 'package:provider/provider.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeViewModel()..getAdverts(),
      child: Scaffold(
        body: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            return viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: viewModel.adverts.length,
                    itemBuilder: (context, index) {
                      final Advert advert = viewModel.adverts[index];
                      return AdvertCard(
                        advert: advert,
                        //    user: snapshot.data![index].customer,
                        ///TODO: User bilgilerini al
                      );
                    },
                  );
          },
        ),
      ),
    );
  }
}
