import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:hive_ui/domain/usecases/username_collision_detection_usecase.dart';

/// Use case for generating a username based on the user's name
class GenerateUsernameUseCase {
  final UsernameCollisionDetectionUseCase _usernameCollisionDetectionUseCase;
  
  /// Creates a new instance with the given use case
  GenerateUsernameUseCase(this._usernameCollisionDetectionUseCase);
  
  /// Executes the use case to generate a username
  /// 
  /// Takes a first name and last name and generates a slugified username
  /// with a random suffix. Handles collisions by adding a different suffix.
  Future<Result<String, Failure>> execute(String firstName, String lastName) async {
    try {
      // Validate inputs
      if (firstName.isEmpty || lastName.isEmpty) {
        return const Result.left(AuthFailure('First name and last name are required'));
      }
      
      // Slugify the name parts
      final slug = _slugify('$firstName $lastName');
      
      // Generate a 4-digit random suffix
      final randomSuffix = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
      final username = '${slug}_$randomSuffix';
      
      // Check if username is already taken
      final checkResult = await _usernameCollisionDetectionUseCase.isUsernameTaken(username);
      
      if (checkResult.isFailure) {
        return Result.left(checkResult.getFailure);
      }
      
      final isTaken = checkResult.getSuccess;
      
      if (isTaken) {
        // Handle collision by generating an alternative
        return await _usernameCollisionDetectionUseCase.generateAlternativeUsername(slug);
      }
      
      return Result.right(username);
    } catch (e) {
      return Result.left(ServerFailure('Failed to generate username: ${e.toString()}'));
    }
  }
  
  /// Slugifies a string by removing special characters, converting to lowercase,
  /// and replacing spaces with underscores
  String _slugify(String input) {
    if (input.isEmpty) {
      return '';
    }
    
    // Convert to lowercase
    var slug = input.toLowerCase();
    
    // Replace non-alphanumeric characters with underscore
    slug = slug.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    
    // Replace multiple underscores with a single one
    slug = slug.replaceAll(RegExp(r'_+'), '_');
    
    // Remove leading and trailing underscores
    slug = slug.replaceAll(RegExp(r'^_+|_+$'), '');
    
    // Handle special cases
    if (slug.isEmpty) {
      return 'user';
    }
    
    // Ensure slug is not too long
    if (slug.length > 15) {
      slug = slug.substring(0, 15);
    }
    
    return slug;
  }
} 