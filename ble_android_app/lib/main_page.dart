import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum BLEState { idle, connecting, connected, found, scanning }

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  BLEState currentState = BLEState.idle;
  String stateString = '';
  BluetoothCharacteristic? bleCharacteristic;

  BluetoothDevice? device;
  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      if (await FlutterBluePlus.isSupported) {
        FlutterBluePlus.onScanResults.listen((event) {
          for (int i = 0; i < event.length; i++) {
            log("Scan Result: ${event[i].advertisementData.advName}");
            log("Device is ${event[i].device}");
            if (event[i].advertisementData.advName == "Keychain Yusuf") {
              setState(() {
                device = event[i].device;
                currentState = BLEState.found;
              });
              FlutterBluePlus.stopScan();
            }
          }
        }, onError: (error) {
          log("Error ${error}");
        });

        FlutterBluePlus.adapterState.listen((event) {
          log("State is ${event}");
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            MaterialButton(
              onPressed: () async {
                setState(() {
                  currentState = BLEState.scanning;
                });
                FlutterBluePlus.startScan(
                  timeout: Duration(seconds: 5),
                );
                await Future.delayed(Duration(seconds: 5));
                log("SCAN STOP");
                if (currentState == BLEState.found) {
                  if (device != null) {
                    log("Try to connect");
                    device!.connectionState.listen((event) async {
                      log("DEVICE EVENT ${event}");
                      if (event == BluetoothConnectionState.connected) {
                        setState(() {
                          currentState = BLEState.connected;
                        });
                      }
                    });
                    setState(() {
                      currentState = BLEState.connecting;
                    });
                    await device!.connect();
                    device!.discoverServices().then((value) {
                      for (var i = 0; i < value.length; i++) {
                        for (var j = 0;
                            j < value[i].characteristics.length;
                            j++) {
                          if (value[i].characteristics[j].uuid.str ==
                              'beb5483e-36e1-4688-b7f5-ea07361b26a8') {
                            setState(() {
                              bleCharacteristic = value[i].characteristics[j];
                            });
                          }
                        }
                      }
                    });
                  }
                }
              },
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
                child: Center(child: Text(_getStateString(currentState))),
              ),
            ),
            (bleCharacteristic == null)
                ? Container()
                : Column(
                    children: [
                      MaterialButton(
                        onPressed: () {
                          String commandString = "on";
                          List<int> byteArrayCommand =
                              utf8.encode(commandString);
                          bleCharacteristic!.write(byteArrayCommand);
                        },
                        child: Text("PING"),
                        color: Colors.red,
                      ),
                      MaterialButton(
                        onPressed: () {
                          String commandString = "off";
                          List<int> byteArrayCommand =
                              utf8.encode(commandString);
                          bleCharacteristic!.write(byteArrayCommand);
                        },
                        child: Text("STOP"),
                        color: Colors.red,
                      ),
                    ],
                  )
          ],
        ),
      )),
    );
  }

  String _getStateString(BLEState state) {
    switch (state) {
      case BLEState.idle:
        return 'Idle';
      case BLEState.connecting:
        return 'Connecting...';
      case BLEState.connected:
        return 'Connected';
      case BLEState.found:
        return 'Found';
      case BLEState.scanning:
        return 'Scanning...';
    }
  }
}
