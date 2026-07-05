import '../models/property.dart';

class CompareService {
  static final List<String> _compareIds = [];
  static final List<Property> _compareProperties = [];

  static List<String> get compareIds => List.unmodifiable(_compareIds);
  static List<Property> get compareProperties => List.unmodifiable(_compareProperties);

  static bool isInCompare(String propertyId) => _compareIds.contains(propertyId);

  static void toggle(String propertyId, [Property? property]) {
    if (_compareIds.contains(propertyId)) {
      _compareIds.remove(propertyId);
      _compareProperties.removeWhere((p) => p.id == propertyId);
    } else {
      _compareIds.add(propertyId);
      if (property != null) _compareProperties.add(property);
    }
  }

  static void clear() {
    _compareIds.clear();
    _compareProperties.clear();
  }
}
