import 'package:flutter/material.dart';
import 'package:vvp_app/screens/compass_screen.dart';
import 'package:vvp_app/screens/room_check_screen.dart';
import 'package:vvp_app/screens/saved_results_screen.dart';
import 'package:vvp_app/widgets/feature_card.dart';
import 'package:provider/provider.dart';
import 'package:vvp_app/services/vastu_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VVP - Vastu Virtual Planner'),
        elevation: 0,
        centerTitle: true,
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // Welcome section
                Text(
                  'Welcome to Vastu Virtual Planner',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your guide to harmonious living spaces',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                
                const SizedBox(height: 32),
                
                // Features section
                Text(
                  'Features',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                FutureBuilder<int>(
                  future: context.read<VastuService>().calculateOverallScore(),
                  builder: (context, snapshot) {
                    final overallScore = snapshot.data ?? 0;
                    
                    return Column(
                      children: [
                        // Direction Compass Feature
                        FeatureCard(
                          title: 'Direction Compass',
                          description: 'Find exact directions for Vastu alignment',
                          icon: Icons.explore,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CompassScreen()),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Room Check Wizard Feature
                        FeatureCard(
                          title: 'Room Check Wizard',
                          description: 'Evaluate if your room placement aligns with Vastu principles',
                          icon: Icons.house,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RoomCheckScreen()),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Saved Results Feature
                        FeatureCard(
                          title: 'Saved Evaluations',
                          description: 'View your previous room evaluations and overall score',
                          icon: Icons.list_alt,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SavedResultsScreen()),
                          ),
                          trailing: overallScore > 0 
                              ? Chip(
                                  label: Text('Score: $overallScore/10'),
                                  backgroundColor: _getScoreColor(overallScore),
                                )
                              : null,
                        ),
                      ],
                    );
                  }
                ),
                
                const SizedBox(height: 32),
                
                // Weekly tip section
                _buildWeeklyTip(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildWeeklyTip(BuildContext context) {
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
                Icons.lightbulb,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Weekly Vastu Tip',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your North-East direction clean and clutter-free to enhance positive energy flow. This direction is associated with water and wisdom.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  Color _getScoreColor(int score) {
    if (score >= 8) return Colors.green.shade100;
    if (score >= 6) return Colors.amber.shade100;
    return Colors.red.shade100;
  }
}
