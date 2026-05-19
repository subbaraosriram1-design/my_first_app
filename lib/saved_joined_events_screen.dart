import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'events_provider.dart';
import 'event_detail_screen.dart';

class SavedJoinedEventsScreen extends StatelessWidget {
  final int initialTab;
  const SavedJoinedEventsScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('My Events', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            labelColor: const Color(0xFF5B3FD8),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF5B3FD8),
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Saved'),
              Tab(text: 'Joined'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EventList(isSaved: true),
            _EventList(isSaved: false),
          ],
        ),
      ),
    );
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

class _EventList extends StatelessWidget {
  final bool isSaved;
  const _EventList({required this.isSaved});

  @override
  Widget build(BuildContext context) {
    return Consumer<EventsProvider>(
      builder: (context, provider, child) {
        final events = isSaved ? provider.savedEvents : provider.joinedEvents;
        
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isSaved ? Icons.bookmark_border : Icons.check_circle_outline, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  isSaved ? 'No saved events yet' : 'You haven\'t joined any events',
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    event['image'] ?? _getFallbackImage(event['category'] ?? event['name'] ?? ''),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Image.network(
                      _getFallbackImage(event['category'] ?? event['name'] ?? ''),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(event['name'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: Text(event['date'] ?? '', style: GoogleFonts.poppins(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () {
                        if (isSaved) {
                          provider.removeSavedEvent(event['name']);
                        } else {
                          provider.removeJoinedEvent(event['name']);
                        }
                      },
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
