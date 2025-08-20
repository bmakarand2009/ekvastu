import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';

class CompassService extends ChangeNotifier {
  double _heading = 0;
  bool _hasPermission = false;
  bool _isCalibrating = false;
  bool _isInitializing = true;
  String _errorMessage = '';
  StreamSubscription<CompassEvent>? _compassSubscription;
  
  double get heading => _heading;
  bool get hasPermission => _hasPermission;
  bool get isCalibrating => _isCalibrating;
  bool get isInitializing => _isInitializing;
  String get errorMessage => _errorMessage;

  CompassService() {
    _init();
  }

  void _init() async {
    try {
      _isInitializing = true;
      notifyListeners();
      
      // Handle permissions first on iOS
      if (Platform.isIOS) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            _errorMessage = 'Location permissions are denied';
            _hasPermission = false;
            _isInitializing = false;
            notifyListeners();
            return;
          }
        }
        
        if (permission == LocationPermission.deniedForever) {
          _errorMessage = 'Location permissions are permanently denied';
          _hasPermission = false;
          _isInitializing = false;
          notifyListeners();
          return;
        }
      }
      
      if (FlutterCompass.events == null) {
        _errorMessage = 'Compass not available on this device';
        _hasPermission = false;
        _isInitializing = false;
        notifyListeners();
        return;
      }

      _hasPermission = true;
      _errorMessage = '';
      _compassSubscription = FlutterCompass.events!.listen(
        (event) {
          if (event.heading != null) {
            _heading = event.heading!;
            _isInitializing = false;
            notifyListeners();
          }
        },
        onError: (error) {
          _errorMessage = 'Compass error: $error';
          _isInitializing = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to initialize compass: $e';
      _isInitializing = false;
      notifyListeners();
    }
  }

  String getDirectionText() {
    const List<String> directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    int index = ((_heading + 22.5) % 360 / 45).floor();
    return directions[index % 8];
  }
  
  String getVastuDirection() {
    // In Vastu, East is particularly important
    if (_heading >= 67.5 && _heading < 112.5) return 'East (Auspicious)';
    if (_heading >= 157.5 && _heading < 202.5) return 'South (Heat/Energy)';
    if (_heading >= 247.5 && _heading < 292.5) return 'West (Moderate)';
    if (_heading >= 337.5 || _heading < 22.5) return 'North (Wealth/Prosperity)';
    if (_heading >= 22.5 && _heading < 67.5) return 'North-East (Highly Auspicious)';
    if (_heading >= 112.5 && _heading < 157.5) return 'South-East (Fire Element)';
    if (_heading >= 202.5 && _heading < 247.5) return 'South-West (Stability)';
    return 'North-West (Air Element)';
  }

  void calibrateCompass() {
    _isCalibrating = true;
    notifyListeners();
    
    // Simulate calibration process
    Future.delayed(const Duration(seconds: 3), () {
      _isCalibrating = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }
}
