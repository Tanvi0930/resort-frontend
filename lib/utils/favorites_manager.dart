import 'package:shared_preferences/shared_preferences.dart';

class FavoritesManager {
  static const String _key = 'favorited_resort_names';

  // Get list of favorited resort names
  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  // Toggle favorite status
  static Future<bool> toggleFavorite(String resortName) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    bool isFavorited;
    
    if (current.contains(resortName)) {
      current.remove(resortName);
      isFavorited = false;
    } else {
      current.add(resortName);
      isFavorited = true;
    }
    
    await prefs.setStringList(_key, current);
    return isFavorited;
  }

  // Check if a resort is favorited
  static Future<bool> isFavorited(String resortName) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    return current.contains(resortName);
  }
}
