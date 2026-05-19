import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_service.dart';
import 'firebase_service.dart';
import 'location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'general_detail_screen.dart';

class RecommendationsListScreen extends StatefulWidget {
  final String category;
  const RecommendationsListScreen({super.key, required this.category});

  @override
  State<RecommendationsListScreen> createState() => _RecommendationsListScreenState();
}

class _RecommendationsListScreenState extends State<RecommendationsListScreen> {
  final AiService _aiService = GroqAiService();
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    _currentPosition = await LocationService.getCurrentLocation();
    await _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final userData = await FirebaseService.instance.getResume(userId);
      if (userData != null) {
        // Add location context if available
        if (_currentPosition != null) {
          userData['current_lat'] = _currentPosition!.latitude;
          userData['current_lng'] = _currentPosition!.longitude;
        }

        final recs = await _aiService.getNearbyRecommendations(userData, widget.category);
        if (mounted) {
          setState(() {
            _recommendations = recs;
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.category, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B3FD8)))
          : _recommendations.isEmpty
              ? Center(child: Text('No recommendations found.', style: GoogleFonts.poppins()))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _recommendations.length,
                  itemBuilder: (context, index) {
                    final item = _recommendations[index];
                    return _buildRecommendationCard(item);
                  },
                ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GeneralDetailScreen(item: item, category: widget.category),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B3FD8).withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business, color: Color(0xFF5B3FD8)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? item['name'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        item['company'] ?? item['provider'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item['match']}% Match',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item['location'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_currentPosition != null && item['latitude'] != null && item['longitude'] != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${LocationService.calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude, (item['latitude'] as num).toDouble(), (item['longitude'] as num).toDouble()).toStringAsFixed(1)} km',
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (item['skills'] as List? ?? []).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    skill.toString(),
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              item['description'] ?? '',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GeneralDetailScreen(item: item, category: widget.category),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3FD8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  'View Details',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
