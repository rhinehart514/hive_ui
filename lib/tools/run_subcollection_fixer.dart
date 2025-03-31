import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/utils/space_subcollection_fixer.dart';
import 'package:hive_ui/firebase_options.dart';

/// A standalone tool to fix events in space subcollections
/// This is separate from the space cleanup process and focuses specifically on
/// ensuring proper synchronization between main event collection and space subcollections.
///
/// Run with: flutter run -t lib/tools/run_subcollection_fixer.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SubcollectionFixerApp());
}

class SubcollectionFixerApp extends StatefulWidget {
  const SubcollectionFixerApp({Key? key}) : super(key: key);

  @override
  State<SubcollectionFixerApp> createState() => _SubcollectionFixerAppState();
}

class _SubcollectionFixerAppState extends State<SubcollectionFixerApp> {
  bool _isRunning = false;
  bool _isComplete = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Space Subcollection Fixer'),
          backgroundColor: Colors.black87,
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Card(
                  color: Colors.black87,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Event Subcollection Fixer',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'This tool synchronizes events between the main collection and space subcollections.',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'It ensures events in spaces/type/spaces/spaceId/events/eventId are properly linked.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_isRunning) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_status, textAlign: TextAlign.center),
                ] else ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    onPressed: _isComplete ? null : _runFixer,
                    child: Text(
                      _isComplete
                          ? 'Process Complete'
                          : 'Run Subcollection Fixer',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isComplete)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Space subcollection fix process completed!'),
                        ],
                      ),
                    )
                ],
                const SizedBox(height: 32),
                const Card(
                  color: Colors.black87,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Notes:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text(
                            '• This is a standalone tool separate from the space cleanup process'),
                        Text(
                            '• View debug console for detailed logs of all operations'),
                        Text(
                            '• The process may take several minutes depending on database size'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _runFixer() async {
    setState(() {
      _isRunning = true;
      _status = 'Starting subcollection fix process...';
    });

    try {
      // Step 1: Fix existing subcollections
      setState(() {
        _status = 'Finding events in space subcollections...';
      });
      await SpaceSubcollectionFixer.fixSpaceEventSubcollections();

      // Step 2: Sync events from main collection to subcollections
      setState(() {
        _status =
            'Syncing events from main collection to space subcollections...';
      });
      await SpaceSubcollectionFixer.syncEventsToSubcollections();

      setState(() {
        _isComplete = true;
        _status = 'Process completed successfully!';
      });
    } catch (error) {
      setState(() {
        _status = 'Error: $error';
      });
      debugPrint('Error running subcollection fixer: $error');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }
}
