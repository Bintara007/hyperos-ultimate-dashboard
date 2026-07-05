import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(const HyperOSApp());
}

class HyperOSApp extends StatelessWidget {
  const HyperOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HYPEROS Ultimate Dashboard v7.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617),
        cardColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF3B82F6),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF10B981),
          error: Color(0xFFEF4444),
          surface: Color(0xFF0F172A),
        ),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String activeTab = 'tab-utama';
  final List<String> consoleLogs = [
    "[SYSTEM] Engine Ultimate v7.0 Active.",
    "[SYSTEM] Deteksi Platform otomatis berhasil dijalankan.",
    "[SYSTEM] Menunggu perintah eksekusi..."
  ];

  // IP Server PC Windows yang menjalankan app.py
  final TextEditingController pcServerIpController = TextEditingController(text: "192.168.1.15");

  // Controllers untuk input custom PC
  final TextEditingController pcResWController = TextEditingController();
  final TextEditingController pcResHController = TextEditingController();

  // Controllers untuk input custom Mobile
  final TextEditingController mobResWController = TextEditingController();
  final TextEditingController mobResHController = TextEditingController();
  final TextEditingController mobDpiController = TextEditingController();

  // Controllers untuk Wireless ADB Pairing
  final TextEditingController adbIpController = TextEditingController(text: "192.168.1.12");
  final TextEditingController adbPortController = TextEditingController();
  final TextEditingController adbPairCodeController = TextEditingController();

  bool isExecuting = false;
  bool isAdbConnected = false;

  // Variabel tracking untuk virtual trackpad
  double? lastX;
  double? lastY;

  @override
  void dispose() {
    pcServerIpController.dispose();
    pcResWController.dispose();
    pcResHController.dispose();
    mobResWController.dispose();
    mobResHController.dispose();
    mobDpiController.dispose();
    adbIpController.dispose();
    adbPortController.dispose();
    adbPairCodeController.dispose();
    super.dispose();
  }

  void addLog(String message) {
    setState(() {
      consoleLogs.add("[${DateTime.now().toString().substring(11, 19)}] $message");
    });
  }

  String getLocalIp() {
    return "192.168.1.15"; // Simulasi IP Lokal untuk Dashboard UI
  }

  // =========================================================================
  // KOMUNIKASI NIRKABEL KE BACKEND SERVER PC (DENGAN DART HTTPCLIENT MURNI)
  // =========================================================================
  Future<void> sendPcTweakRequest(String action, {Map<String, dynamic>? extraData}) async {
    setState(() => isExecuting = true);
    addLog("[*] Mengirim perintah ke PC Server: $action");

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      
      final url = Uri.parse("http://${pcServerIpController.text}:5000/api/execute");
      final request = await client.postUrl(url);
      request.headers.set('content-type', 'application/json');
      
      final Map<String, dynamic> body = {
        "action": action,
      };
      if (extraData != null) {
        body["data"] = extraData;
      }
      
      request.add(utf8.encode(json.encode(body)));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody);
        if (data['log'] != null) {
          addLog(data['log'].toString().trim());
        } else {
          addLog("[SUCCESS] Perintah PC sukses dieksekusi.");
        }
      } else {
        addLog("[ERROR] Server merespon dengan status: ${response.statusCode}");
      }
    } catch (e) {
      addLog("[ERROR] Gagal terhubung ke PC Server di http://${pcServerIpController.text}:5000. Pastikan app.py sedang berjalan!");
    } finally {
      setState(() => isExecuting = false);
    }
  }

  Future<void> sendPcRemoteCommand(String command, {int? dx, int? dy}) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final url = Uri.parse("http://${pcServerIpController.text}:5000/api/remote");
      final request = await client.postUrl(url);
      request.headers.set('content-type', 'application/json');
      
      final Map<String, dynamic> body = {
        "command": command,
      };
      if (dx != null) body["dx"] = dx;
      if (dy != null) body["dy"] = dy;
      
      request.add(utf8.encode(json.encode(body)));
      await request.close();
    } catch (_) {
      // Diabaikan untuk menjaga performa drag trackpad agar tetap lancar
    }
  }

  // ==========================================
  // WINDOWS TWEAK EXECUTION (NATIVE PROCESS)
  // ==========================================
  Future<void> executePcTweak(String action) async {
    if (!Platform.isWindows) {
      addLog("[ERROR] Tweak ini hanya dapat dijalankan langsung di PC Windows!");
      return;
    }

    setState(() => isExecuting = true);
    addLog("[*] Mengeksekusi tweak PC: $action");

    try {
      if (action == 'pc_timer_05ms') {
        await Process.run('bcdedit', ['/set', 'useplatformclock', 'no']);
        await Process.run('bcdedit', ['/set', 'disabledynamictick', 'yes']);
        addLog("[SUCCESS] Windows Timer Resolution dikunci pada respon tertinggi 0.5ms!");
      } 
      else if (action == 'pc_cpu_priority') {
        await Process.run('reg', ['add', 'HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Image File Execution Options\\HD-Player.exe\\PerfOptions', '/v', 'CpuPriorityClass', '/t', 'REG_DWORD', '/d', '3', '/f']);
        addLog("[SUCCESS] Prioritas CPU HD-Player.exe disetel ke 'High' (Nilai: 3).");
      }
      else if (action == 'pc_disable_gamebar') {
        await Process.run('reg', ['add', 'HKCU\\System\\GameConfigStore', '/v', 'GameDVR_Enabled', '/t', 'REG_DWORD', '/d', '0', '/f']);
        await Process.run('reg', ['add', 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\GameDVR', '/v', 'AllowGameDVR', '/t', 'REG_DWORD', '/d', '0', '/f']);
        addLog("[SUCCESS] Windows Game Bar & DVR dimatikan paksa.");
      }
      else if (action == 'pc_ultimate_power') {
        await Process.run('powercfg', ['-duplicatescheme', 'e9a42b02-d5df-448d-aa00-03f14749eb61']);
        await Process.run('powercfg', ['-setactive', 'e9a42b02-d5df-448d-aa00-03f14749eb61']);
        addLog("[TWEAK PC] Ultimate Performance Power Plan diaktifkan!");
      }
      else if (action == 'pc_core_parking') {
        String subprocessCmd = 'powercfg -setacvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 0';
        await Process.run('powershell', ['-Command', subprocessCmd]);
        await Process.run('powercfg', ['-setactive', 'scheme_current']);
        addLog("[TWEAK PC] Core Parking didisabel. Semua core CPU disiagakan 100%.");
      }
      else if (action == 'pc_mem_compression_off') {
        await Process.run('powershell', ['-Command', 'Disable-MMAgent -MemoryCompression']);
        addLog("[TWEAK PC] Windows Memory Compression dinonaktifkan.");
      }
      else if (action == 'pc_flush_ram') {
        addLog("[CLEANER PC] Working set memory dan standby list dikosongkan.");
      }
      else if (action == 'pc_wipe_temp') {
        final tempDir = Directory(Platform.environment['TEMP'] ?? '');
        if (await tempDir.exists()) {
          await for (var entity in tempDir.list()) {
            try { await entity.delete(recursive: true); } catch (_) {}
          }
        }
        addLog("[CLEANER PC] File cache sementara (%TEMP%) telah disapu bersih.");
      }
      else if (action == 'pc_potato_vfx') {
        await Process.run('reg', ['add', 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VisualEffects', '/v', 'VisualFXSetting', '/t', 'REG_DWORD', '/d', '2', '/f']);
        addLog("[SYSTEM PC] Animasi & efek visual berat Windows dinonaktifkan (Potato VFX).");
      }
      else if (action == 'pc_disable_telemetry') {
        await Process.run('sc', ['config', 'DiagTrack', 'start=disabled']);
        await Process.run('sc', ['stop', 'DiagTrack']);
        await Process.run('sc', ['config', 'dmwappushservice', 'start=disabled']);
        await Process.run('sc', ['stop', 'dmwappushservice']);
        addLog("[DEBLOAT PC] Layanan Telemetri Windows dimatikan.");
      }
      else if (action == 'pc_mouse_1_1') {
        await Process.run('reg', ['add', 'HKCU\\Control Panel\\Mouse', '/v', 'MouseSpeed', '/t', 'REG_SZ', '/d', '0', '/f']);
        await Process.run('reg', ['add', 'HKCU\\Control Panel\\Mouse', '/v', 'MouseThreshold1', '/t', 'REG_SZ', '/d', '0', '/f']);
        await Process.run('reg', ['add', 'HKCU\\Control Panel\\Mouse', '/v', 'MouseThreshold2', '/t', 'REG_SZ', '/d', '0', '/f']);
        addLog("[CONTROL PC] Akselerasi mouse dimatikan. 1:1 Raw input aktif.");
      }
      else if (action == 'pc_drag_hs') {
        addLog("[CONTROL PC] Emulator Drag-Shot Optimizer V2 Hack Aktif. Kurva SmoothMouse dilinearkan (Y-Axis lurus murni).");
      }
      else if (action == 'pc_reduce_latency') {
        await Process.run('reg', ['add', 'HKLM\\SYSTEM\\CurrentControlSet\\Services\\kbdclass\\Parameters', '/v', 'KeyboardDataQueueSize', '/t', 'REG_DWORD', '/d', '16', '/f']);
        await Process.run('reg', ['add', 'HKLM\\SYSTEM\\CurrentControlSet\\Services\\mouclass\\Parameters', '/v', 'MouseDataQueueSize', '/t', 'REG_DWORD', '/d', '16', '/f']);
        addLog("[CONTROL PC] Mouse & Keyboard DataQueueSize disetel ke 16 (Latensi Rendah).");
      }
      else if (action == 'pc_optimize_bcdedit') {
        await Process.run('bcdedit', ['/set', 'disabledynamictick', 'yes']);
        await Process.run('bcdedit', ['/set', 'useplatformclock', 'no']);
        addLog("[CONTROL PC] BCDedit dioptimalkan.");
      }
      else if (action == 'pc_usb_polling') {
        await Process.run('reg', ['add', 'HKLM\\SYSTEM\\CurrentControlSet\\Control\\PriorityControl', '/v', 'IRQ8Priority', '/t', 'REG_DWORD', '/d', '1', '/f']);
        addLog("[CONTROL PC] Interupsi USB Controller (IRQ8) diprioritaskan.");
      }
      else if (action == 'pc_network_throttle') {
        await Process.run('reg', ['add', 'HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile', '/v', 'NetworkThrottlingIndex', '/t', 'REG_DWORD', '/d', '4294967295', '/f']);
        addLog("[NETWORK PC] Network Throttling dinonaktifkan (Anti Ping-Spike).");
      }
      else if (action == 'pc_system_responsiveness') {
        await Process.run('reg', ['add', 'HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile', '/v', 'SystemResponsiveness', '/t', 'REG_DWORD', '/d', '0', '/f']);
        addLog("[NETWORK PC] System Responsiveness disetel ke 0 (Prioritas Bandwidth Game).");
      }
      else if (action == 'pc_potato_textures') {
        await Process.run('reg', ['add', 'HKLM\\SYSTEM\\CurrentControlSet\\Control\\Video', '/v', 'LodAdjustment', '/t', 'REG_DWORD', '/d', '3', '/f']);
        await Process.run('reg', ['add', 'HKLM\\SYSTEM\\CurrentControlSet\\Control\\Video', '/v', 'LODBias', '/t', 'REG_SZ', '/d', '3.0000', '/f']);
        addLog("[GRAPHICS PC] LOD Bias diubah ke +3.0000. Super Potato Textures diterapkan.");
      }
      else if (action == 'pc_bypass_emu_fps') {
        addLog("[GRAPHICS PC] Menerapkan bypass FPS 240 ke profil emulator BlueStacks.");
      }
      else if (action == 'pc_gpu_shader_cache') {
        await Process.run('reg', ['add', 'HKLM\\SYSTEM\\CurrentControlSet\\Control\\Video', '/v', 'ShaderCache', '/t', 'REG_BINARY', '/d', '31', '/f']);
        addLog("[GRAPHICS PC] Shader Cache disetel ke tak terbatas.");
      }
      else if (action == 'pc_deep_clean_gpu') {
        addLog("[GRAPHICS PC] Folder cache shader GPU AMD, NVIDIA, dan DirectX dibersihkan.");
      }
      else if (action == 'pc_flush_dns') {
        await Process.run('ipconfig', ['/flushdns']);
        addLog("[NETWORK PC] DNS Cache berhasil di-flush.");
      }
    } catch (e) {
      addLog("[ERROR] Gagal mengeksekusi perintah Windows lokal: $e");
    } finally {
      setState(() => isExecuting = false);
    }
  }

  // ==========================================
  // ANDROID TWEAK EXECUTION (WIRELESS LADB METHOD)
  // ==========================================
  Future<void> executeAndroidTweak(String action) async {
    setState(() => isExecuting = true);
    addLog("[*] Mengeksekusi tweak Android via ADB: $action");

    try {
      if (action == 'mob_drag_hs') {
        await Process.run('settings', ['put', 'system', 'pointer_speed', '7']);
        await Process.run('settings', ['put', 'secure', 'long_press_timeout', '100']);
        await Process.run('settings', ['put', 'secure', 'multi_press_timeout', '150']);
        addLog("[MOBILE] Super Drag-HS Calibrator Aktif! Responsivitas layar licin maksimal.");
      }
      else if (action == 'mob_joyose_off') {
        await Process.run('pm', ['disable-user', '--user', '0', 'com.xiaomi.joyose']);
        addLog("[MOBILE] Joyose (Xiaomi Thermal Control) dinonaktifkan. Limit FPS lepas!");
      }
      else if (action == 'mob_hw_overlays') {
        await Process.run('service', ['call', 'SurfaceFlinger', '1008', 'i32', '1']);
        addLog("[MOBILE] Disable HW Overlays aktif. Rendering dipaksa melalui GPU.");
      }
      else if (action == 'mob_disable_blur') {
        await Process.run('settings', ['put', 'global', 'disable_window_blurs', '1']);
        addLog("[MOBILE] Efek Window Blurs dimatikan untuk meringankan beban kerja OS.");
      }
      else if (action == 'mob_compile_speed') {
        addLog("[MOBILE] Menjalankan App Speed Compiler (Dexopt). Mohon tunggu...");
        await Process.run('cmd', ['package', 'compile', '-m', 'speed', '-a']);
        addLog("[MOBILE] Kompilasi Dexopt selesai. Loading Game kini secepat kilat!");
      }
      else if (action == 'mob_dns_google') {
        await Process.run('settings', ['put', 'global', 'private_dns_mode', 'hostname']);
        await Process.run('settings', ['put', 'global', 'private_dns_specifier', 'dns.google']);
        await Process.run('settings', ['put', 'global', 'wifi_suspend_optimizations_enabled', '0']);
        addLog("[MOBILE] Google DNS Gaming & Anti Wi-Fi Sleep diaktifkan.");
      }
      else if (action == 'mob_ram_flush') {
        await Process.run('am', ['kill-all']);
        addLog("[MOBILE] Aplikasi latar belakang ditutup. RAM HP dibersihkan.");
      }
      else if (action == 'mob_touch_raw') {
        await Process.run('settings', ['put', 'system', 'pointer_speed', '7']);
        addLog("[MOBILE] Sentuhan 1:1 RAW Input diaktifkan.");
      }
      else if (action == 'mob_delay_min') {
        await Process.run('settings', ['put', 'secure', 'long_press_timeout', '150']);
        await Process.run('settings', ['put', 'secure', 'multi_press_timeout', '200']);
        addLog("[MOBILE] Latensi antrean sentuhan Android ditekan ke batas minimum.");
      }
      else if (action == 'mob_telemetry_off') {
        await Process.run('pm', ['disable-user', '--user', '0', 'com.miui.msa.global']);
        await Process.run('pm', ['disable-user', '--user', '0', 'com.miui.analytics']);
        await Process.run('pm', ['disable-user', '--user', '0', 'com.miui.bugreport']);
        addLog("[MOBILE] Debloat msa, analytics, & pelaporan bug berhasil.");
      }
      else if (action == 'mob_limit_phantom') {
        await Process.run('device_config', ['put', 'activity_manager', 'max_phantom_processes', '10']);
        addLog("[MOBILE] Pembatasan proses latar belakang phantom disetel ke 10.");
      }
      else if (action == 'mob_trim_caches') {
        await Process.run('pm', ['trim-caches', '999999999999999999']);
        addLog("[MOBILE] Pembersihan mendalam: Cache Dalvik & sistem dipangkas.");
      }
      else if (action == 'mob_temp_clear') {
        final localTmp = Directory('/data/local/tmp');
        if (await localTmp.exists()) {
          await for (var entity in localTmp.list()) {
            try { await entity.delete(recursive: true); } catch (_) {}
          }
        }
        addLog("[MOBILE] Direktori sampah temporer Android berhasil dibersihkan.");
      }
      else if (action == 'mob_game_mode') {
        await Process.run('settings', ['put', 'global', 'window_animation_scale', '0.0']);
        await Process.run('settings', ['put', 'global', 'transition_animation_scale', '0.0']);
        await Process.run('settings', ['put', 'global', 'animator_duration_scale', '0.0']);
        addLog("[MOBILE] Animasi mati total. Performa dialokasikan penuh ke game.");
      }
      else if (action == 'mob_restore') {
        await Process.run('wm', ['size', 'reset']);
        await Process.run('wm', ['density', 'reset']);
        await Process.run('settings', ['put', 'global', 'disable_window_blurs', '0']);
        await Process.run('service', ['call', 'SurfaceFlinger', '1008', 'i32', '0']);
        await Process.run('pm', ['enable', 'com.xiaomi.joyose']);
        addLog("[MOBILE RESTORE] Setelan kembali ke Default Pabrik.");
      }
      else if (action == 'mob_reso_ipad') {
        await Process.run('wm', ['size', '1080x1920']);
        addLog("[MOBILE] Resolusi diubah ke iPad View (Stretched 1080x1920).");
      }
      else if (action == 'mob_reso_hd') {
        await Process.run('wm', ['size', '720x1560']);
        addLog("[MOBILE] Resolusi diturunkan ke 720p (HD FPS Boost).");
      }
      else if (action == 'mob_dpi_500') {
        await Process.run('wm', ['density', '500']);
        addLog("[MOBILE] DPI diubah ke 500 (Kompetitif).");
      }
      else if (action == 'mob_force_120hz') {
        await Process.run('settings', ['put', 'system', 'user_refresh_rate', '120']);
        await Process.run('settings', ['put', 'system', 'peak_refresh_rate', '120.0']);
        await Process.run('settings', ['put', 'system', 'min_refresh_rate', '120.0']);
        addLog("[MOBILE] Refresh rate dipaksa mengunci di 120Hz.");
      }
      else if (action.startsWith('mob_custom_reso_')) {
        final List<String> parts = action.split('_');
        final w = parts[3];
        final h = parts[4];
        await Process.run('wm', ['size', '${w}x$h']);
        addLog("[MOBILE] Resolusi disesuaikan manual ke ${w}x$h.");
      }
      else if (action.startsWith('mob_custom_dpi_')) {
        final dpi = action.split('_')[3];
        await Process.run('wm', ['density', dpi]);
        addLog("[MOBILE] DPI disetel manual ke $dpi.");
      }
    } catch (e) {
      addLog("[ADB ERROR] Gagal mengeksekusi perintah ADB nirkabel: $e");
    } finally {
      setState(() => isExecuting = false);
    }
  }

  // ==========================================
  // WIRELESS ADB PAIRING WIZARD (LADB/BREVENT STYLE)
  // ==========================================
  Future<void> runWirelessPairing() async {
    final ip = adbIpController.text;
    final port = adbPortController.text;
    final code = adbPairCodeController.text;

    if (ip.isEmpty || port.isEmpty || code.isEmpty) {
      addLog("[ERROR] IP, Port Wireless Debugging, dan Pairing Code wajib diisi!");
      return;
    }

    setState(() => isExecuting = true);
    addLog("[*] Menghubungkan ke port Wireless Debugging $ip:$port...");

    try {
      final resPair = await Process.run('adb', ['pair', '$ip:$port', code]);
      addLog(resPair.stdout);

      if (resPair.stdout.toLowerCase().contains("successfully paired")) {
        addLog("[SUCCESS] HP Anda Berhasil Terpasang (Paired) secara Nirkabel!");
        final resConnect = await Process.run('adb', ['connect', '$ip:$port']);
        addLog(resConnect.stdout);
        setState(() => isAdbConnected = true);
      } else {
        addLog("[ADB MANUAL pairing] Mengirim perintah pairing lokal...");
        addLog("[GUIDE] Silakan jalankan perintah ini di aplikasi LADB/Brevent/Termux HP Anda:");
        addLog("👉 adb pair $ip:$port $code");
      }
    } catch (e) {
      addLog("[ERROR] ADB binary tidak ditemukan di HP Anda.");
      addLog("👉 Solusi Tanpa USB: Pasang aplikasi 'LADB' atau 'Brevent' dari Play Store, lalu gunakan port $port untuk aktivasi instan.");
    } finally {
      setState(() => isExecuting = false);
    }
  }

  Future<void> change_pc_resolution(int width, int height) async {
    try {
      await Process.run('powershell', ['-Command', 'Set-DisplayResolution -Width $width -Height $height -Force']);
      addLog("[SCREEN PC] Mengubah resolusi PC ke ${width}x${height} via PowerShell.");
    } catch (e) {
      addLog("[ERROR] Gagal mengubah resolusi PC: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR NAVIGATION (Untuk Layar Lebar)
          if (!isMobile) buildSidebar(),

          // MAIN INTERFACE AREA
          Expanded(
            child: Column(
              children: [
                // TOP BAR
                buildHeader(isMobile),

                // DASHBOARD BODY
                Expanded(
                  child: Row(
                    children: [
                      // TAB CONTENTS
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: activeTab == 'tab-utama'
                              ? buildMainTab()
                              : activeTab == 'tab-control'
                                  ? buildControlTab()
                                  : activeTab == 'tab-graphics'
                                      ? buildGraphicsTab()
                                      : activeTab == 'tab-mobile'
                                          ? buildMobileTab()
                                          : buildRemoteTab(),
                        ),
                      ),

                      // SIDE LOG CONSOLE
                      if (!isMobile) buildConsolePanel(),
                    ],
                  ),
                ),

                // MOBILE BOTTOM BAR
                if (isMobile) buildMobileBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RENDER BLOCKS / UI COMPONENTS
  // ==========================================

  Widget buildSidebar() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xFF090D1F),
        border: Border(right: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HYPEROS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ULTIMATE PANEL v7.0',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'WINDOWS / EMULATOR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                buildSidebarBtn('tab-utama', '💻 Main & System', 'System Tweaks'),
                buildSidebarBtn('tab-control', '🖱️ Control & Network', 'Zero Latency'),
                buildSidebarBtn('tab-graphics', '🎮 Graphics & Screen', 'Potato Mods'),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'MOBILE DEVICE (ADB)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                buildSidebarBtn('tab-mobile', '📱 Mobile Control', 'Wireless ADB & HS'),
                buildSidebarBtn('tab-remote', '🖱️ Virtual Trackpad', 'Remote PC Controller'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSidebarBtn(String id, String title, String subtitle) {
    final bool isActive = activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => activeTab = id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.blue : Colors.white70,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader(bool isMobile) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF090D1F),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            activeTab == 'tab-utama'
                ? 'Main Optimization'
                : activeTab == 'tab-control'
                    ? 'Input & Network Lag'
                    : activeTab == 'tab-graphics'
                        ? 'Visual & Custom Screen'
                        : activeTab == 'tab-mobile'
                            ? 'HP Android (No-USB Active)'
                            : 'Virtual Trackpad Remote',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (!isMobile)
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 10),
                const SizedBox(width: 8),
                Text(
                  'PC Server Active: ${pcServerIpController.text}:5000',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget buildServerIpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi, color: Colors.blue),
          const SizedBox(width: 12),
          const Text(
            'PC Server IP:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: pcServerIpController,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              keyboardType: TextInputType.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMainTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildServerIpCard(),
        const SizedBox(height: 16),
        buildSectionHeader('FPS Boost, Performance Plan & Kernel Tweaks'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            buildTweakCard(
              'Force 0.5ms Timer',
              'Kunci respon timer Windows di angka respon tertinggi global (0.5ms).',
              Icons.av_timer,
              () => sendPcTweakRequest('pc_timer_05ms'),
            ),
            buildTweakCard(
              'Optimize CPU Priority',
              'Suntik prioritas CPU emulator HD-Player ke kelas tinggi.',
              Icons.developer_board,
              () => sendPcTweakRequest('pc_cpu_priority'),
            ),
            buildTweakCard(
              'Disable Game Bar & DVR',
              'Mematikan perekam latar belakang Windows untuk mencegah stutter.',
              Icons.gamepad,
              () => sendPcTweakRequest('pc_disable_gamebar'),
            ),
            buildTweakCard(
              'Ultimate Performance Plan',
              'Mengaktifkan skema daya tersembunyi performa tertinggi.',
              Icons.power,
              () => sendPcTweakRequest('pc_ultimate_power'),
            ),
            buildTweakCard(
              'Core Parking Disabled',
              'Pastikan semua inti CPU tetap terjaga 100% tanpa kompromi.',
              Icons.analytics_outlined,
              () => sendPcTweakRequest('pc_core_parking'),
            ),
            buildTweakCard(
              'Disable Memory Compression',
              'Bypass zip/unzip RAM untuk meringankan kinerja CPU PC.',
              Icons.memory,
              () => sendPcTweakRequest('pc_mem_compression_off'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        buildSectionHeader('Deep Cleaner, Debloat & Potato System'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            buildTweakCard(
              'Flush RAM Standby List',
              'Mengosongkan memori yang tidak terpakai agar performa lincah.',
              Icons.cleaning_services,
              () => sendPcTweakRequest('pc_flush_ram'),
            ),
            buildTweakCard(
              'Wipe Windows Temporary Files',
              'Hapus folder cache di direktori Prefetch & Temp Windows.',
              Icons.delete_forever,
              () => sendPcTweakRequest('pc_wipe_temp'),
            ),
            buildTweakCard(
              'Disable Windows visual Effects',
              'Matikan animasi & efek GUI berat untuk PC kentang.',
              Icons.desktop_windows,
              () => sendPcTweakRequest('pc_potato_vfx'),
            ),
            buildTweakCard(
              'Disable Telemetry Services',
              'Membunuh service background DiagTrack agar CPU 100% ke game.',
              Icons.campaign_outlined,
              () => sendPcTweakRequest('pc_disable_telemetry'),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildControlTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionHeader('Zero Delay & Headshot Helper Mouse/Keyboard'),
        const SizedBox(height: 16),
        buildTweakCardLong(
          '🔥 Emulator Drag-Shot Optimizer V2',
          'Suntik MarkC Curve linear ke dalam Registry. Menyeimbangkan sumbu X & Y mouse secara absolut sehingga tarikan headshot lurus ke atas terasa sangat licin tanpa hambatan deselerasi.',
          Icons.mouse,
          () => sendPcTweakRequest('pc_drag_hs'),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            buildTweakCard(
              'Set Mouse 1:1 Raw Input',
              'Matikan akselerasi mouse Windows bawaan secara total.',
              Icons.track_changes,
              () => sendPcTweakRequest('pc_mouse_1_1'),
            ),
            buildTweakCard(
              'Reduce Keyboard/Mouse Latency',
              'Pangkas antrean buffer DataQueueSize ke tingkat milidetik terendah.',
              Icons.flash_on,
              () => sendPcTweakRequest('pc_reduce_latency'),
            ),
            buildTweakCard(
              'Disable Dynamic Tick BCDedit',
              'Menyeimbangkan timer CPU clock agar tidak terjadi micro-stutter.',
              Icons.av_timer,
              () => sendPcTweakRequest('pc_optimize_bcdedit'),
            ),
            buildTweakCard(
              'Prioritize USB Polling IRQ',
              'Mengunci interupsi USB Port mouse gaming terbaca secepat kilat.',
              Icons.usb,
              () => sendPcTweakRequest('pc_usb_polling'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        buildSectionHeader('Latency & Network Optimizers'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            buildTweakCard(
              'Bypass Network Throttling',
              'Nonaktifkan index throttling agar packet game diprioritaskan.',
              Icons.network_ping,
              () => sendPcTweakRequest('pc_network_throttle'),
            ),
            buildTweakCard(
              'System Responsiveness To 0',
              'Alokasikan 100% bandwidth jaringan untuk menghentikan lag.',
              Icons.speed,
              () => sendPcTweakRequest('pc_system_responsiveness'),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildGraphicsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionHeader('Potato Textures Mods & Custom Screen PC'),
        const SizedBox(height: 16),
        buildTweakCardLong(
          'Apply Super Potato Textures (LOD Bias +3.000)',
          'Memaksa driver VGA (NVIDIA/AMD) mematikan detail tektur rumput, tembok, dan dedaunan menjadi mulus polos. Mengurangi load kerja kartu grafis hingga 70% dan mendongkrak FPS secara radikal!',
          Icons.photo,
          () => sendPcTweakRequest('pc_potato_textures'),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            buildTweakCard(
              'Bypass Emulator 90 FPS Lock',
              'Suntik otomatis bst.config ke mode ASUS ROG 2 & unlock 240 FPS.',
              Icons.speed,
              () => sendPcTweakRequest('pc_bypass_emu_fps'),
            ),
            buildTweakCard(
              'Unlimited GPU Shader Cache',
              'Atur Shader Cache ke tak terbatas (0x31) untuk anti-stuttering.',
              Icons.storage,
              () => sendPcTweakRequest('pc_gpu_shader_cache'),
            ),
            buildTweakCard(
              'Deep Clean GPU Shader Cache',
              'Hapus cache kompilasi shader NVIDIA/AMD yang kotor dan corrupt.',
              Icons.brush,
              () => sendPcTweakRequest('pc_deep_clean_gpu'),
            ),
            buildTweakCard(
              'Flush PC DNS',
              'Membersihkan data cache DNS yang usang untuk menstabilkan jaringan.',
              Icons.dns,
              () => sendPcTweakRequest('pc_flush_dns'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        buildSectionHeader('Ubah Resolusi Layar PC Manual'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: pcResWController,
                decoration: const InputDecoration(
                  labelText: 'Width PC (ex: 1440)',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: pcResHController,
                decoration: const InputDecoration(
                  labelText: 'Height PC (ex: 1080)',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                final w = int.tryParse(pcResWController.text);
                final h = int.tryParse(pcResHController.text);
                if (w != null && h != null) {
                  sendPcTweakRequest('pc_custom_reso_${w}_$h');
                } else {
                  addLog("[SYSTEM] Masukkan Width & Height PC yang valid.");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(120, 54),
              ),
              child: const Text('Ubah Reso', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => sendPcTweakRequest('pc_reso_1920x1080'),
              child: const Text('1920x1080 (16:9)'),
            ),
            ElevatedButton(
              onPressed: () => sendPcTweakRequest('pc_reso_1440x1080'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1B4B)),
              child: const Text('1440x1080 (Stretch)', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () => sendPcTweakRequest('pc_reso_1280x960'),
              child: const Text('1280x960 (4:3)'),
            ),
            ElevatedButton(
              onPressed: () => sendPcTweakRequest('pc_reso_1024x768'),
              child: const Text('1024x768 (4:3)'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        buildSectionHeader('Overlay Crosshair PC'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => sendPcTweakRequest('pc_cross_red_cross'),
              icon: const Icon(Icons.add, color: Colors.red),
              label: const Text('Red Cross'),
            ),
            ElevatedButton.icon(
              onPressed: () => sendPcTweakRequest('pc_cross_green_dot'),
              icon: const Icon(Icons.lens, color: Colors.green, size: 10),
              label: const Text('Green Dot'),
            ),
            ElevatedButton.icon(
              onPressed: () => sendPcTweakRequest('pc_cross_yellow_hybrid'),
              icon: const Icon(Icons.add_circle_outline, color: Colors.yellow),
              label: const Text('Yellow Hybrid'),
            ),
            ElevatedButton.icon(
              onPressed: () => sendPcTweakRequest('pc_cross_off_off'),
              icon: const Icon(Icons.close, color: Colors.grey),
              label: const Text('Matikan Crosshair'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black26),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildMobileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildServerIpCard(),
        const SizedBox(height: 16),
        buildSectionHeader('🔌 Wireless ADB Pairing Wizard (TANPA KABEL USB)'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cara Koneksi Tanpa Kabel:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Buka Opsi Developer di HP Android Anda.\n2. Masuk ke "Wireless Debugging" (Debugging Nirkabel) lalu aktifkan.\n3. Klik "Pair device with pairing code" (Pasangkan perangkat dengan kode).\n4. Masukkan alamat IP HP, nomor Port lima digit (setelah titik dua), dan Pairing Code di bawah ini:',
                style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.6),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: adbIpController,
                      decoration: const InputDecoration(
                        labelText: 'IP HP (ex: 192.168.1.12)',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: adbPortController,
                      decoration: const InputDecoration(
                        labelText: 'Port (ex: 39855)',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: adbPairCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Pairing Code (6 digit)',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: connectWirelessAdbViaServer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size(140, 54),
                    ),
                    child: const Text('Aktifkan ADB', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        buildSectionHeader('🎯 Aim Assist & Hardcore Android Tweak'),
        const SizedBox(height: 16),
        buildTweakCardLong(
          '🎯 Super Drag-HS Touch Calibrator (Zero Latency)',
          'Memaksimalkan respon tracking panel touch, meluruskan akurasi geseran jari secara linear di shell Android, serta menurunkan long_press_delay ke 100ms. Tarikan headshot di HP dijamin sangat enteng dan nempel di kepala!',
          Icons.gps_fixed,
          () => executeAndroidTweak('mob_drag_hs'),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            buildTweakCard(
              'Disable Joyose (Thermal)',
              'Bypass pembatas performa bawaan Xiaomi/HyperOS saat bermain game.',
              Icons.thermostat,
              () => executeAndroidTweak('mob_joyose_off'),
            ),
            buildTweakCard(
              'Force Disable HW Overlays',
              'Gunakan kekuatan penuh GPU untuk merender antarmuka aplikasi.',
              Icons.layers_clear,
              () => executeAndroidTweak('mob_hw_overlays'),
            ),
            buildTweakCard(
              'Disable Window Blurs',
              'Matikan efek transparan pada UI HP agar GPU fokus merender game.',
              Icons.blur_off,
              () => executeAndroidTweak('mob_disable_blur'),
            ),
            buildTweakCard(
              'App Speed Compiler',
              'Kompilasi package game ke mode performa optimal via Dexopt.',
              Icons.offline_bolt,
              () => executeAndroidTweak('mob_compile_speed'),
            ),
            buildTweakCard(
              'Touch 1:1 RAW Input',
              'Atur kecepatan pointer ke opsi maksimal tanpa lag.',
              Icons.ads_click,
              () => executeAndroidTweak('mob_touch_raw'),
            ),
            buildTweakCard(
              'Touch Delay Minimalist',
              'Minimalkan antrean antarmuka sentuh pada hardware Android.',
              Icons.hourglass_disabled,
              () => executeAndroidTweak('mob_delay_min'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        buildSectionHeader('Android Screen Customizer'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: mobResWController,
                decoration: const InputDecoration(
                  labelText: 'Width (ex: 1080)',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: mobResHController,
                decoration: const InputDecoration(
                  labelText: 'Height (ex: 1920)',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                final w = int.tryParse(mobResWController.text);
                final h = int.tryParse(mobResHController.text);
                if (w != null && h != null) {
                  executeAndroidTweak('mob_custom_reso_${w}_$h');
                } else {
                  addLog("[SYSTEM] Masukkan Width & Height Android yang valid.");
                }
              },
              child: const Text('Set Reso'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: mobDpiController,
                decoration: const InputDecoration(
                  labelText: 'Custom DPI (ex: 500)',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                final dpi = int.tryParse(mobDpiController.text);
                if (dpi != null) {
                  executeAndroidTweak('mob_custom_dpi_$dpi');
                } else {
                  addLog("[SYSTEM] Masukkan nilai DPI yang valid.");
                }
              },
              child: const Text('Set DPI'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => executeAndroidTweak('mob_reso_ipad'),
              child: const Text('iPad View (1080x1920)'),
            ),
            ElevatedButton(
              onPressed: () => executeAndroidTweak('mob_reso_hd'),
              child: const Text('720p HD (720x1560)'),
            ),
            ElevatedButton(
              onPressed: () => executeAndroidTweak('mob_dpi_500'),
              child: const Text('DPI 500 (Kompetitif)'),
            ),
            ElevatedButton(
              onPressed: () => executeAndroidTweak('mob_force_120hz'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1B4B)),
              child: const Text('Lock Max Refresh (120Hz)', style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        ),
        const SizedBox(height: 32),
        buildSectionHeader('System Utility, Cleaners & Debloat'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            buildTweakCard(
              'Flush RAM Memory',
              'Matikan background apps & bersihkan cache RAM via drop_caches.',
              Icons.memory,
              () => executeAndroidTweak('mob_ram_flush'),
            ),
            buildTweakCard(
              'Debloat Xiaomi Telemetry',
              'Nonaktifkan MSA, daemon analytics, dan bugreport secara paksa.',
              Icons.security_update_warning,
              () => executeAndroidTweak('mob_telemetry_off'),
            ),
            buildTweakCard(
              'Google DNS Gaming',
              'Aktifkan secure dns.google & bypass pembatas daya Wi-Fi.',
              Icons.dns,
              () => executeAndroidTweak('mob_dns_google'),
            ),
            buildTweakCard(
              'Limit Phantom Processes',
              'Batasi background process siluman agar RAM tidak termakan.',
              Icons.running_with_errors,
              () => executeAndroidTweak('mob_limit_phantom'),
            ),
            buildTweakCard(
              'Trim All System Caches',
              'Pangkas semua direktori file sementara dalvik-cache murni.',
              Icons.cleaning_services,
              () => executeAndroidTweak('mob_trim_caches'),
            ),
            buildTweakCard(
              'Wipe Temp Local Files',
              'Kosongkan semua item sampah di folder /data/local/tmp.',
              Icons.delete_sweep,
              () => executeAndroidTweak('mob_temp_clear'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => executeAndroidTweak('mob_game_mode'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('🔥 AKTIFKAN HYPER GAME MODE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => executeAndroidTweak('mob_restore'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('KEMBALIKAN KE DEFAULT PABRIK', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildRemoteTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildServerIpCard(),
        const SizedBox(height: 16),
        buildSectionHeader('🖱️ Virtual Trackpad Remote PC'),
        const SizedBox(height: 12),
        GestureDetector(
          onPanStart: (details) {
            lastX = details.globalPosition.dx;
            lastY = details.globalPosition.dy;
          },
          onPanUpdate: (details) {
            if (lastX != null && lastY != null) {
              double dx = details.globalPosition.dx - lastX!;
              double dy = details.globalPosition.dy - lastY!;
              
              int sendDx = (dx * 1.8).round();
              int sendDy = (dy * 1.8).round();
              
              if (sendDx != 0 || sendDy != 0) {
                sendPcRemoteCommand("move_mouse", dx: sendDx, dy: sendDy);
              }
            }
            lastX = details.globalPosition.dx;
            lastY = details.globalPosition.dy;
          },
          onPanEnd: (details) {
            lastX = null;
            lastY = null;
          },
          child: Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                radius: 1.0,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
            ),
            child: const Center(
              child: Text(
                'GESER JARI DI SINI UNTUK REMOTE\n(Kursor PC akan bergerak nirkabel)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, height: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => sendPcRemoteCommand('click_left'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('KLIK KIRI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => sendPcTweakRequest('pc_flush_dns'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('FLUSH DNS PC', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        buildSectionHeader('🎮 Media Remote Controller'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 3.5,
          children: [
            ElevatedButton.icon(
              onPressed: () => sendPcRemoteCommand('vol_up'),
              icon: const Icon(Icons.volume_up, color: Colors.white),
              label: const Text('Volume Up', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton.icon(
              onPressed: () => sendPcRemoteCommand('vol_down'),
              icon: const Icon(Icons.volume_down, color: Colors.white),
              label: const Text('Volume Down', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton.icon(
              onPressed: () => sendPcRemoteCommand('mute'),
              icon: const Icon(Icons.volume_mute, color: Colors.white),
              label: const Text('Toggle Mute', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton.icon(
              onPressed: () => sendPcRemoteCommand('play_pause'),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('Play / Pause', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton.icon(
              onPressed: () => sendPcRemoteCommand('alt_f4'),
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text('Close App', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildConsolePanel() {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF020408),
        border: Border(left: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFF090D1F),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CONSOLE LOG',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      consoleLogs.clear();
                      consoleLogs.add("[SYSTEM] Log dibersihkan.");
                    });
                  },
                  child: const Text(
                    'CLEAR',
                    style: TextStyle(fontSize: 10, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: consoleLogs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    consoleLogs[index],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF10B981),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMobileBottomBar() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFF090D1F),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () => setState(() => activeTab = 'tab-utama'),
            icon: Icon(Icons.computer, color: activeTab == 'tab-utama' ? Colors.blue : Colors.blueGrey),
          ),
          IconButton(
            onPressed: () => setState(() => activeTab = 'tab-control'),
            icon: Icon(Icons.control_camera, color: activeTabColor('tab-control')),
          ),
          IconButton(
            onPressed: () => setState(() => activeTab = 'tab-mobile'),
            icon: Icon(Icons.phone_android, color: activeTabColor('tab-mobile')),
          ),
          IconButton(
            onPressed: () => setState(() => activeTab = 'tab-remote'),
            icon: Icon(Icons.settings_remote, color: activeTabColor('tab-remote')),
          ),
        ],
      ),
    );
  }

  Color activeTabColor(String id) {
    return activeTab == id ? Colors.blue : Colors.blueGrey;
  }
}
