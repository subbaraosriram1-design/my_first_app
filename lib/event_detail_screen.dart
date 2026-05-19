import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'events_provider.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _isJoined = context.read<EventsProvider>().joinedEvents.any((e) => e['name'] == widget.event['name']);
  }

  Future<void> _openMaps() async {
    final double lat = widget.event['latitude'] ?? 0.0;
    final double lng = widget.event['longitude'] ?? 0.0;
    final String label = widget.event['name'] ?? 'Event Location';
    
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    final Uri appleMapsUrl = Uri.parse("http://maps.apple.com/?ll=$lat,$lng&q=$label");
    final Uri geoUrl = Uri.parse("geo:$lat,$lng?q=$lat,$lng($label)");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(geoUrl)) {
      await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.event['image'] ?? _getFallbackImage(widget.event['category'] ?? widget.event['name'] ?? ''),
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Image.network(
                  _getFallbackImage(widget.event['category'] ?? widget.event['name'] ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B3FD8).withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.event['category'] ?? 'General',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5B3FD8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.event['date'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.event['name'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF5B3FD8), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.event['location'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    'About Event',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.event['description'] ?? 'No description available.',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildOrganizerInfo(),
                  const SizedBox(height: 24),
                  _buildRegistrationInfo(),
                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openMaps,
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: const Color(0xFF5B3FD8),
                  side: const BorderSide(color: Color(0xFF5B3FD8)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (!_isJoined) {
                    context.read<EventsProvider>().joinEvent(widget.event);
                    setState(() {
                      _isJoined = true;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isJoined ? const Color(0xFF10B981) : const Color(0xFF5B3FD8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  _isJoined ? 'Joined' : 'Join Event',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF5B3FD8).withAlpha(10),
                child: const Icon(Icons.person, color: Color(0xFF5B3FD8)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organizer',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    Text(
                      widget.event['organizer'] ?? 'Unknown Organizer',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.event['contact'] != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.event['contact'],
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegistrationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registration Details',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withAlpha(20)),
          ),
          child: Text(
            widget.event['registration_info'] ?? 'Register on the spot or via the official platform link.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
