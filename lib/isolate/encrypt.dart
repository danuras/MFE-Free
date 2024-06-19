import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:mfe_free/asset_code/global_variable.dart';
import 'package:mfe_free/asset_code/logic.dart';
import 'package:mfe_free/model/input_user.dart';
import 'package:mfe_free/provider/output_proses.dart';
import 'package:mfe_free/provider/provider_progress_file.dart';

late Isolate encryptIsolateInstance;

Future<SendPort> initIsolateEncrypt(ProgressApp progressApp,
    OutputProses outputProses, VoidCallback clear, VoidCallback onFail) async {
  Completer completer = Completer<SendPort>();
  ReceivePort isolateToMainStream = ReceivePort();

  isolateToMainStream.listen((data) {
    if (data is SendPort) {
      SendPort mainToIsolateStream = data;
      completer.complete(mainToIsolateStream);
    } else if (data is double) {
      progressApp.proses = data;
    } else if (data == "failed") {
      onFail();
      clear();
      isLoading = false;
      encryptIsolateInstance.kill();
      progressApp.proses = 0;
    } else if (data == 'selesai') {
      isLoading = false;
      clear();
      encryptIsolateInstance.kill();
      progressApp.proses = 1;
    } else if (data is String) {
      outputProses.tulisan = data;
    }
  });

  encryptIsolateInstance =
      await Isolate.spawn(encrypt, isolateToMainStream.sendPort);
  return completer.future as Future<SendPort>;
}

void encrypt(SendPort isolateToMainStream) async {
  late InputUser input;

  void _designerRumus() {
    int i = 0;

    for (i = 0; i < Pembatas.angka; i++) {
      proses![bantu] = Uint8List.fromList([40]);
      bantu++;
      proses![bantu] = Uint8List.fromList(utf8.encode(pecahan.x[i].toString()));
      bantu++;
      proses![bantu] = Uint8List.fromList([47]);
      bantu++;
      proses![bantu] = Uint8List.fromList(utf8.encode(pecahan.y[i].toString()));
      bantu++;
      proses![bantu] = Uint8List.fromList([41]);
      bantu++;

      if (i < Pembatas.angka - 1) {
        proses![bantu] = Uint8List.fromList([110]);
        bantu++;
        if (i < Pembatas.angka - 2) {
          proses![bantu] = Uint8List.fromList([94]);
          bantu++;
          proses![bantu] = Uint8List.fromList([50]);
          bantu++;
        }
      }
      proses![bantu] = Uint8List.fromList([43]);
      bantu++;
    }

    if (bantu == prosesLength) {
      bantu = 0;
      if (isFile) {
        writePartData(convertHasil(prosesLength));
      } else {
        total!.add(convertHasil(prosesLength));
      }
      proses = List.filled(prosesLength, Uint8List(1));
    }
  }

  Future<void> myEncrypt() async {
    int w, k, m = 0, p = 0, n, i = 0, j = 0, o = 0, z = 0, langkah = 0;
    double progress = 0;
    teksLength = input.plainText.length;

    fileName = input.fileName + '.mfe';
    isLoading = true;
    pecahan.x = [0, 0, 0];
    pecahan.y = [0, 0, 0];
    total = [];
    numberFile = 0;
    isFile = input.isFile;
    prosesLength = ((teksLength <= 600000) ? teksLength ~/ 3 * 22 : 4400000);
    proses = List.filled(prosesLength, Uint8List(1));
    Pembatas.T = input.plainText.length;
    Pembatas.angka = 3;
    Pembatas.t = Pembatas.T ~/ Pembatas.angka;
    langkah = (Pembatas.t / 100).truncate();
    passwordGenerator(input.passw);
    int y = input.passw.length;
    isNotFirst = false;
    data = [
      Data(Pembatas.angka + 1),
      Data(Pembatas.angka + 1),
      Data(Pembatas.angka + 1)
    ];
    data2 = [
      Data2(Pembatas.angka + 1),
      Data2(Pembatas.angka + 1),
      Data2(Pembatas.angka + 1)
    ];
    bantu = 0;
    await getExternalVisibleDir;
    o = 0;
    m = 0;
    try {
      do {
        p = i;
        for (w = 0; w < Pembatas.angka; w++) {
          for (j = 0; j < Pembatas.angka; j++) {
            data[w].w[j] = pangkat(input.passw[m], Pembatas.angka - j - 1);
          }
          data[w].w[j] = input.plainText[p];
          p++;
          m++;
        }
        if (m == y) m = 0;
        data2[0].z = List.from(data[0].w);
        for (w = Pembatas.angka - 1; w > 0; w--) {
          for (j = 0; j < w; j++) {
            z = data[j].w[w];
            n = data[j + 1].w[w];
            for (k = 0; k < Pembatas.angka + 1; k++) {
              data[j].w[k] = data[j + 1].w[k] * z - data[j].w[k] * n;
            }
          }
          data2[Pembatas.angka - w].z = List.from(data[0].w);
        }
        pecahan.x[0] = data2[Pembatas.angka - 1].z[Pembatas.angka];
        pecahan.y[0] = data2[Pembatas.angka - 1].z[0];

        penyederhanaPecahan(pecahan, 0);
        for (w = Pembatas.angka - 1; w > 0; w--) {
          n = Pembatas.angka - w - 1;
          pecahan.x[3 - w] = data2[w - 1].z[Pembatas.angka];
          pecahan.y[3 - w] = 1;
          for (j = w; j <= Pembatas.angka - 1; j++) {
            pecahan.x[3 - w] = pecahan.x[3 - w] * pecahan.y[n] -
                data2[w - 1].z[Pembatas.angka - j - 1] *
                    pecahan.x[n] *
                    pecahan.y[3 - w];
            pecahan.y[3 - w] *= pecahan.y[n];
            penyederhanaPecahan(pecahan, 3 - w);
            n--;
          }
          pecahan.y[3 - w] =
              data2[w - 1].z[Pembatas.angka - w] * pecahan.y[3 - w];
          penyederhanaPecahan(pecahan, 3 - w);
        }

        i += Pembatas.angka;
        o++;
        if (isFile && ((o % langkah) == 0)) {
          progress += 0.01;
          if (progress < 1) {
            isolateToMainStream.send(progress);
          }
        }
        _designerRumus();
      } while (o < Pembatas.t);

      if (bantu != 9) {
        if (isFile) {
          writePartData(convertHasil(bantu));
        } else {
          total!.add(convertHasil(bantu));
        }
        proses = List.filled(prosesLength, Uint8List(1));
      }

      (isFile)
          ? await writeData(await readData())
          : convertHasil2(total!.length);
      if (isFile) {
        isolateToMainStream.send(1);
      } else {
        isolateToMainStream.send(String.fromCharCodes(hasil!));
      }
      isolateToMainStream.send('selesai');
    } catch (e) {
      isolateToMainStream.send("failed");
    }

    pecahan.x = [];
    pecahan.y = [];
  }

  ReceivePort mainToIsolateStream = ReceivePort();
  isolateToMainStream.send(mainToIsolateStream.sendPort);
  mainToIsolateStream.listen((data) {
    if (data == 'action') {
      myEncrypt();
    } else if (data is InputUser) {
      input = data;
    }
  });
}
