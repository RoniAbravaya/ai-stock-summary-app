import 'package:flutter/material.dart';

class TestDataGeneratorWidget extends StatefulWidget {
  final Function(String table, int count) onGenerateData;

  const TestDataGeneratorWidget({
    super.key,
    required this.onGenerateData,
  });

  @override
  State<TestDataGeneratorWidget> createState() =>
      _TestDataGeneratorWidgetState();
}

class _TestDataGeneratorWidgetState extends State<TestDataGeneratorWidget> {
  String _selectedTable = 'stocks';
  int _recordCount = 10;

  final List<String> _availableTables = [
    'stocks',
    'portfolios',
    'watchlists',
    'ai_summaries',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Data Generator',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTable,
                    decoration: const InputDecoration(
                      labelText: 'Table',
                      border: OutlineInputBorder(),
                    ),
                    items: _availableTables.map((table) {
                      return DropdownMenuItem(
                        value: table,
                        child: Text(table),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTable = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _recordCount.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Record Count',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _recordCount = int.tryParse(value) ?? 10;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    widget.onGenerateData(_selectedTable, _recordCount),
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Generate Test Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
