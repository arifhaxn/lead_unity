import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkOverlay extends StatefulWidget {
  final Widget child;

  const NetworkOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<NetworkOverlay> createState() => _NetworkOverlayState();
}

class _NetworkOverlayState extends State<NetworkOverlay> {
  bool _hasInternet = true;
  bool _showBanner = false;
  bool _isFirstCheck = true;
  Timer? _hideTimer;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!mounted) return;
      
      bool isConnected = !results.contains(ConnectivityResult.none);

      // Prevent the "Back online" banner from showing on a fresh app launch
      if (_isFirstCheck) {
        _isFirstCheck = false;
        _hasInternet = isConnected;
        if (!isConnected) {
          _triggerBanner();
        }
        return;
      }

      // If the state actually changed, trigger the banner
      if (isConnected != _hasInternet) {
        setState(() {
          _hasInternet = isConnected;
        });
        _triggerBanner();
      }
    });
  }

  void _triggerBanner() {
    setState(() {
      _showBanner = true;
    });
    
    _hideTimer?.cancel();
    // 🟢 Changed to 2 seconds (2000 milliseconds)
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showBanner = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the top safe area (notch/status bar height) so it floats just below it
    final double topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // 1. The main app content
        widget.child,

        // 2. The sleek, auto-hiding pill banner
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          // Slides down slightly below the notch/status bar, or hides far above
          top: _showBanner ? topPadding + 10 : -100,
          left: 0,
          right: 0,
          child: IgnorePointer( // Ensures the banner doesn't block taps underneath it
            child: Material(
              color: Colors.transparent,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    // Deep red for offline, crisp green for online
                    color: _hasInternet ? const Color(0xFF10B981) : Colors.redAccent.shade700,
                    borderRadius: BorderRadius.circular(30), // Sleek pill shape
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Keeps the pill wrapped tightly around text
                    children: [
                      Icon(
                        _hasInternet ? Icons.wifi_rounded : Icons.wifi_off_rounded, 
                        color: Colors.white, 
                        size: 16
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _hasInternet ? "Back online" : "No internet connection",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}