import 'package:ratix/models/items.dart';

class Categories with Items{

  Categories({
    required this.name,
    required this.id,
  });
  
  final String id;
  final String name;
  bool _pinned=false;

  bool get isPinned => _pinned;

  void togglePinned() {
  _pinned = !_pinned;
  }

}