import 'package:shared_preferences/shared_preferences.dart';

class Lang {
  static String current = 'ar';
  static Map<String, Map<String, String>> t = {
    'ar': {
      'live': 'مباشر',
      'movies': 'أفلام',
      'series': 'مسلسلات',
      'epg': 'الدليل',
      'fav': 'المفضلة',
      'settings': 'الإعدادات',
      'all': 'الكل',
      'categories': 'الباقات',
      'added': 'أضيف للمفضلة',
      'removed': 'حذف من المفضلة',
      'lang': 'اللغة',
      'player': 'المشغل',
    },
    'fr': {
      'live': 'DIRECT',
      'movies': 'FILMS',
      'series': 'SÉRIES',
      'epg': 'GUIDE',
      'fav': 'FAVORIS',
      'settings': 'PARAMÈTRES',
      'all': 'Tout',
      'categories': 'Catégories',
      'added': 'Ajouté aux favoris',
      'removed': 'Retiré',
      'lang': 'Langue',
      'player': 'Lecteur',
    },
    'cs': {
      'live': 'ŽIVĚ',
      'movies': 'FILMY',
      'series': 'SERIÁLY',
      'epg': 'PROGRAM',
      'fav': 'OBLÍBENÉ',
      'settings': 'NASTAVENÍ',
      'all': 'Vše',
      'categories': 'Kategorie',
      'added': 'Přidáno',
      'removed': 'Odebráno',
      'lang': 'Jazyk',
      'player': 'Přehrávač',
    },
  };

  static String get(String key) => t[current]![key]?? key;
  static Future load() async {
    final p = await SharedPreferences.getInstance();
    current = p.getString('lang')?? 'ar';
  }
  static Future set(String l) async {
    current = l;
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', l);
  }
}
