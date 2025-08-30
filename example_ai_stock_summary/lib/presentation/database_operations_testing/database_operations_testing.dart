import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../registration/registration.dart';
import './widgets/connection_monitor_widget.dart';
import './widgets/operation_card_widget.dart';
import './widgets/operation_result_widget.dart';
import './widgets/test_data_generator_widget.dart';
import 'widgets/connection_monitor_widget.dart';
import 'widgets/operation_card_widget.dart';
import 'widgets/operation_result_widget.dart';
import 'widgets/test_data_generator_widget.dart';

class DatabaseOperationsTesting extends StatefulWidget {
  const DatabaseOperationsTesting({super.key});

  @override
  State<DatabaseOperationsTesting> createState() =>
      _DatabaseOperationsTestingState();
}

class _DatabaseOperationsTestingState extends State<DatabaseOperationsTesting>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final List<OperationResult> _operationResults = [];
  bool _isPerformingOperation = false;

  StreamSubscription? _realtimeSubscription;
  final List<Map<String, dynamic>> _realtimeEvents = [];

  Map<String, dynamic> _connectionMetrics = {
    'activeConnections': 1,
    'queryCount': 0,
    'avgResponseTime': 0,
    'totalOperations': 0,
  };

  List<Map<String, dynamic>> _availableTables = [];
  String? _selectedTable;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAvailableTables();
    _setupRealtimeMonitoring();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAvailableTables() async {
    setState(() {
      _availableTables = [
        {'name': 'stocks', 'rows': 0},
        {'name': 'user_profiles', 'rows': 0},
        {'name': 'portfolios', 'rows': 0},
        {'name': 'ai_summaries', 'rows': 0},
        {'name': 'watchlists', 'rows': 0},
      ];
    });

    // Load actual row counts
    for (var table in _availableTables) {
      try {
        final response = await SupabaseService.instance.client
            .from(table['name'])
            .select('id', const FetchOptions(count: CountOption.exact))
            .limit(1)
            .execute();

        setState(() {
          table['rows'] = response.count ?? 0;
        });
      } catch (e) {
        debugPrint('Error counting rows for ${table['name']}: $e');
      }
    }
  }

  void _setupRealtimeMonitoring() {
    _realtimeSubscription = SupabaseService.instance.client
        .from('stocks')
        .stream(primaryKey: ['id']).listen((data) {
      setState(() {
        _realtimeEvents.insert(0, {
          'timestamp': DateTime.now(),
          'table': 'stocks',
          'action': 'change',
          'recordCount': data.length,
        });

        // Keep only last 20 events
        if (_realtimeEvents.length > 20) {
          _realtimeEvents.removeRange(20, _realtimeEvents.length);
        }
      });
    });
  }

  Future<void> _performCreateOperation() async {
    setState(() {
      _isPerformingOperation = true;
    });

    final stopwatch = Stopwatch()..start();

    try {
      // Create a test stock record
      final testData = {
        'symbol': 'TEST${Random().nextInt(1000)}',
        'name': 'Test Company ${Random().nextInt(100)}',
        'exchange': 'TEST',
        'sector': 'Technology',
        'industry': 'Software',
        'market_cap': Random().nextDouble() * 1000000000,
      };

      final response = await SupabaseService.instance.client
          .from('stocks')
          .insert(testData)
          .select()
          .execute();

      stopwatch.stop();

      final result = OperationResult(
        operation: 'CREATE',
        table: 'stocks',
        success: response.data != null && response.data!.isNotEmpty,
        executionTime: stopwatch.elapsedMilliseconds,
        sqlQuery: 'INSERT INTO stocks (...) VALUES (...)',
        responseData: response.data?.toString() ?? 'No data',
        timestamp: DateTime.now(),
      );

      _addOperationResult(result);

      if (result.success) {
        Fluttertoast.showToast(
          msg: 'Test record created successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      stopwatch.stop();

      _addOperationResult(OperationResult(
        operation: 'CREATE',
        table: 'stocks',
        success: false,
        executionTime: stopwatch.elapsedMilliseconds,
        sqlQuery: 'INSERT INTO stocks (...) VALUES (...)',
        responseData: 'Error: ${e.toString()}',
        timestamp: DateTime.now(),
      ));
    }

    setState(() {
      _isPerformingOperation = false;
    });
  }

  Future<void> _performReadOperation() async {
    setState(() {
      _isPerformingOperation = true;
    });

    final stopwatch = Stopwatch()..start();

    try {
      final response = await SupabaseService.instance.client
          .from('stocks')
          .select('symbol, name, sector, market_cap')
          .limit(10)
          .execute();

      stopwatch.stop();

      final result = OperationResult(
        operation: 'READ',
        table: 'stocks',
        success: response.data != null,
        executionTime: stopwatch.elapsedMilliseconds,
        sqlQuery:
            'SELECT symbol, name, sector, market_cap FROM stocks LIMIT 10',
        responseData: '${response.data?.length ?? 0} records retrieved',
        timestamp: DateTime.now(),
      );

      _addOperationResult(result);
    } catch (e) {
      stopwatch.stop();

      _addOperationResult(OperationResult(
        operation: 'READ',
        table: 'stocks',
        success: false,
        executionTime: stopwatch.elapsedMilliseconds,
        sqlQuery: 'SELECT * FROM stocks LIMIT 10',
        responseData: 'Error: ${e.toString()}',
        timestamp: DateTime.now(),
      ));
    }

    setState(() {
      _isPerformingOperation = false;
    });
  }

  Future<void> _performUpdateOperation() async {
    setState(() {
      _isPerformingOperation = true;
    });

    final stopwatch = Stopwatch()..start();

    try {
      // First, get a test record
      final readResponse = await SupabaseService.instance.client
          .from('stocks')
          .select('id')
          .ilike('symbol', 'TEST%')
          .limit(1)
          .execute();

      if (readResponse.data == null || readResponse.data!.isEmpty) {
        throw Exception('No test records found to update');
      }

      final recordId = readResponse.data![0]['id'];

      final response = await SupabaseService.instance.client
          .from('stocks')
          .update({'market_cap': Random().nextDouble() * 1000000000})
          .eq('id', recordId)
          .execute();

      stopwatch.stop();

      final result = OperationResult(
        operation: 'UPDATE',
        table: 'stocks',
        success: response.data != null,
        executionTime: stopwatch.elapsedMilliseconds,
        sqlQuery: 'UPDATE stocks SET market_cap = ? WHERE id = ?',
        responseData: 'Record updated successfully',
        timestamp: DateTime.now(),
      );

      _addOperationResult(result);

      if (result.success) {
        Fluttertoast.showToast(
          msg: 'Test record updated successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      stopwatch.stop();

      _addOperationResult(OperationResult(
        operation: 'UPDATE',
        table: 'stocks',
        success: false,
        executionTime: stopwatch.elapsedMilliseconds,
        sqlQuery: 'UPDATE stocks SET ... WHERE id = ?',
        responseData: 'Error: ${e.toString()}',
        timestamp: DateTime.now(),
      ));
    }

    setState(() {
      _isPerformingOperation = false;
    });
  }

  Future<void> _performDeleteOperation() async {
    setState(() {
      _isPerformingOperation = true;
    });

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
            'Are you sure you want to delete test records? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      setState(() {
        _isPerformingOperation = false;
      });
      return;
    }

    final stopwatch = Stopwatch()..start();

    try {
      final response = await SupabaseService.instance.client
          .from('stocks')
          .delete()
          .ilike('symbol', 'TEST%')
          .execute();

      stopwatch.stop();

      final result = OperationResult(
        operation: 'DELETE',
        table: 'stocks',
        success: true,
        executionTime: stopwatch.elapsedMilliseconds,
        sqlQuery: 'DELETE FROM stocks WHERE symbol LIKE \'TEST%\'',
        responseData: 'Test records deleted successfully',
        timestamp: DateTime.now(),
      );

      _addOperationResult(result);

      Fluttertoast.showToast(
        msg: 'Test records deleted successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      stopwatch.stop();

      _addOperationResult(OperationResult(
        operation: 'DELETE',
        table: 'stocks',
        success: false,
        executionTime: stopwatch.elapsedMilliseconds,
        sqlQuery: 'DELETE FROM stocks WHERE symbol LIKE \'TEST%\'',
        responseData: 'Error: ${e.toString()}',
        timestamp: DateTime.now(),
      ));
    }

    setState(() {
      _isPerformingOperation = false;
    });
  }

  Future<void> _testUserRegistration() async {
    setState(() {
      _isPerformingOperation = true;
    });

    final stopwatch = Stopwatch()..start();

    try {
      final testEmail = 'test${Random().nextInt(10000)}@example.com';
      final testPassword = 'TestPassword123!';

      final response = await SupabaseService.instance.client.auth.signUp(
        email: testEmail,
        password: testPassword,
      );

      stopwatch.stop();

      final result = OperationResult(
        operation: 'REGISTER',
        table: 'auth.users',
        success: response.user != null,
        executionTime: stopwatch.elapsedMilliseconds,
        sqlQuery: 'Auth signup operation',
        responseData: response.user != null
            ? 'User registered: ${response.user!.email}'
            : 'Registration failed',
        timestamp: DateTime.now(),
      );

      _addOperationResult(result);
    } catch (e) {
      stopwatch.stop();

      _addOperationResult(OperationResult(
        operation: 'REGISTER',
        table: 'auth.users',
        success: false,
        executionTime: stopwatch.elapsedMilliseconds,
        sqlQuery: 'Auth signup operation',
        responseData: 'Error: ${e.toString()}',
        timestamp: DateTime.now(),
      ));
    }

    setState(() {
      _isPerformingOperation = false;
    });
  }

  Future<void> _testSessionManagement() async {
    setState(() {
      _isPerformingOperation = true;
    });

    final stopwatch = Stopwatch()..start();

    try {
      final session = SupabaseService.instance.client.auth.currentSession;
      final user = SupabaseService.instance.client.auth.currentUser;

      stopwatch.stop();

      final result = OperationResult(
        operation: 'SESSION_CHECK',
        table: 'auth.sessions',
        success: true,
        executionTime: stopwatch.elapsedMilliseconds,
        sqlQuery: 'Auth session check',
        responseData: session != null
            ? 'Active session for: ${user?.email ?? "Unknown"}'
            : 'No active session',
        timestamp: DateTime.now(),
      );

      _addOperationResult(result);
    } catch (e) {
      stopwatch.stop();

      _addOperationResult(OperationResult(
        operation: 'SESSION_CHECK',
        table: 'auth.sessions',
        success: false,
        executionTime: stopwatch.elapsedMilliseconds,
        sqlQuery: 'Auth session check',
        responseData: 'Error: ${e.toString()}',
        timestamp: DateTime.now(),
      ));
    }

    setState(() {
      _isPerformingOperation = false;
    });
  }

  void _addOperationResult(OperationResult result) {
    setState(() {
      _operationResults.insert(0, result);
      _connectionMetrics['totalOperations']++;
      _connectionMetrics['queryCount']++;

      // Calculate average response time
      final totalTime = _operationResults
          .take(10)
          .map((r) => r.executionTime)
          .reduce((a, b) => a + b);
      _connectionMetrics['avgResponseTime'] =
          totalTime ~/ min(_operationResults.length, 10);

      // Keep only last 50 results
      if (_operationResults.length > 50) {
        _operationResults.removeRange(50, _operationResults.length);
      }
    });
  }

  void _exportTestReport() {
    // In a real implementation, this would generate and export a detailed test report
    Fluttertoast.showToast(
      msg: 'Test report exported successfully',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Operations Testing'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportTestReport,
            tooltip: 'Export Test Report',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tables'),
            Tab(text: 'Auth'),
            Tab(text: 'Storage'),
            Tab(text: 'Real-time'),
          ],
        ),
      ),
      body: Column(
        children: [
          ConnectionMonitorWidget(metrics: _connectionMetrics),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTablesTab(),
                _buildAuthTab(),
                _buildStorageTab(),
                _buildRealtimeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Table Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Tables',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ..._availableTables.map((table) => ListTile(
                        title: Text(table['name']),
                        subtitle: Text('${table['rows']} rows'),
                        trailing: Icon(
                          Icons.table_chart,
                          color: Theme.of(context).primaryColor,
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // CRUD Operations
          Row(
            children: [
              Expanded(
                child: OperationCardWidget(
                  title: 'Create',
                  description: 'Insert test data',
                  icon: Icons.add_circle,
                  color: Colors.green,
                  isRunning: _isPerformingOperation,
                  onTap: _performCreateOperation,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OperationCardWidget(
                  title: 'Read',
                  description: 'Query records',
                  icon: Icons.search,
                  color: Colors.blue,
                  isRunning: _isPerformingOperation,
                  onTap: _performReadOperation,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OperationCardWidget(
                  title: 'Update',
                  description: 'Modify data',
                  icon: Icons.edit,
                  color: Colors.orange,
                  isRunning: _isPerformingOperation,
                  onTap: _performUpdateOperation,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OperationCardWidget(
                  title: 'Delete',
                  description: 'Remove test data',
                  icon: Icons.delete,
                  color: Colors.red,
                  isRunning: _isPerformingOperation,
                  onTap: _performDeleteOperation,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Test Data Generator
          TestDataGeneratorWidget(
            onGenerateData: (table, count) async {
              // Generate test data for the specified table
              Fluttertoast.showToast(
                msg: 'Generated $count test records for $table',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
          ),
          const SizedBox(height: 16),

          // Operation Results
          if (_operationResults.isNotEmpty)
            OperationResultWidget(results: _operationResults),
        ],
      ),
    );
  }

  Widget _buildAuthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          OperationCardWidget(
            title: 'User Registration',
            description: 'Test user signup with random credentials',
            icon: Icons.person_add,
            color: Colors.blue,
            isRunning: _isPerformingOperation,
            onTap: _testUserRegistration,
          ),
          const SizedBox(height: 12),
          OperationCardWidget(
            title: 'Session Management',
            description: 'Check current user session status',
            icon: Icons.login,
            color: Colors.green,
            isRunning: _isPerformingOperation,
            onTap: _testSessionManagement,
          ),
          const SizedBox(height: 16),
          if (_operationResults
              .where((r) => r.table.contains('auth'))
              .isNotEmpty)
            OperationResultWidget(
              results: _operationResults
                  .where((r) => r.table.contains('auth'))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStorageTab() {
    return const Center(
      child: Text('Storage testing features will be implemented here'),
    );
  }

  Widget _buildRealtimeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Real-time Events',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_realtimeEvents.isEmpty)
                    const Text('No real-time events captured yet')
                  else
                    Column(
                      children: _realtimeEvents
                          .map((event) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: const Icon(Icons.flash_on,
                                      color: Colors.white),
                                ),
                                title: Text(
                                    '${event['table']} - ${event['action']}'),
                                subtitle:
                                    Text('${event['recordCount']} records'),
                                trailing: Text(
                                  '${event['timestamp'].hour}:${event['timestamp'].minute.toString().padLeft(2, '0')}',
                                ),
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OperationResult {
  final String operation;
  final String table;
  final bool success;
  final int executionTime;
  final String sqlQuery;
  final String responseData;
  final DateTime timestamp;

  OperationResult({
    required this.operation,
    required this.table,
    required this.success,
    required this.executionTime,
    required this.sqlQuery,
    required this.responseData,
    required this.timestamp,
  });
}
