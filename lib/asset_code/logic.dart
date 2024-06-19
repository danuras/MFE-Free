import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'dart:typed_data';

import 'package:mfe_free/asset_code/global_variable.dart';

//class Logic {
List<Uint8List>? proses, total;
Uint8List? hasil;
final Pecahan pecahan = Pecahan();
List<Data> data = [];
List<Data2> data2 = [];
bool isNotFirst = true, isFile = false;
bool isLoading = false;
int bantu = 0, teksLength = 0, prosesLength = 0, numberFile = 0;

Future<Directory> get getExternalVisibleDir async {
  if (await Directory('/data/user/0/com.danuras.mfe_free/cache/HasilProses')
      .exists()) {
    final externalDir =
        Directory('/data/user/0/com.danuras.mfe_free/cache/HasilProses');
    return externalDir;
  } else {
    await Directory('/data/user/0/com.danuras.mfe_free/cache/HasilProses')
        .create(recursive: true);
    final externalDir =
        Directory('/data/user/0/com.danuras.mfe_free/cache/HasilProses');
    return externalDir;
  }
}

void passwordGenerator(Uint8List password) {
  int i = password.length, j = 0, k = 0;

  bantu = 0;

  for (j = 0; j < i; j++) {
    for (k = 0; k < i; k++) {
      if (k != j) {
        if (password[j] == password[k]) {
          password[j]++;
          k = 0;
          j = 0;
        }
      }
    }
  }
}

void clearTheJunk() {
  data = [];
  data2 = [];
  proses = [];
  hasil = null;
}

int pangkat(int a, int b) {
  int c = 1;
  for (int i = 1; i <= b; i++) {
    c = c * a;
  }
  return c;
}

void penyederhanaPecahan(Pecahan pech, int l) {
  bool c = true, d = true;
  int v = 0;
  if (pech.x[l] < 0) {
    pech.x[l] *= -1;
    c = false;
  } else if (pech.x[l] == 0) {
    pech.y[l] = 1;
  }
  if (pech.y[l] < 0) {
    pech.y[l] *= -1;
    d = false;
  }
  if (pech.x[l] <= pech.y[l]) {
    v = pech.x[l];
  } else if (pech.y[l] < pech.x[l]) {
    v = pech.y[l];
  }
  while ((pech.x[l] % 2 == 0) && (pech.y[l] % 2 == 0)) {
    pech.x[l] ~/= 2;
    pech.y[l] ~/= 2;
    if (pech.x[l] <= pech.y[l]) {
      v = pech.x[l];
    } else if (pech.y[l] < pech.x[l]) {
      v = pech.y[l];
    }
  }
  for (int z = 3; z <= v; z += 2) {
    if ((pech.x[l] % z == 0) && (pech.y[l] % z == 0)) {
      pech.x[l] ~/= z;
      pech.y[l] ~/= z;
      if (pech.x[l] <= pech.y[l]) {
        v = pech.x[l];
      } else if (pech.y[l] < pech.x[l]) {
        v = pech.y[l];
      }
    }
    if ((pech.x[l] % z == 0) && (pech.y[l] % z == 0)) {
      z -= 2;
    }
  }
  if (c == false) pech.x[l] *= -1;
  if (d == false) pech.y[l] *= -1;
  if (!d && !c) {
    pech.x[l] *= -1;
    pech.y[l] *= -1;
  }
}

/* 
  void encrypt_2() {
    List<int> t = utf8.encode(teks);
    List<Uint8List> enk = [];
    int j = teks.length;
    for (int i = 0; i < j; i++) {
      enk.add(Uint8List(1));
      enk[i] = Uint8List.fromList(utf8.encode((t[i] + 10).toString()));
    }
    log(enk.toString());
  } */

Uint8List convertHasil(int length) {
  int i = 0, j = 0, k = 0, s = 0, x = 0;
  Uint8List numpang;
  for (i = 0; i < length; i++) {
    s += proses![i].length;
  }
  numpang = Uint8List(s);
  for (i = 0; i < length; i++) {
    k = proses![i].length;
    for (j = 0; j < k; j++) {
      numpang[x] = proses![i][j];
      x++;
    }
  }
  return numpang;
}

void convertHasil2(int length) {
  int i = 0, j = 0, k = 0, s = 0, x = 0;
  for (i = 0; i < length; i++) {
    s += total![i].length;
  }
  hasil = Uint8List(s);
  for (i = 0; i < length; i++) {
    k = total![i].length;
    for (j = 0; j < k; j++) {
      hasil![x] = total![i][j];
      x++;
    }
  }
}

Future<void> writePartData(dataToWrite) async {
  File f = File('/data/user/0/com.danuras.mfe_free/cache/HasilProses/' +
      fileName +
      '.part' +
      numberFile.toString());
  numberFile++;
  f.writeAsBytes(dataToWrite);
}

Future<Uint8List> readData() async {
  List<Uint8List> numpang = [];
  int s = 0, k = 0, x = 0;
  Uint8List? output;
  log(fileName.toString());
  for (int i = 0; i < numberFile; i++) {
    File f = File('/data/user/0/com.danuras.mfe_free/cache/HasilProses/' +
        fileName +
        '.part' +
        i.toString());
    numpang.add(await f.readAsBytes());
    await f.delete();
  }
  log("test3");
  for (int i = 0; i < numberFile; i++) {
    s += numpang[i].length;
  }
  output = Uint8List(s);
  log("test1");
  for (int i = 0; i < numberFile; i++) {
    k = numpang[i].length;
    for (int j = 0; j < k; j++) {
      output[x] = numpang[i][j];
      x++;
    }
  }

  return output;
}

Future<void> writeData(dataToWrite) async {
  File f =
      File('/data/user/0/com.danuras.mfe_free/cache/HasilProses/' + fileName);
  await f.writeAsBytes(dataToWrite);
}

//}

class Pembatas {
  static int t = 0, T = 0, angka = 0;
}

class Pecahan {
  List<int> x = [];
  List<int> y = [];
}

class Data {
  Data(int jml) {
    w = List<int>.filled(jml, 0);
  }
  late List<int> w;
}

class Data2 {
  Data2(int jml) {
    z = List<int>.filled(jml, 0);
  }
  late List<int> z;
}
