import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ====== PERSONALIZA AQUI ======
const String kNombre = 'EDUARDO';
const String kCiudad = 'Zipaquirá';
const String kInterno = 'Buseta · Interno 004';
const double kLatDef = 5.0228, kLonDef = -74.0059;
// ==============================

const _dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const _meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
  'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: Home()));
}

// ---------- acciones ----------
Future<void> abrirWaze() async {
  try {
    if (await InstalledApps.startApp('com.waze') == true) return;
  } catch (_) {}
  await launchUrl(Uri.parse('https://waze.com/ul'), mode: LaunchMode.externalApplication);
}

Future<void> wazeFavorito(String f) async {
  try {
    final i = AndroidIntent(
        action: 'action_view', data: 'waze://?favorite=$f&navigate=yes', package: 'com.waze');
    if (await i.canResolveActivity() == true) return i.launch();
  } catch (_) {}
  await abrirWaze();
}

Future<void> abrirYoutubeBrave() async {
  const url = 'https://www.youtube.com';
  try {
    final i = AndroidIntent(action: 'action_view', data: url, package: 'com.brave.browser');
    if (await i.canResolveActivity() == true) return i.launch();
  } catch (_) {}
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

Future<void> abrirSpotify() async {
  try {
    if (await InstalledApps.startApp('com.spotify.music') == true) return;
  } catch (_) {}
  await launchUrl(Uri.parse('https://open.spotify.com'), mode: LaunchMode.externalApplication);
}

Future<void> ajustes(String action) async {
  try { await AndroidIntent(action: action).launch(); } catch (_) {}
}

// ---------- estilo ----------
class Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color? tint;
  const Glass({super.key, required this.child, this.radius = 26,
      this.padding = const EdgeInsets.all(16), this.tint});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [(tint ?? Colors.white).withOpacity(0.28), Colors.white.withOpacity(0.07)]),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.2),
            ),
            child: child,
          ),
        ),
      );
}

Widget pill(String t, {double size = 12, Color? bg}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
          color: bg ?? Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.35))),
      child: Text(t, style: TextStyle(color: Colors.white, fontSize: size)),
    );

class MascotPainter extends CustomPainter {
  final double t;
  final bool hablando;
  MascotPainter(this.t, this.hablando);
  @override
  void paint(Canvas c, Size s) {
    final m = s.center(Offset.zero);
    final r = s.width / 2;
    c.drawCircle(m, r, Paint()..color = const Color(0xFF7BE04A));
    c.drawCircle(m, r - 1.5, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = Colors.white);
    final mej = Paint()..color = const Color(0x88FF6B6B);
    c.drawCircle(m + Offset(-r * .55, r * .2), r * .14, mej);
    c.drawCircle(m + Offset(r * .55, r * .2), r * .14, mej);
    final par = sin(t * 2 * pi * 3) > .95 ? .1 : 1.0;
    for (final k in [-1, 1]) {
      c.drawOval(Rect.fromCenter(center: m + Offset(r * .35 * k, -r * .2),
          width: r * .22, height: r * .3 * par), Paint()..color = Colors.black87);
    }
    final ab = hablando ? sin(t * 2 * pi * 8).abs() : 0.12;
    c.drawOval(Rect.fromCenter(center: m + Offset(0, r * .45), width: r * .55,
        height: r * (.08 + .3 * ab)), Paint()..color = const Color(0xFF7A1F1F));
  }
  @override
  bool shouldRepaint(covariant MascotPainter o) => true;
}

class WazePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, cx = w / 2, cy = s.height * .45, rx = w * .48, ry = s.height * .40;
    final azul = Paint()..color = const Color(0xFF33CCFF);
    final osc = Paint()..color = const Color(0xFF283246);
    c.drawPath(Path()..moveTo(cx - rx * .62, cy + ry * .55)..lineTo(cx - rx * .98, cy + ry * 1.15)
        ..lineTo(cx - rx * .15, cy + ry * .85)..close(), azul);
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2), azul);
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 1.56, height: ry * 1.56),
        Paint()..color = Colors.white);
    for (final k in [-1, 1]) {
      c.drawOval(Rect.fromCenter(center: Offset(cx + k * rx * .28, cy - ry * .22),
          width: rx * .14, height: ry * .22), osc);
      c.drawCircle(Offset(cx + k * rx * .5, cy + ry * .78), ry * .17, osc);
    }
    c.drawArc(Rect.fromCenter(center: Offset(cx, cy + ry * .1), width: rx * .6, height: ry * .5),
        0.35, 2.4, false, Paint()..color = const Color(0xFF283246)..style = PaintingStyle.stroke
        ..strokeWidth = w * .03..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class YtPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, s.height * .15, s.width, s.height * .7),
        Radius.circular(s.height * .22)), Paint()..color = const Color(0xFFFF0000));
    c.drawPath(Path()..moveTo(s.width * .4, s.height * .33)..lineTo(s.width * .4, s.height * .67)
        ..lineTo(s.width * .68, s.height * .5)..close(), Paint()..color = Colors.white);
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class SpPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final m = s.center(Offset.zero), r = s.width / 2;
    c.drawCircle(m, r, Paint()..color = const Color(0xFF1ED760));
    final p = Paint()..color = const Color(0xFF0E140F)..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final a in [[.66, .12, .11], [.52, .30, .09], [.38, .46, .075]]) {
      p.strokeWidth = r * a[2];
      c.drawArc(Rect.fromCircle(center: m + Offset(0, r * a[1] * .6), radius: r * a[0]),
          -145 * pi / 180, 110 * pi / 180, false, p);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ---------- pantalla principal ----------
class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final tts = FlutterTts();
  late final AnimationController anim =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  late final WebViewController mapa = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted);
  bool hablando = false, saludoVisible = true, nocturno = false;
  DateTime now = DateTime.now();
  double lat = kLatDef, lon = kLonDef;
  num? temp, sens, hum, viento, tmax, tmin;
  int? code;
  Timer? reloj, refresco;

  @override
  void initState() {
    super.initState();
    reloj = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => now = DateTime.now()));
    _cargarMapa();
    _saludar();
    _ubicarYClima();
    refresco = Timer.periodic(const Duration(minutes: 2), (_) => _ubicarYClima());
  }

  @override
  void dispose() {
    reloj?.cancel();
    refresco?.cancel();
    anim.dispose();
    super.dispose();
  }

  void _cargarMapa() => mapa.loadRequest(Uri.parse(
      'https://embed.waze.com/iframe?zoom=15&lat=$lat&lon=$lon&ct=livemap&pin=1'));

  Future<void> _saludar() async {
    try {
      await tts.setLanguage('es-CO');
      await tts.setPitch(1.3);
      await tts.setSpeechRate(0.45);
      tts.setStartHandler(() => setState(() => hablando = true));
      tts.setCompletionHandler(() => setState(() => hablando = false));
      tts.setErrorHandler((_) => setState(() => hablando = false));
      setState(() => saludoVisible = true);
      await tts.speak('Hola $kNombre, bienvenido');
    } catch (_) {}
    await Future.delayed(const Duration(seconds: 6));
    if (mounted) setState(() => saludoVisible = false);
  }

  Future<void> _ubicarYClima() async {
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p != LocationPermission.denied && p != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium).timeout(const Duration(seconds: 10));
        lat = pos.latitude;
        lon = pos.longitude;
        _cargarMapa();
      }
    } catch (_) {}
    try {
      final r = await http.get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat'
          '&longitude=$lon&current=temperature_2m,apparent_temperature,relative_humidity_2m,'
          'wind_speed_10m,weather_code&daily=temperature_2m_max,temperature_2m_min&timezone=auto'))
          .timeout(const Duration(seconds: 10));
      final j = jsonDecode(r.body);
      final c = j['current'], d = j['daily'];
      if (!mounted) return;
      setState(() {
        temp = c['temperature_2m'];
        sens = c['apparent_temperature'];
        hum = c['relative_humidity_2m'];
        viento = c['wind_speed_10m'];
        code = c['weather_code'];
        tmax = d['temperature_2m_max'][0];
        tmin = d['temperature_2m_min'][0];
      });
    } catch (_) {}
  }

  (IconData, String) get clima {
    final c = code ?? -1;
    if (c == 0) return (Icons.wb_sunny_rounded, 'Despejado');
    if (c <= 3 && c > 0) return (Icons.cloud_rounded, 'Nublado');
    if (c == 45 || c == 48) return (Icons.foggy, 'Niebla');
    if (c >= 51 && c <= 57) return (Icons.grain, 'Llovizna');
    if (c >= 61 && c <= 67 || c >= 80 && c <= 82) return (Icons.water_drop_rounded, 'Lluvia');
    if (c >= 71 && c <= 77) return (Icons.ac_unit, 'Nieve');
    if (c >= 95) return (Icons.thunderstorm_rounded, 'Tormenta');
    return (Icons.cloud_queue_rounded, 'Sin datos');
  }

  String get saludoHora => now.hour < 12 ? 'Buenos días' : now.hour < 19 ? 'Buenas tardes' : 'Buenas noches';
  String two(int n) => n.toString().padLeft(2, '0');
  String n0(num? v) => v == null ? '--' : v.round().toString();

  Widget mascota(double size) => AnimatedBuilder(
      animation: anim,
      builder: (_, __) => CustomPaint(size: Size(size, size), painter: MascotPainter(anim.value, hablando)));

  void _todasLasApps() => showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => const AppDrawer());

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF16205C),
        body: Stack(fit: StackFit.expand, children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF16205C), Color(0xFF4A2480)]))),
          _glow(-120, 120, const Color(0xFF46BE3C)),
          _glow(380, 200, const Color(0xFF2878E6)),
          _glow(700, -60, const Color(0xFFBE3CDC)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(flex: 35, child: _tarjetaBus()),
                  const SizedBox(width: 12),
                  Expanded(flex: 30, child: Column(children: [
                    Expanded(flex: 4, child: _reloj()),
                    const SizedBox(height: 12),
                    Expanded(flex: 7, child: _mapaCard()),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(flex: 31, child: _wazeCard()),
                ])),
                SizedBox(height: 62, child: _nav()),
              ]),
            ),
          ),
          if (nocturno) IgnorePointer(child: Container(color: Colors.black.withOpacity(0.55))),
          IgnorePointer(
            ignoring: !saludoVisible,
            child: AnimatedOpacity(
              opacity: saludoVisible ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: Center(
                child: GestureDetector(
                  onTap: _saludar,
                  child: Glass(radius: 36, padding: const EdgeInsets.all(26),
                    tint: const Color(0xFF7BE04A),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      mascota(120),
                      const SizedBox(width: 24),
                      Text('¡Hola $kNombre,\nbienvenido!', style: const TextStyle(
                          color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700)),
                    ])),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _glow(double x, double y, Color c) => Positioned(left: x, top: y,
      child: Container(width: 420, height: 420, decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c.withOpacity(0.5), c.withOpacity(0)]))));

  Widget _tarjetaBus() {
    final (ico, desc) = clima;
    return Glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hola, $kNombre', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
            Text('$saludoHora · ¡Bienvenido!',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
          ])),
          GestureDetector(onTap: _saludar, child: mascota(54)),
        ]),
        Expanded(child: Center(child: Image.asset('assets/bus.png', fit: BoxFit.contain))),
        Row(children: [
          Icon(ico, color: Colors.white, size: 40),
          const SizedBox(width: 8),
          Text('${n0(temp)}°', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w300)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(desc, style: const TextStyle(color: Colors.white, fontSize: 15)),
            Text('Sensación ${n0(sens)}°', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
          ])),
        ]),
        const SizedBox(height: 8),
        pill('↑ ${n0(tmax)}°  ↓ ${n0(tmin)}°   ${n0(hum)}%   ${n0(viento)} km/h'),
      ]),
    );
  }

  Widget _reloj() => Glass(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${two(now.hour)}:${two(now.minute)}', style: const TextStyle(
              color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700)),
          Text('${_dias[now.weekday - 1]}, ${now.day} de ${_meses[now.month - 1]}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          pill(kInterno),
        ]),
      );

  Widget _mapaCard() => ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(children: [
          Positioned.fill(child: WebViewWidget(controller: mapa)),
          Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: abrirWaze)),
          Positioned(left: 12, top: 12, child: IgnorePointer(child: pill('MAPA WAZE', size: 11, bg: const Color(0xCC0A0E28)))),
          Positioned(left: 12, right: 12, bottom: 12,
              child: IgnorePointer(child: Center(child: pill('$kCiudad · toca para abrir Waze', bg: const Color(0xCC0A0E28))))),
          Positioned.fill(child: IgnorePointer(child: Container(decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.2))))),
        ]),
      );

  Widget _wazeCard() => Glass(
        tint: const Color(0xFF3CBEFF),
        child: Column(children: [
          Align(alignment: Alignment.centerLeft, child: pill('WAZE', size: 11)),
          Expanded(child: GestureDetector(onTap: abrirWaze,
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                  child: AspectRatio(aspectRatio: 1, child: CustomPaint(painter: WazePainter()))))),
          const Text('¿A dónde vamos?', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700)),
          Text(kNombre, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF33CCFF)),
              onPressed: abrirWaze, child: const Text('Abrir Waze'))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => wazeFavorito('Home'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white), child: const Text('Casa'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => wazeFavorito('Work'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white), child: const Text('Trabajo'))),
          ]),
        ]),
      );

  Widget _btn(Widget w, VoidCallback f) => InkResponse(
      onTap: f, radius: 34, child: SizedBox(width: 64, height: 56, child: Center(child: w)));

  Widget _nav() => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _btn(SizedBox(width: 36, height: 36, child: CustomPaint(painter: WazePainter())), abrirWaze),
        _btn(const Icon(Icons.bluetooth, color: Colors.white, size: 30),
            () => ajustes('android.settings.BLUETOOTH_SETTINGS')),
        _btn(SizedBox(width: 42, height: 34, child: CustomPaint(painter: YtPainter())), abrirYoutubeBrave),
        _btn(SizedBox(width: 36, height: 36, child: CustomPaint(painter: SpPainter())), abrirSpotify),
        _btn(Container(width: 46, height: 46, padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF50C8FF), width: 4)),
            child: Container(decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA078FF), width: 4)))), _todasLasApps),
        _btn(Icon(nocturno ? Icons.wb_sunny_rounded : Icons.nightlight_round, color: Colors.white, size: 30),
            () => setState(() => nocturno = !nocturno)),
        _btn(const Icon(Icons.tune, color: Colors.white, size: 30),
            () => ajustes('android.settings.SOUND_SETTINGS')),
        _btn(const Icon(Icons.settings, color: Colors.white, size: 30),
            () => ajustes('android.settings.SETTINGS')),
      ]);
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Glass(
          radius: 30,
          tint: const Color(0xFF16205C),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .72,
            child: FutureBuilder<List<AppInfo>>(
              future: InstalledApps.getInstalledApps(true, true),
              builder: (_, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final list = snap.data!..sort((a, b) =>
                    '${a.name}'.toLowerCase().compareTo('${b.name}'.toLowerCase()));
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8, childAspectRatio: .95),
                  itemCount: list.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => InstalledApps.startApp(list[i].packageName),
                    child: Column(children: [
                      if (list[i].icon != null) Image.memory(list[i].icon!, width: 46, height: 46),
                      const SizedBox(height: 4),
                      Text('${list[i].name}', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ),
      );
}
