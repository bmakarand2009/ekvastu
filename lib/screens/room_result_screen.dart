import 'package:flutter/material.dart';
import 'package:vvp_app/models/room.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomResultScreen extends StatelessWidget {
  final Room room;
  
  const RoomResultScreen({Key? key, required this.room}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Compatibility'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result summary card
            _buildResultSummaryCard(context),
            
            const SizedBox(height: 24),
            
            // Recommendation details
            Text(
              'Detailed Recommendations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Remedies list
            _buildRemediesCard(context),
            
            const SizedBox(height: 24),
            
            // Color recommendations
            _buildColorRecommendationsCard(context),
            
            const SizedBox(height: 24),
            
            // Actions
            _buildActionsCard(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultSummaryCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: _getHeaderColor(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      room.type,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        room.direction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Vastu Score: ${room.score}/10',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      room.getScoreEmoji(),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              room.recommendation,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRemediesCard(BuildContext context) {
    if (room.remedies.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No remedies needed for this room placement.'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.healing,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Remedies',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...room.remedies.map((remedy) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(remedy)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildColorRecommendationsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.color_lens,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recommended Colors',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: room.colorRecommendations.map((color) => Chip(
                label: Text(color),
                backgroundColor: _getColorChipBackground(color),
                labelStyle: TextStyle(
                  color: _isLightColor(color) ? Colors.black : Colors.white,
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.more_horiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share Results'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                // Share functionality would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing results...')),
                );
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('Book Consultation'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                _launchConsultationBooking();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getHeaderColor(BuildContext context) {
    if (room.score >= 8) {
      return Colors.green;
    } else if (room.score >= 6) {
      return Colors.amber.shade700;
    } else {
      return Colors.red;
    }
  }
  
  Color _getColorChipBackground(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'light blue':
        return Colors.lightBlue.shade200;
      case 'white':
        return Colors.grey.shade100;
      case 'light gray':
      case 'light grey':
        return Colors.grey.shade300;
      case 'light purple':
        return Colors.purple.shade200;
      case 'light yellow':
        return Colors.yellow.shade200;
      case 'cream':
        return const Color(0xFFFFF8DC);
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'brown':
        return Colors.brown;
      case 'beige':
        return const Color(0xFFF5F5DC);
      case 'gray':
      case 'grey':
        return Colors.grey;
      case 'silver':
        return Colors.grey.shade300;
      default:
        if (colorName.toLowerCase().contains('earth')) {
          return Colors.brown.shade300;
        } else if (colorName.toLowerCase().contains('metallic')) {
          return Colors.grey.shade400;
        }
        return Colors.grey.shade500;
    }
  }
  
  bool _isLightColor(String colorName) {
    final lowerName = colorName.toLowerCase();
    return lowerName.contains('light') || 
           lowerName == 'white' || 
           lowerName == 'cream' || 
           lowerName == 'beige' || 
           lowerName == 'yellow';
  }
  
  void _launchConsultationBooking() async {
    // This would typically link to a booking system
    const url = 'https://example.com/book-consultation';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
