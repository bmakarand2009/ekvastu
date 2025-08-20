import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vvp_app/services/compass_service.dart';

class CompassScreen extends StatefulWidget {
  const CompassScreen({Key? key}) : super(key: key);

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showVastuInfo = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompassService>(
      builder: (context, compassService, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Direction Compass'),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: compassService.isInitializing ? null : () {
                  compassService.calibrateCompass();
                  _animationController.forward(from: 0.0);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Calibrating compass...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(_showVastuInfo ? Icons.info_outline : Icons.info),
                onPressed: () {
                  setState(() {
                    _showVastuInfo = !_showVastuInfo;
                  });
                },
              ),
            ],
          ),
          body: _buildBody(compassService),
        );
      },
    );
  }
  
  Widget _buildBody(CompassService compassService) {
    // Handle initializing state
    if (compassService.isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing compass...'),
          ],
        ),
      );
    }
    
    // Handle error state
    if (compassService.errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Compass Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                compassService.errorMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Force a reload/reinit of the compass service
                Provider.of<CompassService>(context, listen: false).calibrateCompass();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // Handle permission denied state
    if (!compassService.hasPermission) {
      return _buildPermissionDenied();
    }
    
    // Handle normal state with permissions granted
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: _buildCompass(compassService),
          ),
          if (_showVastuInfo) ...[                        
            const SizedBox(height: 16),
            _buildVastuInfo(compassService),
          ],
        ],
      ),
    );
  }

  Widget _buildCompass(CompassService compassService) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Point your device in the direction you want to check',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer compass circle
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            
            // Compass direction indicators
            SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(
                painter: CompassPainter(),
              ),
            ),
            
            // Rotating compass needle
            Transform.rotate(
              angle: (compassService.heading * (math.pi / 180) * -1),
              child: Container(
                width: 220,
                height: 220,
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // North pointer (red)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 8,
                        height: 100,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.red, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // South pointer (gray)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 8,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.grey.shade400, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore, size: 24),
            const SizedBox(width: 8),
            Text(
              '${compassService.heading.toStringAsFixed(1)}° ${compassService.getDirectionText()}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          compassService.getVastuDirection(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (compassService.isCalibrating)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: Tween(begin: 0.0, end: 1.0)
                    .animate(_animationController..repeat()),
                child: const Icon(Icons.sync, size: 20),
              ),
              const SizedBox(width: 8),
              const Text('Calibrating...'),
            ],
          ),
      ],
    );
  }

  Widget _buildVastuInfo(CompassService compassService) {
    final direction = compassService.getDirectionText();
    String directionInfo;
    
    // Get Vastu info based on direction
    switch (direction) {
      case 'N':
        directionInfo = 'North: Associated with wealth and prosperity. Good for bedroom, study, or office.';
        break;
      case 'NE':
        directionInfo = 'North-East: Most auspicious direction. Ideal for prayer room, meditation space.';
        break;
      case 'E':
        directionInfo = 'East: Brings positive energy and health. Good for living rooms and entrances.';
        break;
      case 'SE':
        directionInfo = 'South-East: Fire element. Ideal for kitchen and activities.';
        break;
      case 'S':
        directionInfo = 'South: Strong energy, can be intense. Suitable for storage, bathrooms.';
        break;
      case 'SW':
        directionInfo = 'South-West: Represents stability. Good for master bedroom.';
        break;
      case 'W':
        directionInfo = 'West: Moderate energy. Suitable for dining, bedrooms.';
        break;
      case 'NW':
        directionInfo = 'North-West: Good for guest rooms and children\'s rooms.';
        break;
      default:
        directionInfo = 'Checking direction...';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Vastu Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            directionInfo,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Check Room in This Direction'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/room_check');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_disabled,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Compass Access Required',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This app needs access to your device\'s compass and location sensors to show directions. Please grant the required permissions in your device settings.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: () {
                // Force a reload of the compass service by triggering calibration
                Provider.of<CompassService>(context, listen: false).calibrateCompass();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw circle
    canvas.drawCircle(center, radius, paint);
    
    // Draw cross lines
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    
    // Draw diagonal lines
    canvas.drawLine(
      Offset(center.dx - radius * 0.7, center.dy - radius * 0.7),
      Offset(center.dx + radius * 0.7, center.dy + radius * 0.7),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.7, center.dy + radius * 0.7),
      Offset(center.dx + radius * 0.7, center.dy - radius * 0.7),
      paint,
    );
    
    // Draw direction texts
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    void drawText(String text, double angle) {
      textPainter.text = TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      
      textPainter.layout();
      
      final dx = radius * math.cos(angle) + center.dx - textPainter.width / 2;
      final dy = radius * math.sin(angle) + center.dy - textPainter.height / 2;
      
      textPainter.paint(canvas, Offset(dx, dy));
    }
    
    // Draw cardinal directions
    drawText('N', -math.pi / 2);
    drawText('E', 0);
    drawText('S', math.pi / 2);
    drawText('W', math.pi);
    
    // Draw ordinal directions
    drawText('NE', -math.pi / 4);
    drawText('SE', math.pi / 4);
    drawText('SW', 3 * math.pi / 4);
    drawText('NW', -3 * math.pi / 4);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
