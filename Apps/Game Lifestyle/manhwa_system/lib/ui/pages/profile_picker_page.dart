import 'package:flutter/material.dart';
import '../../services/system_controller.dart';
import '../../models/profile.dart';
import '../widgets/page_container.dart';

class ProfilePickerPage extends StatefulWidget {
  final SystemController controller;

  const ProfilePickerPage({super.key, required this.controller});

  @override
  State<ProfilePickerPage> createState() => _ProfilePickerPageState();
}

class _ProfilePickerPageState extends State<ProfilePickerPage> {
  final _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await widget.controller.createProfile(name);
    if (mounted) {
      setState(() {
        _nameController.clear();
        _isCreating = false;
      });
    }
  }

  Future<void> _switchProfile(String profileId) async {
    await widget.controller.switchProfile(profileId);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteProfile(String profileId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await widget.controller.deleteProfile(profileId);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot delete active or last profile')),
        );
      } else {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = widget.controller.profiles;
    final activeId = widget.controller.activeProfileId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
      ),
      body: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile list
            Expanded(
              child: ListView.builder(
                itemCount: profiles.length,
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  final isActive = profile.id == activeId;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    color: isActive ? Colors.blue.shade50 : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isActive
                            ? Colors.blue
                            : Colors.grey,
                        child: Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        profile.name,
                        style: TextStyle(
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        isActive ? 'Active' : 'Created ${_formatDate(DateTime.fromMillisecondsSinceEpoch(profile.createdAt))}',
                      ),
                      trailing: isActive
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.login),
                                  onPressed: () => _switchProfile(profile.id),
                                  tooltip: 'Switch to this profile',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteProfile(profile.id),
                                  tooltip: 'Delete profile',
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),

            // Create new profile section
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _isCreating
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Profile Name',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _createProfile(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _createProfile,
                                child: const Text('Create'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => setState(() {
                                _isCreating = false;
                                _nameController.clear();
                              }),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: () => setState(() => _isCreating = true),
                      icon: const Icon(Icons.add),
                      label: const Text('New Profile'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
