import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'ai_service.dart';
import 'firebase_service.dart';
import 'location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'event_detail_screen.dart';
import 'events_provider.dart';
import 'saved_joined_events_screen.dart';

class EventsSwipeScreen extends StatefulWidget {
  final String category;
  const EventsSwipeScreen({super.key, required this.category});

  @override
  State<EventsSwipeScreen> createState() => _EventsSwipeScreenState();
}

class _EventsSwipeScreenState extends State<EventsSwipeScreen> {
  final AiService _aiService = GroqAiService();
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    context.read<EventsProvider>().loadEvents();
    _fetchData();
  }

  Future<void> _fetchData() async {
    _currentPosition = await LocationService.getCurrentLocation();
    await _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final userData = await FirebaseService.instance.getResume(userId);
      if (userData != null) {
        if (_currentPosition != null) {
          userData['current_lat'] = _currentPosition!.latitude;
          userData['current_lng'] = _currentPosition!.longitude;
        }
        final recs = await _aiService.getNearbyRecommendations(userData, widget.category);
        if (mounted) {
          setState(() {
            _events = recs;
            _isLoading = false;
          });
        }
      }
    }
  }

  void _onSwipe(bool isRight) {
    if (isRight && _currentIndex < _events.length) {
      context.read<EventsProvider>().saveEvent(_events[_currentIndex]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event Saved!', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
    if (mounted) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.category, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark, color: Color(0xFF5B3FD8)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SavedJoinedEventsScreen(initialTab: 0)),
            ),
            tooltip: 'Saved Events',
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, color: Color(0xFF5B3FD8)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SavedJoinedEventsScreen(initialTab: 1)),
            ),
            tooltip: 'Joined Events',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B3FD8)))
          : _currentIndex >= _events.length
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No more events nearby!', style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex = 0;
                            _isLoading = true;
                          });
                          _fetchEvents();
                        },
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: _events.asMap().entries.map((entry) {
                    if (entry.key < _currentIndex) return const SizedBox.shrink();
                    return SwipeableCard(
                      item: entry.value,
                      onSwipe: _onSwipe,
                      isTop: entry.key == _currentIndex,
                      currentPosition: _currentPosition,
                    );
                  }).toList().reversed.toList(),
                ),
    );
  }
}

class SwipeableCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(bool) onSwipe;
  final bool isTop;
  final Position? currentPosition;

  const SwipeableCard({
    super.key,
    required this.item,
    required this.onSwipe,
    required this.isTop,
    this.currentPosition,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> with SingleTickerProviderStateMixin {
  Offset _offset = Offset.zero;
  double _angle = 0;

  String _getFallbackImage(String query) {
    query = query.toLowerCase();
    if (query.contains('cricket')) return 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?q=80&w=600';
    if (query.contains('football') || query.contains('soccer')) return 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?q=80&w=600';
    if (query.contains('badminton')) return 'https://images.unsplash.com/photo-1626225967045-94400244c53b?q=80&w=600';
    if (query.contains('coding') || query.contains('tech')) return 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?q=80&w=600';
    if (query.contains('gaming')) return 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=600';
    if (query.contains('chess')) return 'https://images.unsplash.com/photo-1524362040623-633b4d2f0992?q=80&w=600';
    if (query.contains('singing') || query.contains('music')) return 'https://images.unsplash.com/photo-1516280440614-37939bbacd81?q=80&w=600';
    if (query.contains('dance')) return 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=600';
    return 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?q=80&w=600';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTop) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildCardContent(),
        ),
      );
    }

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _offset += details.delta;
          _angle = _offset.dx / 20 * (3.14159 / 180);
        });
      },
      onPanEnd: (details) {
        if (_offset.dx > 100) {
          widget.onSwipe(true);
        } else if (_offset.dx < -100) {
          widget.onSwipe(false);
        } else {
          setState(() {
            _offset = Offset.zero;
            _angle = 0;
          });
        }
      },
      child: Center(
        child: Transform.translate(
          offset: _offset,
          child: Transform.rotate(
            angle: _angle,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildCardContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: widget.item),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Image.network(
                  widget.item['image'] ?? _getFallbackImage(widget.item['category'] ?? widget.item['name'] ?? ''),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (c, e, s) => Image.network(
                    _getFallbackImage(widget.item['category'] ?? widget.item['name'] ?? ''),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.item['name'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B3FD8).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.item['category'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF5B3FD8),
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.item['date'] ?? '',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.item['location'] ?? '',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.currentPosition != null && widget.item['latitude'] != null && widget.item['longitude'] != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${LocationService.calculateDistance(widget.currentPosition!.latitude, widget.currentPosition!.longitude, (widget.item['latitude'] as num).toDouble(), (widget.item['longitude'] as num).toDouble()).toStringAsFixed(1)} km',
                                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.item['description'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
