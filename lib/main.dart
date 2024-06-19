import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:mfe_free/asset_code/logic.dart';
import 'package:mfe_free/progress_file.dart';
import 'package:mfe_free/provider/provider_progress_file.dart';
import 'package:mfe_free/provider/teks_or_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'asset_code/global_variable.dart';
import 'asset_code/save_and_load/save.dart';
import 'asset_code/warna.dart';
import 'isolate/decrypt.dart';
import 'isolate/encrypt.dart';
import 'model/input_user.dart';
import 'provider/encypt_or_decrypt.dart';
import 'provider/is_loading.dart';
import 'provider/output_proses.dart';
import 'dart:isolate';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  SharedPreferences.getInstance().then((value) {
    Warna.idx = value.getInt("idx") ?? 1;
    runApp(ArithmethicEncrypt());
  });
}

class ArithmethicEncrypt extends StatefulWidget {
  @override
  State<ArithmethicEncrypt> createState() => _ArithmethicEncryptState();
}

class _ArithmethicEncryptState extends State<ArithmethicEncrypt> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  List<PlatformFile>? _paths;
  String? _directoryPath;
  String? _extension;
  bool _isClear = false;
  bool _userAborted = false;
  bool _multiPick = false;
  bool _isGranted = true;
  FileType _pickingType = FileType.any;
  late SendPort mainToIsolateStream, mainToIsolateStreamD;

  final TextEditingController _controller = TextEditingController(text: "");

  final TextEditingController _inputPassword = TextEditingController(text: "");
  InputUser inputUser = InputUser();

  List<String> _consumables = <String>[];
  bool _isAvailable = false;
  bool _loading = true;
  String? _queryProductError;

  final BannerAd myBanner = BannerAd(
    adUnitId: 'ca-app-pub-4958823695969643/2716562368',
    size: AdSize.banner,
    request: const AdRequest(),
    listener: const BannerAdListener(),
  );

  final BannerAdListener listener = BannerAdListener(
    // Called when an ad is successfully received.
    onAdLoaded: (Ad ad) => print('Ad loaded.'),
    // Called when an ad request failed.
    onAdFailedToLoad: (Ad ad, LoadAdError error) {
      // Dispose the ad here to free resources.
      ad.dispose();
      print('Ad failed to load: $error');
    },
    // Called when an ad opens an overlay that covers the screen.
    onAdOpened: (Ad ad) => print('Ad opened.'),
    // Called when an ad removes an overlay that covers the screen.
    onAdClosed: (Ad ad) => print('Ad closed.'),
    // Called when an impression occurs on the ad.
    onAdImpression: (Ad ad) => print('Ad impression.'),
  );

  void _selectFolder(bool isEncrypt) async {
    _resetState();
    try {
      String? path = await FilePicker.platform.getDirectoryPath();
      setState(() {
        _directoryPath = path;
        _userAborted = path == null;
      });
      if (_userAborted) {
        _logException('User Aborted');
      } else {
        File prosesFile = File(
            "/data/user/0/com.danuras.mfe_free/cache/HasilProses/" +
                fileName.substring(1, fileName.length - ((isEncrypt) ? 5 : 1)) +
                ((isEncrypt) ? '' : '.mfe'));
        await prosesFile.copy('$_directoryPath/' +
            fileName.substring(1, fileName.length - ((isEncrypt) ? 5 : 1)) +
            ((isEncrypt) ? '' : '.mfe'));
        //await writeData(logic.hasil!, _directoryPath! + '/' + _fileName!.substring(1, _fileName!.length - ((isEncrypt) ? 5 : 1)) + ((isEncrypt) ? '' : '.mfe'));
      }
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    }
  }

  Future<Uint8List> readData(fileNameWithPath) async {
    File f = File(fileNameWithPath);
    return f.readAsBytesSync();
  }

  void _pickFiles() async {
    _resetState();
    try {
      _directoryPath = null;
      _paths = (await FilePicker.platform.pickFiles(
        type: _pickingType,
        allowMultiple: _multiPick,
        onFileLoading: (FilePickerStatus status) => log(status.toString()),
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension?.replaceAll(' ', '').split(',')
            : null,
      ))
          ?.files;
      log(_paths!
          .map((e) => e.path)
          .toList()[0]
          .toString()); //==> untuk mengetahui path dan nama file yang di pick
      readingFile();
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    }
    if (!mounted) return;
    setState(() {
      fileName = _paths != null ? _paths!.map((e) => e.name).toString() : '';
      _controller.text = fileName;
      _userAborted = _paths == null;
    });
  }

  void _resetState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _paths = null;
      _userAborted = false;
    });
  }

  void _logException(String message) {
    log(message);
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void requestStoragePermission() async {
    if ((await Permission.storage.request().isGranted) &&
        (await Permission.manageExternalStorage.request().isGranted)) {
      setState(() {
        _isGranted = true;
      });
    }
  }

  void readingFile() async {
    List<int> bantu = [];
    inputUser.isFile = !isTeks;
    if (isEncrypt) {
      bantu.addAll(
          await readData(_paths!.map((e) => e.path).toList()[0].toString()));
      for (int i = 0; i < bantu.length % 3; i++) {
        bantu.add(0);
      }
      inputUser.plainText = Uint8List.fromList(bantu);
    } else {
      inputUser.plainText =
          await readData(_paths!.map((e) => e.path).toList()[0].toString());
    }
    bantu.clear();
    log("Read data complete");
  }

  void readingText() async {
    List<int> bantu = [];
    inputUser.isFile = !isTeks;
    if (isTeks) {
      if (isEncrypt) {
        bantu.addAll(Uint8List.fromList(utf8.encode(_controller.text)));
        for (int i = 0; i < bantu.length % 3; i++) {
          bantu.add(0);
        }
        inputUser.plainText = Uint8List.fromList(bantu);
      } else {
        inputUser.plainText = Uint8List.fromList(utf8.encode(_controller.text));
      }
      bantu.clear();
      log("Read data complete");
    }
  }

  @override
  void initState() {
    myBanner.load();

    requestStoragePermission();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProgressApp>(
          create: (context) => ProgressApp(),
        ),
        ChangeNotifierProvider<IsLoading>(
          create: (context) => IsLoading(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<EncryptOrDecrypt>(
                create: (context) => EncryptOrDecrypt(),
              ),
              ChangeNotifierProvider<OutputProses>(
                create: (context) => OutputProses(),
              ),
              ChangeNotifierProvider<TeksOrFile>(
                create: (context) => TeksOrFile(),
              ),
            ],
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(220),
                child: Builder(
                  builder: (context) => AppBar(
                    backgroundColor: Warna.bab[Warna.idx],
                    flexibleSpace: Column(
                      children: [
                        const SizedBox(
                          height: 5,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 205,
                              width: MediaQuery.of(context).size.width * 0.65,
                              child: Column(
                                children: [
                                  Consumer<ProgressApp>(
                                    builder: (context, progressApp, _) =>
                                        Consumer<TeksOrFile>(
                                      builder: (context, teksOrFile, _) =>
                                          TextFormField(
                                        readOnly: !teksOrFile.isTeks,
                                        style: TextStyle(
                                            color: Warna.fca[Warna.idx]),
                                        onTap: () async {
                                          if (!isLoading) {
                                            if (!teksOrFile.isTeks) {
                                              progressApp.proses = 0;
                                              _pickFiles();
                                            }
                                          }
                                        },
                                        decoration: InputDecoration(
                                          fillColor: Warna.bca[Warna.idx],
                                          filled: true,
                                          labelStyle: TextStyle(
                                              color: Warna.fca[Warna.idx]),
                                          hintText: (teksOrFile.isTeks)
                                              ? "Text Input"
                                              : "File Input",
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Warna.fca[Warna.idx],
                                              width: 1.0,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Warna.fca[Warna.idx],
                                              width: 1.0,
                                            ),
                                          ),
                                          hintStyle: TextStyle(
                                              color: Warna.fca[Warna.idx]),
                                        ),
                                        controller: _controller,
                                        maxLines: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  SizedBox(
                                    height: 46,
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: TextField(
                                      style: TextStyle(
                                          color: Warna.fca[Warna.idx]),
                                      decoration: InputDecoration(
                                        fillColor: Warna.bca[Warna.idx],
                                        filled: true,
                                        labelText: "Password",
                                        labelStyle: TextStyle(
                                            color: Warna.fca[Warna.idx]),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Warna.fca[Warna.idx],
                                            width: 1.0,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Warna.fca[Warna.idx],
                                            width: 1.0,
                                          ),
                                        ),
                                      ),
                                      controller: _inputPassword,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 205,
                              width: 110,
                              child: Consumer<TeksOrFile>(
                                builder: (context, teksOrFile, _) =>
                                    Consumer<EncryptOrDecrypt>(
                                  builder: (context, encryptOrDecrypt, _) =>
                                      Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Stack(
                                        children: [
                                          Center(
                                            child: Consumer<ProgressApp>(
                                              builder: (context, progress, _) =>
                                                  SizedBox(
                                                width: 100,
                                                child: ElevatedButton(
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        MaterialStateProperty
                                                            .all(
                                                      (teksOrFile.isTeks)
                                                          ? Warna
                                                              .sbca[Warna.idx]
                                                          : Warna
                                                              .sbcb[Warna.idx],
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    teksOrFile.isTeks =
                                                        !teksOrFile.isTeks;
                                                    if (!isLoading) {
                                                      isTeks =
                                                          teksOrFile.isTeks;
                                                      isFile = !isTeks;
                                                      _controller.text = '';
                                                    }
                                                  },
                                                  child: Column(
                                                    children: [
                                                      Icon(
                                                        (teksOrFile.isTeks)
                                                            ? Icons.text_fields
                                                            : Icons
                                                                .file_present_outlined,
                                                        size: 48,
                                                        color: (teksOrFile
                                                                .isTeks)
                                                            ? Warna
                                                                .fca[Warna.idx]
                                                            : const Color(
                                                                0xffcccccc),
                                                      ),
                                                      Text(
                                                        (teksOrFile.isTeks)
                                                            ? "Text"
                                                            : "File",
                                                        style: TextStyle(
                                                          color: (teksOrFile
                                                                  .isTeks)
                                                              ? Warna.fca[
                                                                  Warna.idx]
                                                              : const Color(
                                                                  0xffcccccc),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: const Alignment(0.75, 1),
                                            child: Icon(
                                              Icons
                                                  .replay_circle_filled_outlined,
                                              size: 20,
                                              color: (teksOrFile.isTeks)
                                                  ? Warna.fca[Warna.idx]
                                                  : const Color(0xffcccccc),
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Stack(
                                        children: [
                                          Center(
                                            child: SizedBox(
                                              width: 100,
                                              child: ElevatedButton(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      MaterialStateProperty.all(
                                                    (encryptOrDecrypt.isEncrypt)
                                                        ? Warna.sbca[Warna.idx]
                                                        : Warna.sbcb[Warna.idx],
                                                  ),
                                                ),
                                                onPressed: () {
                                                  encryptOrDecrypt.isEncrypt =
                                                      !encryptOrDecrypt
                                                          .isEncrypt;
                                                  if (!isLoading) {
                                                    isEncrypt = encryptOrDecrypt
                                                        .isEncrypt;
                                                  }
                                                },
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      (encryptOrDecrypt
                                                              .isEncrypt)
                                                          ? Icons.lock_outline
                                                          : Icons.lock_open,
                                                      size: 48,
                                                      color: (encryptOrDecrypt
                                                              .isEncrypt)
                                                          ? Warna.fca[Warna.idx]
                                                          : const Color(
                                                              0xffcccccc),
                                                    ),
                                                    Text(
                                                      (encryptOrDecrypt
                                                              .isEncrypt)
                                                          ? "Encryption"
                                                          : "Description",
                                                      style: TextStyle(
                                                        color: (encryptOrDecrypt
                                                                .isEncrypt)
                                                            ? Warna
                                                                .fca[Warna.idx]
                                                            : const Color(
                                                                0xffcccccc),
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: const Alignment(0.75, 1),
                                            child: Icon(
                                              Icons
                                                  .replay_circle_filled_outlined,
                                              size: 20,
                                              color:
                                                  (encryptOrDecrypt.isEncrypt)
                                                      ? Warna.fca[Warna.idx]
                                                      : const Color(0xffcccccc),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 11,
                                      ),
                                      SizedBox(
                                        height: 50,
                                        width: 100,
                                        child: Consumer<OutputProses>(
                                          builder: (context, outputProses, _) =>
                                              Consumer<ProgressApp>(
                                            builder: (context, progress, _) =>
                                                Consumer<IsLoading>(
                                              builder: (context, isWait, _) =>
                                                  ElevatedButton(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      MaterialStateProperty.all(
                                                    Warna.sbcb[Warna.idx],
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  if (!isLoading) {
                                                    isWait.isLoading = true;
                                                    isLoading = true;
                                                    readingText();
                                                    List<int> bantu = [];

                                                    progress.proses = 0;
                                                    bantu.addAll(
                                                        Uint8List.fromList(
                                                            utf8.encode(
                                                                _inputPassword
                                                                    .text)));
                                                    for (int i = 0;
                                                        i < bantu.length % 3;
                                                        i++) {
                                                      bantu.add(0);
                                                    }
                                                    inputUser.passw =
                                                        Uint8List.fromList(
                                                            bantu);
                                                    bantu.clear();
                                                    try {
                                                      if (isEncrypt) {
                                                        inputUser.fileName = (isTeks)
                                                            ? ''
                                                            : fileName.substring(
                                                                1,
                                                                fileName.length -
                                                                    1);
                                                        mainToIsolateStream =
                                                            await initIsolateEncrypt(
                                                                progress,
                                                                outputProses,
                                                                () {
                                                          isTeks =
                                                              teksOrFile.isTeks;
                                                          isEncrypt =
                                                              encryptOrDecrypt
                                                                  .isEncrypt;
                                                          isWait.isLoading =
                                                              false;
                                                        }, () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return AlertDialog(
                                                                title: const Text(
                                                                    "Attention"),
                                                                content: Text(((isEncrypt)
                                                                        ? "Encryption"
                                                                        : "Description") +
                                                                    ' failed'),
                                                                actions: [
                                                                  ElevatedButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                            "OK"),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        });
                                                        mainToIsolateStream
                                                            .send(inputUser);

                                                        mainToIsolateStream
                                                            .send('action');
                                                      } else {
                                                        inputUser.fileName = (isTeks)
                                                            ? ''
                                                            : fileName.substring(
                                                                1,
                                                                fileName.length -
                                                                    5);
                                                        mainToIsolateStream =
                                                            await initIsolateDecrypt(
                                                                progress,
                                                                outputProses,
                                                                () {
                                                          isTeks =
                                                              teksOrFile.isTeks;
                                                          isEncrypt =
                                                              encryptOrDecrypt
                                                                  .isEncrypt;
                                                          isWait.isLoading =
                                                              false;
                                                        }, () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return AlertDialog(
                                                                title: const Text(
                                                                    "Attention"),
                                                                content: Text(((isEncrypt)
                                                                        ? "Encryption"
                                                                        : "Description") +
                                                                    ' failed'),
                                                                actions: [
                                                                  ElevatedButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                            "OK"),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        });
                                                        mainToIsolateStream
                                                            .send(inputUser);

                                                        mainToIsolateStream
                                                            .send('action');
                                                      }
                                                    } catch (e) {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          return AlertDialog(
                                                            title: const Text(
                                                                "Attention"),
                                                            content: Text(((isEncrypt)
                                                                    ? "Encryption"
                                                                    : "Description") +
                                                                ' failed'),
                                                            actions: [
                                                              ElevatedButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child:
                                                                    const Text(
                                                                        "OK"),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    }
                                                  }
                                                },
                                                child: const Text(
                                                  "OK",
                                                  style: TextStyle(
                                                    color: Color(0xffcccccc),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              body: Material(
                color: Warna.bbc[Warna.idx],
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Warna.bca[Warna.idx],
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Warna.sbca[Warna.idx],
                          border: Border.all(color: Warna.fca[Warna.idx]),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Consumer<EncryptOrDecrypt>(
                          builder: (context, encryptOrDecrypt, _) =>
                              Consumer<TeksOrFile>(
                            builder: (context, teksOrFile, _) => Row(
                              children: [
                                Text(
                                  (encryptOrDecrypt.isEncrypt)
                                      ? "    Encryption Results"
                                      : "    Description Results",
                                  style: TextStyle(
                                    color: Warna.fca[Warna.idx],
                                    fontSize: 16,
                                  ),
                                ),
                                const Expanded(
                                  flex: 1,
                                  child: SizedBox(),
                                ),
                                IconButton(
                                  icon: Icon(
                                    (Warna.idx == 0)
                                        ? Icons.light_mode
                                        : Icons.dark_mode,
                                    color: Warna.fca[Warna.idx],
                                  ),
                                  onPressed: () {
                                    Warna.idx = 1 - Warna.idx;
                                    Save.saveDataTema();
                                    setState(() {});
                                  },
                                ),
                                Consumer<OutputProses>(
                                  builder: (context, outputProses, _) =>
                                      Consumer<ProgressApp>(
                                    builder: (context, progressApp, _) =>
                                        IconButton(
                                      icon: Icon(
                                        (teksOrFile.isTeks)
                                            ? Icons.content_copy
                                            : Icons.save,
                                        color: Warna.fca[Warna.idx],
                                      ),
                                      onPressed: () {
                                        if ((outputProses.tulisan != '' &&
                                                progressApp.proses != 0) ||
                                            teksOrFile.isTeks) {
                                          if (teksOrFile.isTeks) {
                                            Clipboard.setData(
                                              ClipboardData(
                                                  text: outputProses.tulisan),
                                            );
                                          } else {
                                            if (_isGranted) {
                                              _selectFolder(
                                                  !encryptOrDecrypt.isEncrypt);
                                            } else {
                                              requestStoragePermission();
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Warna.sbca[Warna.idx],
                            border: Border.all(color: Warna.fca[Warna.idx]),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: ListView(
                            children: [
                              Consumer<OutputProses>(
                                builder: (context, outputProses, _) =>
                                    Container(
                                  margin: const EdgeInsets.all(5),
                                  child: Consumer<EncryptOrDecrypt>(
                                    builder: (context, encryptOrDecrypt, _) =>
                                        Consumer<TeksOrFile>(
                                      builder: (context, teksOrFile, _) =>
                                          (teksOrFile.isTeks)
                                              ? SelectableText(
                                                  outputProses.tulisan,
                                                  style: TextStyle(
                                                    color: Warna.fca[Warna.idx],
                                                  ),
                                                )
                                              : (_controller.text != '')
                                                  ? ProgressFile(
                                                      _controller.text, () {
                                                      if (_isGranted) {
                                                        _selectFolder(
                                                            !encryptOrDecrypt
                                                                .isEncrypt);
                                                      } else {
                                                        requestStoragePermission();
                                                      }
                                                    })
                                                  : const Text(""),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.center,
                        child: AdWidget(ad: myBanner),
                        width: myBanner.size.width.toDouble(),
                        height: myBanner.size.height.toDouble(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
