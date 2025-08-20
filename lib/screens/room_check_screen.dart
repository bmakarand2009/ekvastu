import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vvp_app/models/room.dart';
import 'package:vvp_app/services/compass_service.dart';
import 'package:vvp_app/services/vastu_service.dart';
import 'package:vvp_app/screens/room_result_screen.dart';

class RoomCheckScreen extends StatefulWidget {
  const RoomCheckScreen({Key? key}) : super(key: key);

  @override
  State<RoomCheckScreen> createState() => _RoomCheckScreenState();
}

class _RoomCheckScreenState extends State<RoomCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRoomType = '';
  String _selectedDirection = '';
  bool _useCompass = false;
  
  @override
  Widget build(BuildContext context) {
    final compassService = Provider.of<CompassService>(context);
    final vastuService = Provider.of<VastuService>(context);
    
    if (_useCompass) {
      _selectedDirection = compassService.getDirectionText();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Check Wizard'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Room Type Selection
              Text(
                'Step 1: Select Room Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    isExpanded: true,
                    hint: const Text('Select Room Type'),
                    value: _selectedRoomType.isEmpty ? null : _selectedRoomType,
                    items: vastuService.roomTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRoomType = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a room type';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Direction Selection
              Text(
                'Step 2: Select Direction',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              
              // Use compass toggle
              SwitchListTile(
                title: const Text('Use device compass'),
                subtitle: const Text('Automatically detect the direction'),
                value: _useCompass,
                onChanged: (value) {
                  setState(() {
                    _useCompass = value;
                  });
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              ),
              
              if (!_useCompass)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      isExpanded: true,
                      hint: const Text('Select Direction'),
                      value: _selectedDirection.isEmpty ? null : _selectedDirection,
                      items: ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'].map((direction) {
                        return DropdownMenuItem<String>(
                          value: direction,
                          child: Text(_getDirectionName(direction)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDirection = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a direction';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              
              if (_useCompass) ...[
                const SizedBox(height: 16),
                _buildCompassDirection(compassService),
              ],
              
              const SizedBox(height: 32),
              
              // Check button
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Check Room Compatibility'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _checkRoom(context);
                  }
                },
              ),
              
              const SizedBox(height: 24),
              
              // Guide card
              _buildGuideCard(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCompassDirection(CompassService compassService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.explore,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Current Direction',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${compassService.heading.toStringAsFixed(1)}° ${compassService.getDirectionText()}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            Text(
              _getDirectionName(compassService.getDirectionText()),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              child: const Text('Recalibrate Compass'),
              onPressed: () {
                compassService.calibrateCompass();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calibrating compass...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGuideCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to use the Room Check Wizard',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Select the room type you want to evaluate.\n'
            '2. Either use your device compass or manually select the direction the room is facing.\n'
            '3. Click "Check Room Compatibility" to see if the room placement aligns with Vastu principles.',
          ),
        ],
      ),
    );
  }
  
  String _getDirectionName(String shortDirection) {
    switch (shortDirection) {
      case 'N': return 'North';
      case 'NE': return 'North-East';
      case 'E': return 'East';
      case 'SE': return 'South-East';
      case 'S': return 'South';
      case 'SW': return 'South-West';
      case 'W': return 'West';
      case 'NW': return 'North-West';
      default: return shortDirection;
    }
  }
  
  void _checkRoom(BuildContext context) {
    final vastuService = Provider.of<VastuService>(context, listen: false);
    
    final roomRecommendation = vastuService.getRoomRecommendation(
      _selectedRoomType,
      _selectedDirection,
    );
    
    final room = Room.fromJson(roomRecommendation);
    
    // Save the evaluation
    vastuService.saveRoomEvaluation(roomRecommendation);
    
    // Navigate to result screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomResultScreen(room: room),
      ),
    );
  }
}
