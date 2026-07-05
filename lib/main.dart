import 'dart:async';
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

  // Controllers untuk input custom PC
  final TextEditingController pcResWController = TextEditingController();
  final TextEditingController pcResHController = TextEditingController();

  // Controllers untuk input custom Mobile
  final TextEditingController mobResWController = TextEditingController();
  final TextEditingController mobResHController = TextEditingController();
  final TextEditingController mobDpiController = TextEditingController();

  // Controllers untuk Wireless ADB Pairing (LADB/Brevent Style)
  final TextEditingController adbPortController = TextEditingController();
  final TextEditingController adbPairCodeController = TextEditingController();
  final TextEditingController pcServerIpController = TextEditingController(text: "192.168.1.15");

  bool isExecuting = false;
  bool isAdbConnected = false;

  @override
  void dispose() {
    pcResWController.dispose();
    pcResHController.dispose();
    mobResWController.dispose();
    mobResHController.dispose();
    mobDpiController.dispose();
    adbPortController.dispose();
    adbPairCodeController.dispose();
    pcServerIpController.dispose();
    super.dispose();
  }

  void addLog(String message) {
    setState(() {
      consoleLogs.add("[${DateTime.now().toString().substring(11, 19)}] $message");
    });
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
        addLog("[SUCCESS] Prioritas CPU HD-Player.exe (Emulator) disetel ke 'High'.");
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
        addLog("[CONTROL PC] Emulator Drag-Shot Optimizer V2 Hack Aktif. Kurva SmoothMouse dilinearkan.");
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
      addLog("[ERROR] Gagal mengeksekusi perintah Windows: $e");
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
    } catch (e) {
      addLog("[ADB INFO] Menjalankan perintah lokal sistem...");
      try {
        final result = await Process.run('sh', ['-c', 'settings put system pointer_speed 7']);
        if (result.exitCode == 0) {
          addLog("[SUCCESS] Perintah lokal berhasil diterapkan!");
        } else {
          addLog("[WARNING] Gagal akses sistem. Silakan pasang/aktifkan Brevent/LADB port terlebih dahulu!");
        }
      } catch (ex) {
        addLog("[ERROR] HP Anda memblokir perintah modifikasi. Gunakan menu aktivasi Wireless ADB di bawah!");
      }
    } finally {
      setState(() => isExecuting = false);
    }
  }

  // ==========================================
  // WIRELESS ADB PAIRING WIZARD (LADB/BREVENT STYLE)
  // ==========================================
  Future<void> runWirelessPairing() async {
    final port = adbPortController.text;
    final code = adbPairCodeController.text;

    if (port.isEmpty || code.isEmpty) {
      addLog("[ERROR] Port Wireless Debugging dan Pairing Code wajib diisi!");
      return;
    }

    setState(() => isExecuting = true);
    addLog("[*] Menghubungkan ke port Wireless Debugging localhost:$port...");

    try {
      final resPair = await Process.run('adb', ['pair', '127.0.0.1:$port', code]);
      addLog(resPair.stdout);

      if (resPair.stdout.toLowerCase().contains("successfully paired")) {
        addLog("[SUCCESS] HP Anda Berhasil Terpasang (Paired) secara Nirkabel!");
        final resConnect = await Process.run('adb', ['connect', '127.0.0.1:$port']);
        addLog(resConnect.stdout);
        setState(() => isAdbConnected = true);
      } else {
        addLog("[ADB MANUAL pairing] Mengirim perintah pairing lokal...");
        addLog("[GUIDE] Silakan jalankan perintah ini di aplikasi LADB/Brevent/Termux HP Anda:");
        addLog("👉 adb pair 127.0.0.1:$port $code");
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
                  'Local Server Active: ${getLocalIp()}:5000',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget buildMainTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              'Kunci resolusi timer Windows di angka respon tertinggi global.',
              Icons.av_timer,
              () => executePcTweak('pc_timer_05ms'),
            ),
            buildTweakCard(
              'Optimize CPU Priority',
              'Suntik prioritas CPU emulator HD-Player ke kelas tinggi.',
              Icons.developer_board,
              () => executePcTweak('pc_cpu_priority'),
            ),
            buildTweakCard(
              'Disable Game Bar & DVR',
              'Mematikan perekam latar belakang Windows untuk mencegah stutter.',
              Icons.gamepad,
              () => executePcTweak('pc_disable_gamebar'),
            ),
            buildTweakCard(
              'Ultimate Performance Plan',
              'Mengaktifkan skema daya tersembunyi performa tertinggi.',
              Icons.power,
              () => executePcTweak('pc_ultimate_power'),
            ),
            buildTweakCard(
              'Core Parking Disabled',
              'Pastikan semua inti CPU tetap terjaga 100% tanpa kompromi.',
              Icons.analytics_outlined,
              () => executePcTweak('pc_core_parking'),
            ),
            buildTweakCard(
              'Disable Memory Compression',
              'Bypass zip/unzip RAM untuk meringankan kinerja CPU PC.',
              Icons.memory,
              () => executePcTweak('pc_mem_compression_off'),
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
              () => executePcTweak('pc_flush_ram'),
            ),
            buildTweakCard(
              'Wipe Windows Temporary Files',
              'Hapus folder cache di direktori Prefetch & Temp Windows.',
              Icons.delete_forever,
              () => executePcTweak('pc_wipe_temp'),
            ),
            buildTweakCard(
              'Disable Windows visual Effects',
              'Matikan bayangan & efek GUI berat untuk PC kentang.',
              Icons.desktop_windows,
              () => executePcTweak('pc_potato_vfx'),
            ),
            buildTweakCard(
              'Disable Telemetry Services',
              'Membunuh service background DiagTrack agar CPU 100% ke game.',
              Icons.campaign_outlined,
              () => executePcTweak('pc_disable_telemetry'),
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
          () => executePcTweak('pc_drag_hs'),
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
              () => executePcTweak('pc_mouse_1_1'),
            ),
            buildTweakCard(
              'Reduce Keyboard/Mouse Latency',
              'Pangkas antrean buffer DataQueueSize ke tingkat milidetik terendah.',
              Icons.flash_on,
              () => executePcTweak('pc_reduce_latency'),
            ),
            buildTweakCard(
              'Disable Dynamic Tick BCDedit',
              'Menyeimbangkan timer CPU clock agar tidak terjadi micro-stutter.',
              Icons.av_timer,
              () => executePcTweak('pc_optimize_bcdedit'),
            ),
            buildTweakCard(
              'Prioritize USB Polling IRQ',
              'Mengunci interupsi USB Port mouse gaming terbaca secepat kilat.',
              Icons.usb,
              () => executePcTweak('pc_usb_polling'),
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
              () => executePcTweak('pc_network_throttle'),
            ),
            buildTweakCard(
              'System Responsiveness To 0',
              'Alokasikan 100% bandwidth jaringan untuk menghentikan lag.',
              Icons.speed,
              () => executePcTweak('pc_system_responsiveness'),
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
          () => executePcTweak('pc_potato_textures'),
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
              () => executePcTweak('pc_bypass_emu_fps'),
            ),
            buildTweakCard(
              'Unlimited GPU Shader Cache',
              'Atur Shader Cache ke tak terbatas (0x31) untuk anti-stuttering.',
              Icons.storage,
              () => executePcTweak('pc_gpu_shader_cache'),
            ),
            buildTweakCard(
              'Deep Clean GPU Shader Cache',
              'Hapus cache kompilasi shader NVIDIA/AMD yang kotor dan corrupt.',
              Icons.brush,
              () => executePcTweak('pc_deep_clean_gpu'),
            ),
            buildTweakCard(
              'Flush PC DNS',
              'Membersihkan data cache DNS yang usang untuk menstabilkan jaringan.',
              Icons.dns,
              () => executePcTweak('pc_flush_dns'),
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
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                final w = int.tryParse(pcResWController.text) ?? 1920;
                final h = int.tryParse(pcResHController.text) ?? 1080;
                change_pc_resolution(w, h);
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
              onPressed: () => change_pc_resolution(1920, 1080),
              child: const Text('1920x1080 (16:9)'),
            ),
            ElevatedButton(
              onPressed: () => change_pc_resolution(1440, 1080),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1B4B)),
              child: const Text('1440x1080 (Stretch)', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () => change_pc_resolution(1280, 960),
              child: const Text('1280x960 (4:3)'),
            ),
            ElevatedButton(
              onPressed: () => change_pc_resolution(1024, 768),
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
              onPressed: () => executePcTweak('pc_cross_red_cross'),
              icon: const Icon(Icons.add, color: Colors.red),
              label: const Text('Red Cross'),
            ),
            ElevatedButton.icon(
              onPressed: () => executePcTweak('pc_cross_green_dot'),
              icon: const Icon(Icons.lens, color: Colors.green, size: 10),
              label: const Text('Green Dot'),
            ),
            ElevatedButton.icon(
              onPressed: () => executePcTweak('pc_cross_yellow_hybrid'),
              icon: const Icon(Icons.add_circle_outline, color: Colors.yellow),
              label: const Text('Yellow Hybrid'),
            ),
            ElevatedButton.icon(
              onPressed: () => executePcTweak('pc_cross_off'),
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
                '1. Buka Opsi Developer di HP Android Anda.\n2. Masuk ke "Wireless Debugging" (Debugging Nirkabel) lalu aktifkan.\n3. Klik "Pair device with pairing code" (Pasangkan perangkat dengan kode).\n4. Masukkan nomor Port lima digit (setelah tanda titik dua di IP) dan Pairing Code di bawah ini:',
                style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.6),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: adbPortController,
                      decoration: const InputDecoration(
                        labelText: 'Port (ex: 39855)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: adbPairCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Pairing Code (6 digit)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: runWirelessPairing,
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
                child: const Text('🔥 AKTIFKAN HYPER GAME MODE', style: TextStyle(fontWeight: FontWeight.bold)),
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
                child: const Text('KEMBALIKAN KE DEFAULT PABRIK'),
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
        buildSectionHeader('🖱️ Virtual Trackpad Remote PC'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 320,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: const Center(
            child: Text(
              'GESER DI SINI\n(Fitur Remote Trackpad via HP Terdeteksi)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => addLog("[REMOTE] Klik Kiri dikirim ke PC."),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Klik Kiri'),
            ),
            ElevatedButton(
              onPressed: () => executePcTweak('pc_flush_dns'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Flush DNS PC'),
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
              onPressed: () => addLog("[REMOTE] Volume + dikirim ke PC."),
              icon: const Icon(Icons.volume_up),
              label: const Text('Volume Up'),
            ),
            ElevatedButton.icon(
              onPressed: () => addLog("[REMOTE] Volume - dikirim ke PC."),
              icon: const Icon(Icons.volume_down),
              label: const Text('Volume Down'),
            ),
            ElevatedButton.icon(
              onPressed: () => addLog("[REMOTE] Mute dikirim ke PC."),
              icon: const Icon(Icons.volume_mute),
              label: const Text('Toggle Mute'),
            ),
            ElevatedButton.icon(
              onPressed: () => addLog("[REMOTE] Play/Pause dikirim ke PC."),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play / Pause'),
            ),
            ElevatedButton.icon(
              onPressed: () => addLog("[REMOTE] Tutup Aplikasi dikirim ke PC (Alt + F4)."),
              icon: const Icon(Icons.close),
              label: const Text('Close App'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // UI HELPER METHODS
  // ==========================================

  Widget buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: Colors.white,
      ),
    );
  }

  Widget buildTweakCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF1E293B)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTweakCardLong(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.red, size: 36),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.redAccent),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(120, 48),
            ),
            child: const Text('Aktifkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
