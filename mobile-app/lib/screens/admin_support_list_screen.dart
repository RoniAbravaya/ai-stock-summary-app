/// Admin support inbox screens
/// Lists support tickets and provides detail view for status updates.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/support_ticket.dart';
import '../services/language_service.dart';
import '../services/support_repository.dart';

class AdminSupportListPage extends StatelessWidget {
  AdminSupportListPage({super.key});

  final SupportRepository _repository = SupportRepository();

  @override
  Widget build(BuildContext context) {
    final language = LanguageService();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: StreamBuilder<List<SupportTicket>>(
        stream: _repository.listenToTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                language.translate('admin_support_error'),
                textAlign: TextAlign.center,
              ),
            );
          }

          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return Center(
              child: Text(language.translate('admin_support_empty')),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return _SupportListTile(ticket: ticket);
            },
          );
        },
      ),
    );
  }
}

class _SupportListTile extends StatelessWidget {
  const _SupportListTile({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final language = LanguageService();
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd().add_jm();
    final subtitle = '${ticket.userEmail}\n${dateFormat.format(ticket.createdAt)}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminSupportDetailPage(ticket: ticket),
          ),
        ),
        title: Text(
          ticket.subject,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: theme.textTheme.bodySmall,
          ),
        ),
        trailing: _StatusChip(status: ticket.status),
      ),
    );
  }
}

class AdminSupportDetailPage extends StatefulWidget {
  const AdminSupportDetailPage({super.key, required this.ticket});

  final SupportTicket ticket;

  @override
  State<AdminSupportDetailPage> createState() => _AdminSupportDetailPageState();
}

class _AdminSupportDetailPageState extends State<AdminSupportDetailPage> {
  final SupportRepository _repository = SupportRepository();
  late SupportTicketStatus _selectedStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.ticket.status;
  }

  @override
  Widget build(BuildContext context) {
    final language = LanguageService();
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: Text(language.translate('admin_support_detail_title')),
      ),
      body: SafeArea(
        child: StreamBuilder<SupportTicket?>(
          stream: _repository.watchTicket(widget.ticket.ticketId),
          initialData: widget.ticket,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final ticket = snapshot.data ?? widget.ticket;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ticket.userEmail} • ${dateFormat.format(ticket.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(ticket.message, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    language.translate('admin_support_status_label'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SupportTicketStatus>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: SupportTicketStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(_translateStatus(language, status)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedStatus = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => _updateStatus(ticket.ticketId),
                      icon: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(language.translate('admin_support_save')),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _updateStatus(String ticketId) async {
    final language = LanguageService();
    setState(() => _isSaving = true);

    try {
      await _repository.updateStatus(ticketId, _selectedStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(language.translate('admin_support_update_success'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language.translateWithParams('admin_support_update_error', {
              'error': error.toString(),
            }),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _translateStatus(LanguageService language, SupportTicketStatus status) {
    switch (status) {
      case SupportTicketStatus.open:
        return language.translate('admin_support_status_open');
      case SupportTicketStatus.inProgress:
        return language.translate('admin_support_status_in_progress');
      case SupportTicketStatus.closed:
        return language.translate('admin_support_status_closed');
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SupportTicketStatus status;

  @override
  Widget build(BuildContext context) {
    final language = LanguageService();
    Color background;
    Color foreground;

    switch (status) {
      case SupportTicketStatus.open:
        background = Colors.blue.shade50;
        foreground = Colors.blue.shade700;
        break;
      case SupportTicketStatus.inProgress:
        background = Colors.orange.shade50;
        foreground = Colors.orange.shade700;
        break;
      case SupportTicketStatus.closed:
        background = Colors.green.shade50;
        foreground = Colors.green.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _translateStatus(language),
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _translateStatus(LanguageService language) {
    switch (status) {
      case SupportTicketStatus.open:
        return language.translate('admin_support_status_open');
      case SupportTicketStatus.inProgress:
        return language.translate('admin_support_status_in_progress');
      case SupportTicketStatus.closed:
        return language.translate('admin_support_status_closed');
    }
  }
}
