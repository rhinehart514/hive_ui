import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/features/spaces/utils/space_duplicate_merger.dart';
import 'package:hive_ui/firebase_options.dart';
import 'dart:async';

/// One-time use tool to merge duplicate spaces across different space types
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Wrap in a basic Material app to allow Flutter to run
  runApp(MaterialApp(
    home: const SpaceMergerTool(),
    theme: ThemeData.dark().copyWith(
      primaryColor: Colors.amber[800],
      colorScheme: ColorScheme.dark(
        primary: Colors.amber[800]!,
        secondary: Colors.amber[600]!,
      ),
    ),
  ));
}

/// Simple UI to execute the space merger tool
class SpaceMergerTool extends StatefulWidget {
  const SpaceMergerTool({Key? key}) : super(key: key);

  @override
  _SpaceMergerToolState createState() => _SpaceMergerToolState();
}

class _SpaceMergerToolState extends State<SpaceMergerTool> {
  bool _isRunning = false;
  bool _isDone = false;
  String _log = '';
  final _logController = StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();

    // Set up listener for log stream
    _logController.stream.listen((message) {
      setState(() {
        _log += '$message\n';
      });
    });

    // Replace debugPrint with our custom logger
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        _logController.add(message);
      }
      // Still call the original function
      originalDebugPrint(message, wrapWidth: wrapWidth);
    };
  }

  /// Run the merger process
  Future<void> _runMerger() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _log = '';
    });

    try {
      _logController.add('Starting space merger process...');

      // Run the merger
      await SpaceDuplicateMerger.runFullMergeProcess();

      _logController.add('Space merger process completed successfully!');
    } catch (e) {
      _logController.add('Error running space merger: $e');
    } finally {
      setState(() {
        _isRunning = false;
        _isDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Space Merger Tool'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Space Duplicate Merger Tool',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This tool will find and merge duplicate spaces across different space types.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRunning ? null : _runMerger,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[800],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isRunning
                  ? 'Running...'
                  : _isDone
                      ? 'Run Again'
                      : 'Run Space Merger'),
            ),
            const SizedBox(height: 24),
            Text(
              'Process Log:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log.isEmpty
                        ? 'Logs will appear here when you run the tool.'
                        : _log,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.lightGreenAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Close the stream controller
    _logController.close();
    super.dispose();
  }
}
