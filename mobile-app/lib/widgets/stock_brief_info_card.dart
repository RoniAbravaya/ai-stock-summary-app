/// StockBriefInfoCard
/// Displays key company profile information for a stock detail view.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/stock_models.dart';
import '../services/language_service.dart';

class StockBriefInfoCard extends StatelessWidget {
  const StockBriefInfoCard({
    super.key,
    required this.profile,
  });

  final StockProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = LanguageService();

    final placeholder = language.translate('stock_brief_not_available');

    final rows = <_InfoRow>[
      _InfoRow(
        icon: Icons.apartment_outlined,
        label: language.translate('stock_brief_sector'),
        value: _fallback(profile.sector ?? profile.industry, placeholder),
      ),
      _InfoRow(
        icon: Icons.monetization_on_outlined,
        label: language.translate('stock_brief_market_cap'),
        value: _formatMarketCap(profile.marketCap, placeholder),
      ),
      _InfoRow(
        icon: Icons.timeline_outlined,
        label: language.translate('stock_brief_range'),
        value: _formatRange(profile.fiftyTwoWeekLow, profile.fiftyTwoWeekHigh, placeholder),
      ),
      _InfoRow(
        icon: Icons.store_mall_directory_outlined,
        label: language.translate('stock_brief_exchange'),
        value: _fallback(profile.exchange, placeholder),
      ),
      _InfoRow(
        icon: Icons.flag_outlined,
        label: language.translate('stock_brief_country'),
        value: _fallback(profile.country, placeholder),
      ),
    ];

    final hasDescription = (profile.longBusinessSummary ?? '').trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.translate('stock_brief_title'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (profile.companyName != null && profile.companyName!.isNotEmpty)
                      Text(
                        profile.companyName!,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (profile.hasWebsite)
                TextButton.icon(
                  onPressed: () => _launchWebsite(profile.website!),
                  icon: const Icon(Icons.launch, size: 18),
                  label: Text(language.translate('stock_brief_website')),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map((row) => _InfoRowWidget(row: row, placeholder: placeholder)),
          if (hasDescription) ...[
            const SizedBox(height: 12),
            Text(
              language.translate('stock_brief_about'),
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              profile.longBusinessSummary!,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _fallback(String? value, String placeholder) => value == null || value.trim().isEmpty ? placeholder : value;

  String _formatMarketCap(double? value, String placeholder) {
    if (value == null || value <= 0) return placeholder;
    final formatter = NumberFormat.compactCurrency(symbol: r'$', decimalDigits: 2);
    return formatter.format(value);
  }

  String _formatRange(double? low, double? high, String placeholder) {
    if (low == null || high == null) return placeholder;
    return '${low.toStringAsFixed(2)} - ${high.toStringAsFixed(2)}';
  }

  Future<void> _launchWebsite(String url) async {
    var target = url.trim();
    if (!target.startsWith('http://') && !target.startsWith('https://')) {
      target = 'https://$target';
    }
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _InfoRow {
  _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _InfoRowWidget extends StatelessWidget {
  const _InfoRowWidget({
    required this.row,
    required this.placeholder,
  });

  final _InfoRow row;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.bodyMedium;
    final bool isPlaceholder = row.value == placeholder;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(row.icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Builder(
                  builder: (_) {
                    final Color? resolvedColor = isPlaceholder
                        ? theme.textTheme.bodySmall?.color
                        : valueStyle?.color ?? theme.textTheme.bodyMedium?.color;
                    final TextStyle? effectiveStyle = valueStyle != null
                        ? valueStyle!.copyWith(color: resolvedColor)
                        : theme.textTheme.bodyMedium?.copyWith(color: resolvedColor);

                    return Text(
                      row.value,
                      style: effectiveStyle,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
