import 'dart:async';
import 'dart:developer';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mfe_free/asset_code/global_variable.dart';
import 'package:mfe_free/asset_code/logic.dart';
import 'package:mfe_free/model/input_user.dart';
import 'package:mfe_free/provider/output_proses.dart';
import 'package:mfe_free/provider/provider_progress_file.dart';

late Isolate decryptIsolateInstance;

Future<SendPort> initIsolateDecrypt(ProgressApp progressApp,
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
      log("test fail");
      clear();
      onFail();
      isLoading = false;
      decryptIsolateInstance.kill();
      progressApp.proses = 0;
    } else if (data == 'selesai') {
      isLoading = false;
      clear();
      decryptIsolateInstance.kill();
      progressApp.proses = 1;
    } else if (data is String) {
      outputProses.tulisan = data;
    }
  });

  decryptIsolateInstance =
      await Isolate.spawn(descript, isolateToMainStream.sendPort);
  return completer.future as Future<SendPort>;
}

void descript(SendPort isolateToMainStream) async {
  late InputUser input;
  Future<void> myDecrypt() async {
    Pecahan v = Pecahan();
    int i = 0,
        j = 0,
        o = 0,
        k = 0,
        m = 0,
        w,
        y,
        z = 0,
        pem = 0,
        pen = 0,
        langkah = 0;
    double progress = 0;
    teksLength = input.plainText.length;
    pecahan.x = [0, 0, 0];
    proses = [];
    pecahan.y = [0, 0, 0];
    total = [];
    isLoading = true;
    isFile = input.isFile;
    fileName = input.fileName;
    Pembatas.T = 0;
    Pembatas.t = 0;
    Pembatas.angka = 3;
    numberFile = 0;
    for (i = 1; i < teksLength; i++) {
      if (input.plainText[i] == 94) {
        Pembatas.T += 3;
      }
    }
    passwordGenerator(input.passw);
    prosesLength = ((Pembatas.T <= 600000) ? Pembatas.T : 600000);
    proses = List<Uint8List>.filled(prosesLength, Uint8List.fromList([0]));
    Pembatas.t = Pembatas.T ~/ Pembatas.angka;
    langkah = (Pembatas.t / 100).truncate();
    i = 0;
    bantu = 0;
    w = input.passw.length;
    await getExternalVisibleDir;

    k = 0;
    m = 0;
    v.x.add(0);
    v.y.add(1);
    z = 0;
    try {
      do {
        i = 0;
        while (i < 3) {
          if (input.plainText[z] == 40) {
            z++;
            pem = z;
            while (input.plainText[z] != 47) {
              z++;
            }
            z++;
            pen = z;
            while (input.plainText[z] != 41) {
              z++;
            }
            pecahan.x[i] = int.parse(
                String.fromCharCodes(input.plainText.getRange(pem, pen - 1)));
            pecahan.y[i] = int.parse(
                String.fromCharCodes(input.plainText.getRange(pen, z)));
            i++;
          }
          z++;
        }
        for (i = 1; i <= Pembatas.angka; i++) {
          y = Pembatas.angka - 1;
          v.x[0] = 0;
          v.y[0] = 1;
          for (j = 0; j < Pembatas.angka; j++) {
            v.x[0] = pecahan.x[j] * pangkat(input.passw[m], y) * v.y[0] +
                v.x[0] * pecahan.y[j];
            v.y[0] = pecahan.y[j] * v.y[0];
            penyederhanaPecahan(v, 0);
            y--;
          }
          m++;
          if (m == 6) {
            log(v.x[0].toString() + '/' + v.y[0].toString());
          }
          if (k <= Pembatas.T) {
            proses![bantu] = Uint8List.fromList((v.x[0] ~/ v.y[0] >= 0)
                ? [v.x[0] ~/ v.y[0]]
                : [(v.x[0] ~/ v.y[0]) * -1]);
            bantu++;

            k++;
          }
        }
        if (bantu == prosesLength) {
          bantu = 0;
          if (isFile) {
            writePartData(convertHasil(prosesLength));
            proses =
                List<Uint8List>.filled(prosesLength, Uint8List.fromList([0]));
          } else {
            total!.add(convertHasil(prosesLength));
            proses =
                List<Uint8List>.filled(prosesLength, Uint8List.fromList([0]));
          }
        }
        if (m == w) m = 0;
        o++;
        if (isFile && (o % langkah == 0)) {
          progress += 0.01;
          if (progress < 1) {
            isolateToMainStream.send(progress);
          }
        }
      } while (o < Pembatas.t);

      if (bantu != 0) {
        if (isFile) {
          writePartData(convertHasil(bantu));
          proses =
              List<Uint8List>.filled(prosesLength, Uint8List.fromList([0]));
        } else {
          total!.add(convertHasil(bantu));
          proses =
              List<Uint8List>.filled(prosesLength, Uint8List.fromList([0]));
        }
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
      log("test fail");
      isolateToMainStream.send('failed');
    }
    pecahan.x = [];
    pecahan.y = [];
  }

  ReceivePort mainToIsolateStream = ReceivePort();
  isolateToMainStream.send(mainToIsolateStream.sendPort);
  mainToIsolateStream.listen((data) {
    if (data == 'action') {
      myDecrypt();
    } else if (data is InputUser) {
      input = data;
    }
  });
}
