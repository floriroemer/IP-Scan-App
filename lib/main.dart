import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:lan_scanner/lan_scanner.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const IPScannerApp());
}

class IPScannerApp extends StatelessWidget {
  const IPScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RMR IP Scan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        primaryColor: Colors.tealAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.cyanAccent,
          surface: Color(0xFF1E293B), // Slate 800
        ),
        textTheme: GoogleFonts.firaSansTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const ScannerHomePage(),
    );
  }
}

class ScannerHomePage extends StatefulWidget {
  const ScannerHomePage({super.key});

  @override
  State<ScannerHomePage> createState() => _ScannerHomePageState();
}

class _ScannerHomePageState extends State<ScannerHomePage> {
  final List<HostModel> _hosts = [];
  bool _isScanning = false;
  double _progress = 0.0;
  String? _localIp;
  String? _errorMessage;

  Future<void> _startScan() async {
    setState(() {
      _hosts.clear();
      _isScanning = true;
      _progress = 0.0;
      _errorMessage = null;
    });

    try {
      final info = NetworkInfo();
      // On modern Android/iOS, this might require Location permissions to work properly
      final wifiIP = await info.getWifiIP();
      
      if (wifiIP == null) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Could not determine Wi-Fi IP.\nMake sure you are connected to a network\nand granted Location permissions.';
        });
        return;
      }

      setState(() {
        _localIp = wifiIP;
      });

      final scanner = LanScanner();
      final String subnet = ipToCSubnet(wifiIP);

      final stream = scanner.icmpScan(
        subnet,
        progressCallback: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      stream.listen((HostModel host) {
        setState(() {
          if (host.isReachable && !_hosts.any((h) => h.ip == host.ip)) {
            _hosts.add(host);
          }
        });
      }, onDone: () {
        setState(() {
          _isScanning = false;
        });
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RMR IP Scan', style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent))),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: _hosts.isEmpty && !_isScanning
                  ? Center(
                      child: Text(
                        _errorMessage != null ? '' : 'Tap the button below to start scanning',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _hosts.length,
                      itemBuilder: (context, index) {
                        return _buildDeviceCard(_hosts[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? null : _startScan,
        icon: _isScanning
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black87,
                ),
              )
            : const Icon(Icons.radar, color: Colors.black87),
        label: Text(
          _isScanning ? 'Scanning...' : 'Scan Network',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.tealAccent,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.tealAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi, color: Colors.tealAccent.withOpacity(0.8), size: 20),
              const SizedBox(width: 8),
              Text(
                'NETWORK STATUS',
                style: GoogleFonts.firaCode(
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _localIp != null ? 'Your IP: $_localIp' : 'Awaiting initialization...',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_isScanning) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey.shade800,
                color: Colors.cyanAccent,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toStringAsFixed(1)}% Complete',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              textAlign: TextAlign.right,
            )
          ] else if (_hosts.isNotEmpty) ...[
            Text(
              'Found ${_hosts.length} devices',
              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w500),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDeviceCard(HostModel host) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.cyanAccent.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.devices, color: Colors.cyanAccent),
        ),
        title: Text(
          host.ip,
          style: GoogleFonts.firaCode(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Online',
                style: TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
