import 'package:flutter/material.dart';
import 'package:ratix/shared/styled_button.dart';
import 'package:ratix/screens/category_card.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryName;
  const CategoryScreen({
    super.key,
    required this.categoryName,
  });
  
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

List items = ['mario', 'luigi', 'peach', 'toad', 'bowser', 'koopa'];

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, index) {
                  return CharacterCard(items[index]);
                }
              ),
            ),
            StyledButton(
              onPressed: () {},
             child:  const Text("Add item"),
                  )
          ],
        ),
      ),
    );
  }
}