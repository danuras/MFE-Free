import 'package:shared_preferences/shared_preferences.dart';

class Load {
  static Future<int> getTheme() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getInt("idx") ?? 0;
  }
}
