import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 100,
          ),
          Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  'S.S.S',
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Theme(
                  data: ThemeData(
                    dividerColor: Colors.transparent,
                    unselectedWidgetColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Uygulamanın amacı ne?',
                    ),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                        child: Text(
                          'Uygulamanın amacı, aynı şehirlerde ya da farklı şehirlerde bulunan, aynı ilgi alanlarına sahip insanların etkileşim kurarak sosyalleşebilmesi ve eğlenebilmesi için ortam sağlamaktır.',
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),
                Theme(
                  data: ThemeData(
                    dividerColor: Colors.transparent,
                    unselectedWidgetColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Uygulama ücretsiz mi?',
                    ),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                        child: Text(
                          'Evet, uygulama ücretsizdir. Uygulamanın her özelliğinden ücretsiz olarak faydalanabilirsiniz.',
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),
                Theme(
                  data: ThemeData(
                    dividerColor: Colors.transparent,
                    unselectedWidgetColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Uygulamayı nasıl kullanırım?',
                    ),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                        child: Text(
                          'Uygulama, ilgi duyduğunuz kategorilerdeki ilanları "şehrinize göre" veya "ilginize göre" şeklinde ayırarak size sunar. Ayrıca "detaylı arama" butonuyla daha kapsamlı ilan araması yapabilirsiniz.',
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),
                Theme(
                  data: ThemeData(
                    dividerColor: Colors.transparent,
                    unselectedWidgetColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'İlan hakkım biterse ücretsiz ilan hakkı nasıl kazanırım?',
                    ),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                        child: Text(
                          'İlan hakkınız biterse, daha önceki ilanlarda yaptığınız buluşmalara ilişkin fotoğrafları bize göndererek (sosyal medya hesaplarımızda yayınlayacağız) veya reklam izleyerek ücretsiz ilan hakkı kazanabilirsiniz.',
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),
                Theme(
                  data: ThemeData(
                    dividerColor: Colors.transparent,
                    unselectedWidgetColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Profilimi doğrulamanın avantajı ne?',
                    ),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                        child: Text(
                          'Profilinize cep telefonunuzu girerek doğrulamanız halinde, profilinizin yanında onay işareti bulunur. Bu işaret diğer kullanıcılara güvenilirlik mesajı verir, yayınladığınız ilanlara katılımı artırır. Ayrıca başka birinin ilanı için ilan sahibine mesaj attığınızda, ilan sahibine güven verir.',
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),
                Theme(
                  data: ThemeData(
                    dividerColor: Colors.transparent,
                    unselectedWidgetColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Uygulama güvenilir mi?',
                    ),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                        child: Text(
                          'Evet, uygulamamız son derece güvenilirdir. Diğer uygulamalarda olduğu gibi sizden cep telefonu gibi fazla kişisel bilgiler talep edilmez. Ancak isterseniz cep telefonu bilgisi girebilirsiniz. Cep telefonu bilginizi girdiğinizde, profil simgenizin yanında onay işareti olur. Bu da ilanlarınıza veya ilanlara yaptığınız katılımlara geri dönüş sayısını artırır.',
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),
                Theme(
                  data: ThemeData(
                    dividerColor: Colors.transparent,
                    unselectedWidgetColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Premium’da ne gibi avantajlar var?',
                    ),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                        child: Text(
                          'Premium üye olduğunuzda, reklamlara maruz kalmazsınız. Ayrıca sınırsız ilan hakkınız olur. Yayınladığınız ilanlara hangi üyelerimizin baktığını görebilir ve bu kişilere doğrudan mesaj gönderebilirsiniz.',
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
