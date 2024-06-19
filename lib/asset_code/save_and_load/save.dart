import 'package:mfe_free/asset_code/warna.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Save {
  static void saveDataTema() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setInt("idx", Warna.idx);
  }
}
