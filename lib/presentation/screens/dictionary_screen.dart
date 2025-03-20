import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/kanji_search_bar.dart';
import '../widgets/dictionary_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dictionary'),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: KanjiSearchBar(
                controller: TextEditingController(),
                onSearch: () {
                  // Handle search action
                },
              ),
            ),
            
            // Example cards
            Expanded(
              child: ListView(
                children: const [
                  DictionaryCard(
                    word: 'quedarse',
                    partOfSpeech: 'verb',
                    translation: 'to stay',
                    example: 'Nuestros primos se quedaron con nosotros durante la Navidad.',
                  ),
                  DictionaryCard(
                    word: 'la manzana',
                    partOfSpeech: 'noun',
                    translation: 'apple',
                    example: 'La reina malvada le dio una manzana envenenada a Blancanieves.',
                  ),
                  DictionaryCard(
                    word: 'el centro',
                    partOfSpeech: 'noun',
                    translation: 'center',
                    example: 'En el centro del mantel hay una estrella.',
                  ),
                  DictionaryCard(
                    word: 'la ruta',
                    partOfSpeech: 'noun',
                    translation: 'route',
                    example: 'La ruta más rápida al aeropuerto está cerrada por obras.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
