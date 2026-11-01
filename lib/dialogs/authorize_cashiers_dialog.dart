import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../widgets/sweet_alert.dart';

class AuthorizeCashiersDialog extends StatefulWidget {
  final VoidCallback onRefresh;

  const AuthorizeCashiersDialog({
    super.key,
    required this.onRefresh,
  });

  @override
  State<AuthorizeCashiersDialog> createState() => _AuthorizeCashiersDialogState();
}

class _AuthorizeCashiersDialogState extends State<AuthorizeCashiersDialog> {
  List<Map<String, dynamic>> _cashiers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCashiers();
  }

  Future<void> _loadCashiers() async {
    setState(() => _isLoading = true);
    try {
      final res = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('role', 'cashier')
          .eq('is_archived', false)
          .order('full_name', ascending: true);
      if (mounted) {
        setState(() {
          _cashiers = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePermission(Map<String, dynamic> cashier, bool allow) async {
    final id = cashier['id']?.toString() ?? '';
    try {
      await SupabaseService.updateProfileFields(
        userId: id,
        updates: {
          'can_assign_drivers': allow,
          'can_accept_orders': allow,
        },
      );
      await _loadCashiers();
      widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      SweetAlert.showError(context, 'Failed to update permission: $e');
    }
  }

  Future<void> _handleTogglePermission(Map<String, dynamic> cashier, bool allow) async {
    final name = cashier['full_name']?.toString() ?? 'Cashier';
    if (allow) {
      final confirmed = await _showPasswordVerificationDialog(cashier);
      if (confirmed == true) {
        await _togglePermission(cashier, true);
        if (mounted) {
          SweetAlert.showSuccess(context, '$name has been authorized successfully!');
        }
      }
    } else {
      final confirmed = await _showRevokeConfirmationDialog(cashier);
      if (confirmed == true) {
        await _togglePermission(cashier, false);
        if (mounted) {
          SweetAlert.showInfo(context, 'Authorization for $name has been revoked.');
        }
      }
    }
  }

  Future<bool?> _showPasswordVerificationDialog(Map<String, dynamic> cashier) {
    final name = cashier['full_name']?.toString() ?? 'Cashier';
    final phone = cashier['phone']?.toString() ?? '—';
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isVerifying = false;
    String? errorMessage;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> verifyAndConfirm() async {
              final pass = passwordController.text.trim();
              if (pass.isEmpty) {
                setModalState(() {
                  errorMessage = 'Please enter your admin password.';
                });
                return;
              }

              setModalState(() {
                isVerifying = true;
                errorMessage = null;
              });

              try {
                final isValid = await SupabaseService.verifyAdminPassword(pass);
                if (isValid) {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(true);
                  }
                } else {
                  setModalState(() {
                    isVerifying = false;
                    errorMessage = 'Incorrect admin password. Please try again.';
                  });
                }
              } catch (e) {
                setModalState(() {
                  isVerifying = false;
                  errorMessage = 'Verification failed: ${e.toString().replaceAll("Exception: ", "")}';
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 460),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0x33C084FC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0x66C084FC)),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.verified_user_rounded, color: Color(0xFFC084FC), size: 24),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Authorize Cashier',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  Text(
                                    'Admin Password Verification Required',
                                    style: TextStyle(fontSize: 11, color: Color(0xFFBAE6FD)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: isVerifying ? null : () => Navigator.of(dialogContext).pop(false),
                              icon: const Icon(Icons.close, size: 20, color: Color(0xFFBAE6FD)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        Divider(height: 24, color: Colors.white.withValues(alpha: 0.18)),

                        // Cashier Info Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x1AC084FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x44C084FC)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0x33C084FC),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'C',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFC084FC)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                    Text(phone, style: const TextStyle(fontSize: 11, color: Color(0xFFBAE6FD))),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0x3338BDF8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Cashier POS',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Warning / Description
                        const Text(
                          'Are you sure you want to authorize this cashier? Authorized cashiers can accept pending orders and assign drivers on Cashier POS when Admin is away.',
                          style: TextStyle(fontSize: 12, color: Color(0xFFBAE6FD), height: 1.4),
                        ),
                        const SizedBox(height: 16),

                        // Admin Password Input
                        const Text(
                          'ENTER ADMIN PASSWORD',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          onSubmitted: (_) => verifyAndConfirm(),
                          decoration: InputDecoration(
                            hintText: 'Enter your admin password',
                            hintStyle: const TextStyle(color: Color(0x66BAE6FD), fontSize: 13),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF38BDF8), size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFFBAE6FD),
                                size: 18,
                              ),
                              onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0x1F000000),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0x3838BDF8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFC084FC), width: 1.5),
                            ),
                          ),
                        ),

                        // Error message if any
                        if (errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFFCA5A5), size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: isVerifying ? null : () => Navigator.of(dialogContext).pop(false),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFBAE6FD),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: isVerifying ? null : verifyAndConfirm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC084FC),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: isVerifying
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_outline_rounded, size: 16),
                                        SizedBox(width: 6),
                                        Text('Authorize Cashier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _showRevokeConfirmationDialog(Map<String, dynamic> cashier) {
    final name = cashier['full_name']?.toString() ?? 'Cashier';

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0x33EF4444),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x66EF4444)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.remove_moderator_rounded, color: Color(0xFFFCA5A5), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Revoke Authorization',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                'Remove cashier permissions',
                                style: TextStyle(fontSize: 11, color: Color(0xFFBAE6FD)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24, color: Colors.white.withValues(alpha: 0.18)),
                    Text(
                      'Are you sure you want to revoke order acceptance & driver assignment permissions for "$name"?',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD), height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFBAE6FD),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Revoke Permission', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
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
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0x33C084FC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x66C084FC)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.assignment_ind_rounded, color: Color(0xFFC084FC), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Authorize Cashiers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('Delegate order acceptance & driver assignment', style: TextStyle(fontSize: 11, color: Color(0xFFBAE6FD))),
                          ],
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

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x330284C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x6638BDF8)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Authorized cashiers can accept pending orders and assign drivers on Cashier POS when Admin is away.',
                          style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC)))
                      : _cashiers.isEmpty
                          ? const Center(child: Text('No active cashiers registered in system.', style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))))
                          : ListView.separated(
                              itemCount: _cashiers.length,
                              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
                              itemBuilder: (context, index) {
                                final c = _cashiers[index];
                                final name = c['full_name']?.toString() ?? 'Cashier';
                                final phone = c['phone']?.toString() ?? '—';
                                final isAllowed = c['can_assign_drivers'] == true || c['can_assign_driver'] == true || c['can_accept_orders'] == true;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: const Color(0x33C084FC),
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'C',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC084FC)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                            Text(phone, style: const TextStyle(fontSize: 11, color: Color(0xFFBAE6FD))),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: isAllowed,
                                        activeTrackColor: const Color(0xFFC084FC).withValues(alpha: 0.5),
                                        activeThumbColor: const Color(0xFFC084FC),
                                        onChanged: (val) => _handleTogglePermission(c, val),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Done', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
