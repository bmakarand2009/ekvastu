import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VastuService extends ChangeNotifier {
  // Room types supported by the app
  final List<String> roomTypes = [
    'Bedroom',
    'Kitchen',
    'Living Room',
    'Bathroom',
    'Pooja/Temple',
    'Office/Desk',
    'Dining Room',
    'Storage',
    'Entrance',
  ];
  
  // Vastu directions and their significance
  final Map<String, Map<String, dynamic>> directions = {
    'N': {
      'name': 'North',
      'element': 'Water',
      'significance': 'Associated with wealth, prosperity, and career growth.',
      'favorable_rooms': ['Bedroom', 'Office/Desk', 'Living Room', 'Entrance'],
      'unfavorable_rooms': ['Kitchen', 'Pooja/Temple'],
      'color_recommendations': ['Blue', 'White', 'Light Gray', 'Light Purple'],
    },
    'NE': {
      'name': 'North-East',
      'element': 'Water/Earth',
      'significance': 'Highly auspicious direction for spiritual growth and knowledge.',
      'favorable_rooms': ['Pooja/Temple', 'Meditation Area', 'Study'],
      'unfavorable_rooms': ['Kitchen', 'Bathroom', 'Storage'],
      'color_recommendations': ['Light Yellow', 'White', 'Light Blue', 'Cream'],
    },
    'E': {
      'name': 'East',
      'element': 'Air',
      'significance': 'Brings positive energy, health, and spiritual growth.',
      'favorable_rooms': ['Bedroom', 'Living Room', 'Pooja/Temple', 'Entrance'],
      'unfavorable_rooms': ['Bathroom', 'Storage'],
      'color_recommendations': ['Light Yellow', 'White', 'Green', 'Light Blue'],
    },
    'SE': {
      'name': 'South-East',
      'element': 'Fire',
      'significance': 'Associated with fire element; good for kitchen and activities.',
      'favorable_rooms': ['Kitchen', 'Dining Room'],
      'unfavorable_rooms': ['Bedroom', 'Storage'],
      'color_recommendations': ['Orange', 'Red', 'Yellow', 'Pink'],
    },
    'S': {
      'name': 'South',
      'element': 'Fire',
      'significance': 'Brings energy but can be intense; needs careful planning.',
      'favorable_rooms': ['Kitchen', 'Storage', 'Bathroom'],
      'unfavorable_rooms': ['Bedroom (Master)', 'Pooja/Temple'],
      'color_recommendations': ['Red', 'Orange', 'Pink', 'Purple'],
    },
    'SW': {
      'name': 'South-West',
      'element': 'Earth',
      'significance': 'Represents stability, strength, and permanence.',
      'favorable_rooms': ['Master Bedroom', 'Living Room', 'Dining Room'],
      'unfavorable_rooms': ['Kitchen', 'Bathroom', 'Storage'],
      'color_recommendations': ['Earth tones', 'Brown', 'Beige', 'Yellow'],
    },
    'W': {
      'name': 'West',
      'element': 'Air',
      'significance': 'Moderate energy; suitable for social activities and rest.',
      'favorable_rooms': ['Bedroom', 'Dining Room', 'Living Room'],
      'unfavorable_rooms': ['Kitchen', 'Pooja/Temple'],
      'color_recommendations': ['White', 'Gray', 'Light Blue', 'Silver'],
    },
    'NW': {
      'name': 'North-West',
      'element': 'Air',
      'significance': 'Guest-related activities and storage.',
      'favorable_rooms': ['Guest Room', 'Storage', 'Bathroom', 'Children\'s Room'],
      'unfavorable_rooms': ['Kitchen', 'Master Bedroom'],
      'color_recommendations': ['White', 'Gray', 'Light Purple', 'Metallic Colors'],
    },
  };

  // Vastu recommendations for a room based on its type and direction
  Map<String, dynamic> getRoomRecommendation(String roomType, String direction) {
    final directionData = directions[direction] ?? directions['N']!;
    
    bool isFavorable = directionData['favorable_rooms'].contains(roomType);
    bool isUnfavorable = directionData['unfavorable_rooms'].contains(roomType);
    
    String recommendation;
    int score;
    
    if (isFavorable) {
      recommendation = '$roomType is highly favorable in the ${directionData['name']} direction.';
      score = 9;
    } else if (isUnfavorable) {
      recommendation = '$roomType is not recommended in the ${directionData['name']} direction.';
      score = 3;
    } else {
      recommendation = '$roomType is acceptable in the ${directionData['name']} direction.';
      score = 6;
    }
    
    List<String> remedies = [];
    
    if (isUnfavorable) {
      remedies = [
        'Consider relocating this room if possible.',
        'Use colors that balance the energy: ${directionData['color_recommendations'].join(', ')}.',
        'Add appropriate plants or elements to balance the energy.',
        'Consult with a Vastu expert for specific remedies.'
      ];
    } else if (!isFavorable) {
      remedies = [
        'Use colors that enhance energy: ${directionData['color_recommendations'].join(', ')}.',
        'Ensure proper lighting and ventilation.',
        'Keep the area clutter-free.'
      ];
    }
    
    return {
      'roomType': roomType,
      'direction': directionData['name'],
      'element': directionData['element'],
      'recommendation': recommendation,
      'score': score,
      'remedies': remedies,
      'color_recommendations': directionData['color_recommendations'],
    };
  }
  
  // Save room evaluation to local storage
  Future<void> saveRoomEvaluation(Map<String, dynamic> evaluation) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEvaluations = prefs.getStringList('room_evaluations') ?? [];
    
    // Convert evaluation to string representation
    final evaluationString = '${evaluation['roomType']}|${evaluation['direction']}|${evaluation['score']}';
    
    if (!savedEvaluations.contains(evaluationString)) {
      savedEvaluations.add(evaluationString);
      await prefs.setStringList('room_evaluations', savedEvaluations);
    }
    
    notifyListeners();
  }
  
  // Get saved room evaluations from local storage
  Future<List<Map<String, dynamic>>> getSavedEvaluations() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEvaluations = prefs.getStringList('room_evaluations') ?? [];
    
    List<Map<String, dynamic>> evaluations = [];
    
    for (final evalString in savedEvaluations) {
      final parts = evalString.split('|');
      if (parts.length >= 3) {
        final roomType = parts[0];
        final direction = parts[1];
        final score = int.tryParse(parts[2]) ?? 5;
        
        evaluations.add({
          'roomType': roomType,
          'direction': direction,
          'score': score,
        });
      }
    }
    
    return evaluations;
  }
  
  // Calculate overall Vastu score based on saved evaluations
  Future<int> calculateOverallScore() async {
    final evaluations = await getSavedEvaluations();
    
    if (evaluations.isEmpty) {
      return 0;
    }
    
    int totalScore = evaluations.fold(0, (sum, item) => sum + (item['score'] as int));
    return (totalScore / evaluations.length).round();
  }
}
