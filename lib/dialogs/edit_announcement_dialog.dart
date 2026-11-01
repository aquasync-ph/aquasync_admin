import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class EditAnnouncementDialog extends StatefulWidget {
  final AnnouncementModel announcement;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const EditAnnouncementDialog({
    super.key,
    required this.announcement,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<EditAnnouncementDialog> createState() => _EditAnnouncementDialogState();
}

class _EditAnnouncementDialogState extends State<EditAnnouncementDialog> {
  late TextEditingController titleCtrl;
  late TextEditingController messageCtrl;
  late String selectedType;
  late bool isActive;
  DateTime? startsAt;
  DateTime? endsAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.announcement.title);
    messageCtrl = TextEditingController(text: widget.announcement.message);
    selectedType = widget.announcement.type;
    isActive = widget.announcement.isActive;
    startsAt = widget.announcement.startsAt;
    endsAt = widget.announcement.endsAt;
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = (isStart ? startsAt : endsAt) ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null) return;

    setState(() {
      final combined = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      if (isStart) {
        startsAt = combined;
      } else {
        endsAt = combined;
      }
    });
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Not Set';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final y = dt.year;
    final m = twoDigits(dt.month);
    final d = twoDigits(dt.day);
    final h = twoDigits(dt.hour);
    final min = twoDigits(dt.minute);
    return '$y-$m-$d $h:$min';
  }

  Future<void> _submit() async {
    final titleStr = titleCtrl.text.trim();
    if (titleStr.isEmpty) {
      widget.onError('Announcement Title cannot be empty.');
      return;
    }
    if (titleStr.length < 2) {
      widget.onError('Announcement Title must be at least 2 characters.');
      return;
    }
    if (titleStr.length > 60) {
      widget.onError('Announcement Title cannot exceed 60 characters.');
      return;
    }

    final msgStr = messageCtrl.text.trim();
    if (msgStr.isEmpty) {
      widget.onError('Announcement Message cannot be empty.');
      return;
    }
    if (msgStr.length < 5) {
      widget.onError('Announcement Message must be at least 5 characters.');
      return;
    }
    if (msgStr.length > 150) {
      widget.onError('Announcement Message cannot exceed 150 characters.');
      return;
    }

    if (startsAt != null && endsAt != null && (endsAt!.isBefore(startsAt!) || endsAt!.isAtSameMomentAs(startsAt!))) {
      widget.onError('End date & time must be after Start date & time.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService.updateAnnouncement(
        announcementId: widget.announcement.id,
        title: titleStr,
        message: msgStr,
        type: selectedType,
        isActive: isActive,
        startsAt: startsAt,
        endsAt: endsAt,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      widget.onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFA082A45),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x3838BDF8), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 36,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0x330284C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x4038BDF8)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Edit Announcement',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFFBAE6FD)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Divider(height: 24, color: Colors.white.withValues(alpha: 0.18)),

                  const Text(
                    'Announcement Title (Max 60 chars)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    maxLength: 60,
                    decoration: InputDecoration(
                      hintText: 'e.g. Scheduled Station Maintenance',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                      prefixIcon: const Icon(Icons.title_rounded, size: 20, color: Color(0xFF7DD3FC)),
                      counterStyle: const TextStyle(fontSize: 11, color: Color(0xFF7DD3FC)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'Announcement Type',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    dropdownColor: const Color(0xFF0A3052),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: 'info', child: Text('General Info', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'promo', child: Text('Promotional Offer', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'alert', child: Text('Important Alert', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'maintenance', child: Text('Station Maintenance', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedType = val);
                    },
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'Announcement Message (Max 150 chars)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: messageCtrl,
                    maxLength: 150,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter announcement details...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 50),
                        child: Icon(Icons.notes_rounded, size: 20, color: Color(0xFF7DD3FC)),
                      ),
                      counterStyle: const TextStyle(fontSize: 11, color: Color(0xFF7DD3FC)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('START DATE & TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC))),
                                if (startsAt != null)
                                  GestureDetector(
                                    onTap: () => setState(() => startsAt = null),
                                    child: const Text('Clear', style: TextStyle(fontSize: 10, color: Color(0xFFF87171), fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _pickDateTime(true),
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.10),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        startsAt != null ? _formatDateTime(startsAt) : 'Start Immediately',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: startsAt != null ? Colors.white : const Color(0xFFBAE6FD)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF38BDF8)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('END DATE & TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC))),
                                if (endsAt != null)
                                  GestureDetector(
                                    onTap: () => setState(() => endsAt = null),
                                    child: const Text('Clear', style: TextStyle(fontSize: 10, color: Color(0xFFF87171), fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _pickDateTime(false),
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.10),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        endsAt != null ? _formatDateTime(endsAt) : 'No Expiry Date',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: endsAt != null ? Colors.white : const Color(0xFFBAE6FD)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.event_busy_rounded, size: 16, color: Color(0xFF38BDF8)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Broadcast Status',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Switch(
                        value: isActive,
                        activeTrackColor: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                        activeThumbColor: const Color(0xFF38BDF8),
                        onChanged: (val) => setState(() => isActive = val),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                        child: const Text('Cancel', style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD), fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Icon(Icons.check_circle_outline_rounded, size: 16),
                        label: const Text('Save Changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: const Color(0x330284C7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}