import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vvp_app/models/room.dart';
import 'package:vvp_app/services/vastu_service.dart';

class SavedResultsScreen extends StatelessWidget {
  const SavedResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vastuService = Provider.of<VastuService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Evaluations'),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: vastuService.getSavedEvaluations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading saved evaluations: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          
          final evaluations = snapshot.data ?? [];
          
          if (evaluations.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return Column(
            children: [
              // Summary card
              _buildSummaryCard(context, evaluations),
              
              const SizedBox(height: 16),
              
              // List of evaluations
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: evaluations.length,
                  itemBuilder: (context, index) {
                    final evaluation = evaluations[index];
                    return _buildEvaluationCard(context, evaluation);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Saved Evaluations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Evaluate your rooms using the Room Check Wizard',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Evaluate a Room'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/room_check');
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(BuildContext context, List<Map<String, dynamic>> evaluations) {
    // Calculate total score
    int totalScore = 0;
    for (var eval in evaluations) {
      totalScore += eval['score'] as int;
    }
    final averageScore = evaluations.isEmpty ? 0 : (totalScore / evaluations.length).round();
    
    // Get score color
    Color scoreColor;
    if (averageScore >= 8) {
      scoreColor = Colors.green;
    } else if (averageScore >= 6) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }
    
    // Get score text
    String scoreText;
    if (averageScore >= 8) {
      scoreText = 'Excellent Vastu Alignment';
    } else if (averageScore >= 6) {
      scoreText = 'Good Vastu Alignment';
    } else if (averageScore >= 4) {
      scoreText = 'Average Vastu Alignment';
    } else {
      scoreText = 'Poor Vastu Alignment';
    }
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Score',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$averageScore/10',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildScoreEmoji(averageScore),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${evaluations.length} Rooms',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            scoreText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEvaluationCard(BuildContext context, Map<String, dynamic> evaluation) {
    final roomType = evaluation['roomType'] as String;
    final direction = evaluation['direction'] as String;
    final score = evaluation['score'] as int;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            _getRoomEmoji(roomType),
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          roomType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Direction: $direction'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$score/10',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getScoreColor(score),
              ),
            ),
            _buildScoreEmoji(score),
          ],
        ),
        onTap: () {
          // Ideally, we would navigate to detailed view here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$roomType details coming soon!')),
          );
        },
      ),
    );
  }
  
  Widget _buildScoreEmoji(int score) {
    if (score >= 8) return const Text('🔆', style: TextStyle(fontSize: 24));
    if (score >= 6) return const Text('✅', style: TextStyle(fontSize: 24));
    if (score >= 4) return const Text('⚠️', style: TextStyle(fontSize: 24));
    return const Text('❌', style: TextStyle(fontSize: 24));
  }
  
  Color _getScoreColor(int score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    if (score >= 4) return Colors.amber;
    return Colors.red;
  }
  
  String _getRoomEmoji(String roomType) {
    switch (roomType) {
      case 'Bedroom': return '🛌';
      case 'Kitchen': return '🍳';
      case 'Living Room': return '🛋️';
      case 'Bathroom': return '🚿';
      case 'Pooja/Temple': return '🕯️';
      case 'Office/Desk': return '💼';
      case 'Dining Room': return '🍽️';
      case 'Storage': return '📦';
      case 'Entrance': return '🚪';
      default: return '🏠';
    }
  }
}
