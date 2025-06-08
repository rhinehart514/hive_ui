import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart' show kIsWeb;

/// A utility class for capturing and comparing visual appearance of UI components
/// across iOS and Web platforms to ensure consistent design implementation.
class VisualComparisonTester {
  /// Maps component identifiers to their widget builders
  final Map<String, WidgetBuilder> _componentBuilders = {};
  
  /// Directory to store comparison results
  late final Directory _outputDir;
  
  /// Initialize the tester with output directory
  Future<void> initialize() async {
    final tempDir = await getTemporaryDirectory();
    _outputDir = Directory('${tempDir.path}/visual_tests');
    if (!await _outputDir.exists()) {
      await _outputDir.create(recursive: true);
    }
    
    // Register standard components for testing
    registerComponent('primary_button', _buildPrimaryButton);
    registerComponent('card_surface', _buildCardSurface);
    registerComponent('tab_bar', _buildTabBar);
    registerComponent('modal_sheet', _buildModalSheet);
    registerComponent('input_field', _buildInputField);
  }
  
  /// Register a component for testing
  void registerComponent(String identifier, WidgetBuilder builder) {
    _componentBuilders[identifier] = builder;
  }
  
  /// Run visual comparison tests for all registered components
  Future<void> runVisualComparisonTests(WidgetTester tester) async {
    for (final component in _componentBuilders.keys) {
      await _captureAndCompareComponent(tester, component);
    }
  }
  
  /// Capture and compare a specific component
  Future<void> _captureAndCompareComponent(
    WidgetTester tester, 
    String componentId
  ) async {
    if (!_componentBuilders.containsKey(componentId)) {
      throw Exception('Component $componentId not registered');
    }
    
    // Build the component
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          // HIVE theme settings
          scaffoldBackgroundColor: const Color(0xFF121212),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFEEB700),
            surface: Color(0xFF1E1E1E),
          ),
        ),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => _componentBuilders[componentId]!(context),
            ),
          ),
        ),
      )
    );
    
    // Wait for animations to complete
    await tester.pumpAndSettle();
    
    // Capture component image
    final capture = await _captureComponent(tester);
    
    // Save the capture
    final platform = kIsWeb ? 'web' : Platform.isIOS ? 'ios' : 'android';
    final filePath = '${_outputDir.path}/${componentId}_$platform.png';
    
    final file = File(filePath);
    await file.writeAsBytes(capture);
    
    print('Captured $componentId on $platform: $filePath');
    
    // If we have both iOS and web captures, compare them
    if (platform == 'web') {
      final iosFilePath = '${_outputDir.path}/${componentId}_ios.png';
      final iosFile = File(iosFilePath);
      
      if (await iosFile.exists()) {
        final difference = await _compareImages(
          await iosFile.readAsBytes(), 
          capture
        );
        
        print('Comparison result for $componentId: ${difference.toStringAsFixed(2)}% difference');
        
        // Save difference visualization if significant
        if (difference > 5.0) {
          final diffFilePath = '${_outputDir.path}/${componentId}_diff.png';
          await _saveDifferenceImage(iosFilePath, filePath, diffFilePath);
          print('Difference visualization saved to $diffFilePath');
        }
      }
    }
  }
  
  /// Capture a screenshot of the current widget
  Future<Uint8List> _captureComponent(WidgetTester tester) async {
    final renderObject = tester.renderObject(find.byType(MaterialApp));
    final painter = renderObject as RenderRepaintBoundary;
    final image = await painter.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
  
  /// Compare two images and return the percentage difference
  Future<double> _compareImages(Uint8List image1Bytes, Uint8List image2Bytes) async {
    final image1 = img.decodeImage(image1Bytes);
    final image2 = img.decodeImage(image2Bytes);
    
    if (image1 == null || image2 == null) {
      throw Exception('Failed to decode images for comparison');
    }
    
    // Resize to match dimensions if needed
    final img.Image compareImage1 = image1;
    final img.Image compareImage2 = image2.width != image1.width || image2.height != image1.height 
        ? img.copyResize(image2, width: image1.width, height: image1.height) 
        : image2;
    
    int differentPixels = 0;
    final totalPixels = compareImage1.width * compareImage1.height;
    
    for (int y = 0; y < compareImage1.height; y++) {
      for (int x = 0; x < compareImage1.width; x++) {
        final pixel1 = compareImage1.getPixel(x, y);
        final pixel2 = compareImage2.getPixel(x, y);
        
        if (pixel1 != pixel2) {
          differentPixels++;
        }
      }
    }
    
    return (differentPixels / totalPixels) * 100.0;
  }
  
  /// Save a visualization of the difference between two images
  Future<void> _saveDifferenceImage(
    String image1Path, 
    String image2Path, 
    String outputPath
  ) async {
    // This would typically use a tool like ImageMagick or a Flutter-compatible
    // image processing library to create a visual diff
    // For simplicity, we're mocking this functionality
    
    // In a real implementation, you would:
    // 1. Load both images
    // 2. Create a new image highlighting differences
    // 3. Save the resulting difference visualization
    
    print('Creating difference visualization (mock implementation)');
  }
  
  // Component builder methods
  
  Widget _buildPrimaryButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        minimumSize: const Size(150, 36),
      ),
      onPressed: () {},
      child: const Text('Primary Button'),
    );
  }
  
  Widget _buildCardSurface(BuildContext context) {
    return Container(
      width: 280,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card Title',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This is a card surface component with proper styling according to HIVE design system.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: Colors.black,
      child: TabBar(
        tabs: const [
          Tab(text: 'Feed'),
          Tab(text: 'Spaces'),
          Tab(text: 'Events'),
        ],
        controller: TabController(length: 3, vsync: const TestVSync()),
        indicator: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFEEB700),
              width: 2,
            ),
          ),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
      ),
    );
  }
  
  Widget _buildModalSheet(BuildContext context) {
    return Container(
      width: 360,
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: SizedBox(
              width: 40,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF808080),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Modal Title',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This is a modal sheet component with proper styling according to HIVE design guidelines.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {},
              child: const Text('Close Modal'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInputField(BuildContext context) {
    return SizedBox(
      width: 280,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Enter text',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
          ),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFFEEB700),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}

// Test visualization class for mocking animations within tests
class TestVSync extends TickerProvider {
  const TestVSync();
  
  @override
  Ticker createTicker(onTick) => Ticker(onTick);
}

// Main test function
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Visual comparison test for core UI components', (tester) async {
    final visualTester = VisualComparisonTester();
    await visualTester.initialize();
    await visualTester.runVisualComparisonTests(tester);
  });
} 