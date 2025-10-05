import 'package:flutter/material.dart';
import 'package:ratix/shared/styled_button.dart';
import 'package:ratix/shared/styled_text.dart';
import 'package:ratix/screens/category_card.dart';
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List characters = ['mario', 'luigi', 'peach', 'toad', 'bowser', 'koopa'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const StyledTitle('Your Categories'),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // list of characters
            Expanded(
              child: ListView.builder(
                itemCount: characters.length,
                itemBuilder: (_, index) {
                  return CharacterCard(characters[index]);
                }
              ),
            ),
            
            StyledButton(
              onPressed: () {
              },
              child: const StyledHeading('Create New'),
            ),
          ]
        ),
      ),
    );
  }
}