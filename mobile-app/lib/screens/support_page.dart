/// SupportPage
/// Allows authenticated users to send support requests to admins.

import 'package:flutter/material.dart';

import '../services/language_service.dart';
import '../services/support_repository.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final SupportRepository _repository = SupportRepository();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = LanguageService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(language.translate('support_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.translate('support_description'),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: language.translate('support_subject_label'),
                    hintText: language.translate('support_subject_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return language.translate('support_field_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: language.translate('support_message_label'),
                    hintText: language.translate('support_message_hint'),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return language.translate('support_field_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                    label: Text(language.translate('support_submit')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final language = LanguageService();

    setState(() => _isSubmitting = true);

    try {
      await _repository.createTicket(
        subject: _subjectController.text,
        message: _messageController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(language.translate('support_submit_success'))),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language.translateWithParams('support_submit_error', {
              'error': error.toString(),
            }),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
