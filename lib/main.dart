import 'dart:async';

import 'package:asset_copy/asset_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sweph/sweph.dart';

// import 'io_helper.dart';
import 'web_helper.dart' if (dart.library.ffi) 'io_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final stopwatch = Stopwatch()..start();

  runApp(MyApp(
    timeToLoad: stopwatch.elapsed,
  ));
}

class MyApp extends StatefulWidget {
  final Duration timeToLoad;
  // const MyApp({super.key});
  const MyApp({super.key, required this.timeToLoad});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _statusMessage = 'Copying asset...';
  String swephVersion = '';
  // String swephVersion = Sweph.swe_version();
  String moonPosition = '';
  late HouseCuspData houseSystemAscmc;

  @override
  void initState() {
    super.initState();
    if (kIsWeb == false) {
      copyAssetToLocal();
    }

    //
    initS();

    // await initSweph([
    //   'sepl_18.se1', // For house calc
    //   //   'ephe/seasnam.txt', // For asteriods
    // ]);
  }

  Future<void> initS() async {
    await initSweph([
      'sepl_18.se1', // For house calc
      //   'ephe/sefstars.txt', // For star position
      //   'ephe/seasnam.txt', // For asteriods
    ]);
    setState(() {
      swephVersion = Sweph.swe_version();
    });
  }

  Future<void> copyAssetToLocal() async {
    String status;
    try {
      const assetName = 'sepl_18.se1';
      const targetPath = 'sepl_18.se1';

      await AssetCopy.copyAssetToLocalStorage(assetName, targetPath);
      status = 'File copied successfully to $targetPath';
    } on PlatformException catch (e) {
      status = 'Failed to copy asset: ${e.message}';
    }

    if (!mounted) return;

    setState(() {
      _statusMessage = status;
    });
  }

  static String getMoonPosition() {
    final jd =
        Sweph.swe_julday(2024, 12, 2, (2 + 52 / 60), CalendarType.SE_GREG_CAL);
    final pos =
        Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH);
    return 'lat=${pos.latitude.toStringAsFixed(3)} lon=${pos.longitude.toStringAsFixed(3)}';
  }

  static HouseCuspData getHouseSystemAscmc() {
    const year = 1947;
    const month = 8;
    const day = 15;
    const hour = 16 + (0.0 / 60.0) - 5.5;

    const longitude = 81 + 50 / 60.0;
    const latitude = 25 + 57 / 60.0;
    final julday =
        Sweph.swe_julday(year, month, day, hour, CalendarType.SE_GREG_CAL);

    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI,
        SiderealModeFlag.SE_SIDBIT_NONE, 0.0 /* t0 */, 0.0 /* ayan_t0 */);
    return Sweph.swe_houses(julday, latitude, longitude, Hsys.P);
  }

  void _addText(List<Widget> children, String text) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);

    children.add(spacerSmall);
    children.add(Text(
      text,
      style: textStyle,
      textAlign: TextAlign.center,
    ));
  }

  Widget _getContent(BuildContext context) {
    List<Widget> children = [
      const Text(
        'Swiss Ephemeris Example',
        style: TextStyle(fontSize: 30),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 10)
    ];

    _addText(children,
        'Time taken to load Sweph: ${widget.timeToLoad.inMilliseconds} ms');
    setState(() {
      swephVersion = Sweph.swe_version();
      moonPosition = getMoonPosition();
      houseSystemAscmc = getHouseSystemAscmc();
    });
    _addText(children, 'Sweph Version: $swephVersion');
    _addText(
        children, 'Moon position on 2024-12-2 02:52:00 UTC: $moonPosition');
    _addText(children,
        'House System ASCMC[0] for custom time: ${houseSystemAscmc.ascmc[0]}');

    _addText(children, "Copy status: ${_statusMessage}");

    return Column(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Swiss Test App example'),
        ),
        body: Center(
          child: _getContent(context),
        ),
      ),
    );
  }
}
