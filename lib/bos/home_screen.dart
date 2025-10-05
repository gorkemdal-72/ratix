/*import 'package:flutter/material.dart';
import 'package:ratix/shared/styled_button.dart';
import 'package:ratix/screens/category_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Kategoriler state içinde
  final List<String> categories = [];
  final TextEditingController _categoryController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome username"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Categories list" , style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),

            // Kategori listesi
            Expanded(
              child: categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz kategori yok',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Yeni kategori eklemek için yukarıdaki butona tıklayın',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                  : ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (_, i) => Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              categories[i][0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            categories[i],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text( "item sayısı yazacak"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _openCategory(categories[i]),
                        ),
                      )
                    ),
            ),
            // Kategori ekleme
            Align(
              alignment: Alignment.bottomRight,
             child: StyledButton(
              onPressed: _showAddCategoryDialog,
              child: const Text('Add Category'),
            ),
            ),
            
          ],
        ),
      ),
    );
  }

  // Kategori ekleme dialog'u
  void _showAddCategoryDialog() {
    _categoryController.clear();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kategori Ekle'),
          content: TextField(
            controller: _categoryController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Kategori adı',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            onSubmitted: (value) => _addCategory(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: _addCategory,
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  // Kategori ekleme
  void _addCategory() {
    final categoryName = _categoryController.text.trim();
    
    if (categoryName.isEmpty) {
      _showMessage('Kategori adı boş olamaz');
      return;
    }
    
    // Aynı kategori var mı kontrolü
    final exists = categories.any((c) => c.toLowerCase() == categoryName.toLowerCase());
    if (exists) {
      _showMessage('Bu kategori zaten var: $categoryName');
      return;
    }
    
    // Kategoriyi ekle
    setState(() {
      categories.add(categoryName);
    });
    
    // Dialog'u kapat
    Navigator.of(context).pop();
    
    // Başarı mesajı göster
    _showMessage('Kategori eklendi: $categoryName');
  }

  // Mesaj gösterme
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Kategori ekranına geçiş
  void _openCategory(String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryScreen(categoryName: name),
      ),
    );
  }
}*/
