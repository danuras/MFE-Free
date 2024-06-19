import 'dart:developer';
import 'dart:isolate';

import 'package:mfe_free/isolate/decrypt.dart';
import 'package:mfe_free/isolate/encrypt.dart';
import 'package:mfe_free/provider/is_loading.dart';
import 'package:mfe_free/provider/provider_progress_file.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

import 'asset_code/global_variable.dart';
import 'asset_code/logic.dart';
import 'asset_code/warna.dart';

class ProgressFile extends StatefulWidget {
  ProgressFile(this.title, this.saveFile);
  final String title;
  final VoidCallback saveFile;

  @override
  State<ProgressFile> createState() => _ProgressFileState(title, saveFile);
}

class _ProgressFileState extends State<ProgressFile> with TickerProviderStateMixin {
  _ProgressFileState(this.title, this.saveFile);
  final String title;
  final VoidCallback saveFile;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
          decoration: BoxDecoration(
            color: Warna.blc[Warna.idx],
            borderRadius: const BorderRadius.all(
              Radius.circular(5),
            ),
          ),
          padding: const EdgeInsets.all(5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Consumer<ProgressApp>(
                builder: (context, progressApp, _) => CircularPercentIndicator(
                  radius: 90,
                  lineWidth: 10,
                  percent: progressApp.proses,
                  center: Text(
                    (progressApp.proses * 100).toStringAsFixed(0) + "%",
                    style: const TextStyle(
                      color: Color(0xffcccccc),
                      fontSize: 40,
                    ),
                  ),
                  progressColor: const Color(0xffcccccc),
                  backgroundColor: const Color(0xff0e2010),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xffcccccc),
                  fontSize: 18,
                ),
              ),
              Container(
                width: double.infinity,
                height: 1.5,
                color: const Color(0xffcccccc),
              ),
              Consumer<ProgressApp>(
                builder: (context, progressApp, _) => Consumer<IsLoading>(
                  builder: (context, isWait, _) => Center(
                    child: (isWait.isLoading || progressApp.proses == 1)
                        ? ElevatedButton(
                            onPressed: () {
                              if (progressApp.proses == 1) {
                                saveFile();
                              } else {
                                if (isEncrypt) {
                                  encryptIsolateInstance.kill(priority: Isolate.immediate);
                                } else {
                                  decryptIsolateInstance.kill(priority: Isolate.immediate);
                                }
                                progressApp.proses = 0;
                                isLoading = false;
                              }
                            },
                            child: Text(
                              (progressApp.proses != 1) ? "Cancel" : "Save",
                              style: const TextStyle(
                                color: Color(0xffcccccc),
                              ),
                            ),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                Warna.sbcb[Warna.idx],
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ),
              ),
            ],
          )),
    );
  }
}
