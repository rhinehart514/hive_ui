import 'package:hive_ui/models/organization.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/event.dart';

/// Utility class for categorizing spaces
class SpaceCategorizer {
  /// Common keywords associated with student organizations
  static const List<String> _studentOrgKeywords = [
    'student',
    'club',
    'society',
    'association',
    'team',
    'group',
    'council',
    'committee',
    'undergraduate',
    'graduate',
    'members',
    'honors'
  ];

  /// Common keywords associated with university organizations
  static const List<String> _universityOrgKeywords = [
    'department',
    'division',
    'faculty',
    'school',
    'college',
    'institute',
    'center',
    'academy',
    'program',
    'education',
    'academic',
    'administration',
    'research'
  ];

  /// Common keywords associated with campus living
  static const List<String> _campusLivingKeywords = [
    'residence',
    'housing',
    'dormitory',
    'dorm',
    'hall',
    'apartment',
    'flat',
    'accommodation',
    'living',
    'community',
    'village',
    'quarter',
    'suite'
  ];

  /// Common keywords associated with fraternity and sorority
  static const List<String> _fraternityAndSororityKeywords = [
    'fraternity',
    'sorority',
    'frat',
    'greek',
    'alpha',
    'beta',
    'gamma',
    'delta',
    'epsilon',
    'zeta',
    'eta',
    'theta',
    'iota',
    'kappa',
    'lambda',
    'mu',
    'nu',
    'xi',
    'omicron',
    'pi',
    'rho',
    'sigma',
    'tau',
    'upsilon',
    'phi',
    'chi',
    'psi',
    'omega',
    'panhellenic',
    'interfraternity',
    'multicultural'
  ];

  /// Determine the space type based on organization name and description
  static SpaceType categorizeOrganization(Organization org) {
    final String lowerName = org.name.toLowerCase();
    final String lowerDescription = org.description.toLowerCase();
    final String combinedText = '$lowerName $lowerDescription';

    // Check fraternity and sorority first since they have very specific keywords
    if (_checkKeywords(combinedText, _fraternityAndSororityKeywords)) {
      return SpaceType.fraternityAndSorority;
    }

    // Check if it's a university organization
    if (org.isOfficial ||
        org.isUniversityDepartment ||
        _checkKeywords(combinedText, _universityOrgKeywords)) {
      return SpaceType.universityOrg;
    }

    // Check if it's related to campus living
    if (_checkKeywords(combinedText, _campusLivingKeywords)) {
      return SpaceType.campusLiving;
    }

    // Default to student org if it has student-related keywords
    if (_checkKeywords(combinedText, _studentOrgKeywords)) {
      return SpaceType.studentOrg;
    }

    // Otherwise categorize as other
    return SpaceType.other;
  }

  /// Determine the space type based on club information
  static SpaceType categorizeClub(Club club) {
    final String lowerName = club.name.toLowerCase();
    final String lowerDescription = club.description.toLowerCase();
    final String combinedText = '$lowerName $lowerDescription';

    // Check categories from the club data first
    final String lowerCategories = club.categories.join(' ').toLowerCase();

    if (lowerCategories.contains('fraternity') ||
        lowerCategories.contains('sorority') ||
        lowerCategories.contains('greek')) {
      return SpaceType.fraternityAndSorority;
    }

    if (lowerCategories.contains('housing') ||
        lowerCategories.contains('residence') ||
        lowerCategories.contains('campus living')) {
      return SpaceType.campusLiving;
    }

    if (club.isOfficial ||
        lowerCategories.contains('department') ||
        lowerCategories.contains('university')) {
      return SpaceType.universityOrg;
    }

    // Fall back to text analysis if categories don't determine the type
    if (_checkKeywords(combinedText, _fraternityAndSororityKeywords)) {
      return SpaceType.fraternityAndSorority;
    }

    if (_checkKeywords(combinedText, _campusLivingKeywords)) {
      return SpaceType.campusLiving;
    }

    if (_checkKeywords(combinedText, _universityOrgKeywords) ||
        club.isOfficial) {
      return SpaceType.universityOrg;
    }

    // Default to student org if nothing else matches
    return SpaceType.studentOrg;
  }

  /// Determine the space type based on event information
  static SpaceType categorizeFromEvent(Event event) {
    final String lowerOrgName = event.organizerName.toLowerCase();
    final String lowerCategory = event.category.toLowerCase();
    final String lowerDescription = event.description.toLowerCase();
    final String combinedText =
        '$lowerOrgName $lowerCategory $lowerDescription';

    // Check if any fraternity/sorority keywords present
    if (_checkKeywords(combinedText, _fraternityAndSororityKeywords)) {
      return SpaceType.fraternityAndSorority;
    }

    // Check if it's related to campus living
    if (_checkKeywords(combinedText, _campusLivingKeywords)) {
      return SpaceType.campusLiving;
    }

    // Check if it's a university organization
    if (_checkKeywords(combinedText, _universityOrgKeywords) ||
        lowerOrgName.contains('university') ||
        lowerOrgName.contains('department') ||
        lowerOrgName.contains('office of')) {
      return SpaceType.universityOrg;
    }

    // Default to student org if it has student-related keywords
    if (_checkKeywords(combinedText, _studentOrgKeywords)) {
      return SpaceType.studentOrg;
    }

    // Otherwise categorize as other
    return SpaceType.other;
  }

  /// Helper method to check if text contains any of the keywords
  static bool _checkKeywords(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
