import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_service.dart';
import 'add_personal_roadmap_screen.dart';

class PersonalPlanDetailScreen extends StatefulWidget {
  final Map<String, dynamic> roadmapData;
  const PersonalPlanDetailScreen({super.key, required this.roadmapData});

  @override
  State<PersonalPlanDetailScreen> createState() => _PersonalPlanDetailScreenState();
}

class _PersonalPlanDetailScreenState extends State<PersonalPlanDetailScreen> {
  late Map<String, dynamic> _data;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _data = widget.roadmapData;
  }

  Future<void> _moveToNextState() async {
    final String currentStatus = _data['status'] ?? (_data['isCompleted'] == true ? 'Completed' : 'Active');
    String? nextStatus;
    String message = "";

    if (currentStatus == 'Active') {
      nextStatus = 'In Progress';
      message = "Are you sure you want to move this goal to 'In Progress'?";
    } else if (currentStatus == 'In Progress') {
      nextStatus = 'Completed';
      message = "Are you sure you want to mark this goal as 'Completed'?";
    }

    if (nextStatus == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move to $nextStatus?'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Confirm', style: TextStyle(color: const Color(0xFF10B981)))
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      _data['status'] = nextStatus;
      _data['isCompleted'] = (nextStatus == 'Completed');
      _data['updatedAt'] = DateTime.now().toIso8601String();
      
      await FirebaseService.instance.savePersonalRoadmap(
        FirebaseService.instance.currentUserId!, 
        _data
      );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCompletion() async {
    setState(() => _isLoading = true);
    final userId = FirebaseService.instance.currentUserId!;
    final bool newState = !(_data['isCompleted'] ?? false);
    
    _data['isCompleted'] = newState;
    _data['status'] = newState ? 'Completed' : 'Active';
    _data['updatedAt'] = DateTime.now().toIso8601String();
    
    await FirebaseService.instance.savePersonalRoadmap(userId, _data);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deletePlan() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan?'),
        content: const Text('This will permanently remove this personal roadmap.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await FirebaseService.instance.deletePersonalRoadmap(
        FirebaseService.instance.currentUserId!, 
        _data['id']
      );
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.startsWith('http')) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _data['plan'] ?? {};
    final bool isCompleted = _data['isCompleted'] ?? false;

    final String currentStatus = _data['status'] ?? (isCompleted ? 'Completed' : 'Active');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_data['title'] ?? 'Plan Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (currentStatus != 'Completed')
            IconButton(
              icon: const Icon(Icons.arrow_forward, color: Color(0xFF10B981)),
              onPressed: _moveToNextState,
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF10B981)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddPersonalRoadmapScreen(initialData: _data)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _deletePlan,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(currentStatus),
                const SizedBox(height: 32),
                _buildAnalysisSection(plan),
                const SizedBox(height: 32),
                _buildStepsSection(plan['steps'] ?? []),
                const SizedBox(height: 32),
                _buildReferencesSection(plan['references'] ?? []),
                const SizedBox(height: 48),
                _buildCompletionButton(isCompleted),
              ],
            ),
          ),
    );
  }

  Widget _buildHeader(String status) {
    final bool isCompleted = status == 'Completed';
    final bool isInProgress = status == 'In Progress';
    
    Color headerColor;
    Color iconColor;
    IconData iconData;
    String statusTitle;

    if (isCompleted) {
      headerColor = const Color(0xFF10B981);
      iconColor = const Color(0xFF10B981);
      iconData = Icons.verified;
      statusTitle = 'Goal Achieved!';
    } else if (isInProgress) {
      headerColor = const Color(0xFF3B82F6);
      iconColor = const Color(0xFF3B82F6);
      iconData = Icons.trending_up;
      statusTitle = 'Plan In Progress';
    } else {
      headerColor = Colors.grey.shade200;
      iconColor = Colors.orange;
      iconData = Icons.lightbulb_outline;
      statusTitle = 'Plan Active';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            iconData, 
            color: iconColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _data['description'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(Map<String, dynamic> plan) {
    return Column(
      children: [
        _ExpandableAnalysisCard(
          title: 'Strengths',
          content: plan['strengths'] ?? 'Analyze your background to find advantages.',
          icon: Icons.add_circle,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 16),
        _ExpandableAnalysisCard(
          title: 'Negatives',
          content: plan['negatives'] ?? 'Identify potential challenges to overcome.',
          icon: Icons.remove_circle,
          color: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildStepsSection(List<dynamic> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Action Plan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...steps.map((step) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step['title'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(step['description'] ?? '', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildReferencesSection(List<dynamic> refs) {
    if (refs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resources & References', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...refs.map((ref) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            tileColor: Colors.grey.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(ref['title'] ?? 'Reference', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.open_in_new, size: 18, color: Color(0xFF10B981)),
            onTap: () => _launchUrl(ref['link'] ?? ''),
          ),
        )),
      ],
    );
  }

  Widget _buildCompletionButton(bool isCompleted) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _toggleCompletion,
        icon: Icon(isCompleted ? Icons.undo : Icons.check, size: 20),
        label: Text(
          isCompleted ? 'Mark as Incomplete' : 'Mark as Completed', 
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted ? Colors.grey.shade200 : const Color(0xFF10B981),
          foregroundColor: isCompleted ? Colors.grey.shade700 : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _ExpandableAnalysisCard extends StatefulWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _ExpandableAnalysisCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  State<_ExpandableAnalysisCard> createState() => _ExpandableAnalysisCardState();
}

class _ExpandableAnalysisCardState extends State<_ExpandableAnalysisCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isExpanded ? widget.color.withValues(alpha: 0.3) : widget.color.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
          leading: Icon(widget.icon, color: widget.color, size: 20),
          title: Text(
            widget.title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: widget.color, fontSize: 14),
          ),
          iconColor: widget.color,
          collapsedIconColor: widget.color.withValues(alpha: 0.5),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.content,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
