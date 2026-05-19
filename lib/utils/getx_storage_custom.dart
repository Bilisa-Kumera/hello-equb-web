import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:helloequb/models/ekub_category_model.dart';
import 'package:intl/intl.dart';

class DataController extends GetxController {
  static final GetStorage _storage = GetStorage();

  // In-memory cache for synchronous access
  final Map<String, dynamic> _cache = {};
  bool _cacheInitialized = false;
  bool _isInitializing = false;

  DataController() {
    // Start initialization immediately when controller is created
    _ensureCacheInitialized();
  }

  // Initialize cache by loading all data from secure storage
  Future<void> _ensureCacheInitialized() async {
    if (_cacheInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      // First, load critical keys that are checked immediately on app start
      // This ensures they're available when splash screen checks them
      final criticalKeys = [
        'accessToken',
        'isLoggedIn',
        'isFirstTime',
        'userId'
      ];
      for (final key in criticalKeys) {
        try {
          final value = _storage.read(key);
          if (value != null) {
            _cache[key] = _deserializeValue(value);
          }
        } catch (e) {
          // Ignore individual key errors
        }
      }

      // Then load all remaining keys
      final allKeys = _storage.getKeys();
      for (var key in allKeys) {
        // Skip if already loaded as critical key
        if (!criticalKeys.contains(key)) {
          try {
            final value = _storage.read(key);
            if (value != null) {
              _cache[key] = _deserializeValue(value);
            }
          } catch (e) {
            // If deserialization fails, try storing as string
            _cache[key] = _storage.read(key);
          }
        }
      }
      _cacheInitialized = true;
    } catch (e) {
      // If readAll fails (e.g., on older Android versions), mark as initialized
      // Individual reads will still work
      _cacheInitialized = true;
    } finally {
      _isInitializing = false;
    }
  }

  // Synchronously ensure cache is initialized (for synchronous methods)
  void _ensureCacheInitializedSync() {
    if (!_cacheInitialized && !_isInitializing) {
      // Start async initialization but don't wait
      _ensureCacheInitialized();
    }
  }

  // Try to read a value directly from storage if cache isn't ready
  Future<dynamic> _readFromStorage(String key) async {
    try {
      final value = _storage.read(key);
      if (value != null) {
        final deserialized = _deserializeValue(value);
        // Update cache for future reads
        _cache[key] = deserialized;
        return deserialized;
      }
    } catch (e) {
      // Ignore errors, return null
    }
    return null;
  }

  // Serialize value for GetStorage (GetStorage handles serialization automatically)
  dynamic _serializeValue(dynamic value) {
    // GetStorage can handle most types directly
    return value;
  }

  // Deserialize value from GetStorage
  dynamic _deserializeValue(dynamic value) {
    if (value == null) return null;
    // GetStorage already deserializes JSON, so return as-is
    return value;
  }

  // Store data of any type
  void storeData<T>(String key, T value) {
    _ensureCacheInitializedSync();
    _cache[key] = value;
    update(); // Notify listeners of data change

    // Write to GetStorage asynchronously
    final serialized = _serializeValue(value);
    _storage.write(key, serialized);
  }

  // Retrieve data of any type
  T? retrieveData<T>(String key) {
    _ensureCacheInitializedSync();

    // Check cache first
    if (_cache.containsKey(key)) {
      final value = _cache[key];
      if (value == null) return null;

      // Handle type conversion
      if (T == String && value is! String) {
        return value.toString() as T;
      }
      if (T == int && value is num) {
        return value.toInt() as T;
      }
      if (T == double && value is num) {
        return value.toDouble() as T;
      }
      if (T == bool && value is bool) {
        return value as T;
      }

      return value as T?;
    }

    // If cache is not initialized yet and this is a critical key,
    // try to read directly from storage synchronously (with a small delay)
    // Critical keys are loaded first during initialization, so they should be available
    if (!_cacheInitialized && _isInitializing) {
      // For critical keys, they should already be in cache from prioritized loading
      // If not, start async read for next access
      _readFromStorage(key).then((value) {
        if (value != null && !_cache.containsKey(key)) {
          _cache[key] = value;
        }
      });
    } else if (!_cacheInitialized && !_isInitializing) {
      // Start async read for next time
      _readFromStorage(key).then((value) {
        if (value != null && !_cache.containsKey(key)) {
          _cache[key] = value;
        }
      });
    }

    return null;
  }

  // Update data of any type
  void updateData<T>(String key, T value) {
    if (hasData(key)) {
      storeData(key, value);
    }
  }

  // Check if data exists
  bool hasData(String key) {
    _ensureCacheInitializedSync();
    return _cache.containsKey(key) && _cache[key] != null;
  }

  // Delete data
  void deleteData(String key) {
    _ensureCacheInitializedSync();
    _cache.remove(key);
    update(); // Notify listeners of data change

    // Delete from GetStorage
    _storage.remove(key);
  }

  // Add an ID to a list stored under a specific key
  void addIdToList(String key, String id) {
    _ensureCacheInitializedSync();
    List<String> ids =
        (_cache[key] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            [];
    if (!ids.contains(id)) {
      ids.add(id);
      _cache[key] = ids;
      update(); // Notify listeners of data change

      // Write to GetStorage
      final serialized = _serializeValue(ids);
      _storage.write(key, serialized);
    }
  }

  // Retrieve the list of IDs
  List<String>? getIds(String key) {
    _ensureCacheInitializedSync();
    final value = _cache[key];
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  // Remove an ID from the list
  void removeIdFromList(String key, String id) {
    _ensureCacheInitializedSync();
    final value = _cache[key];
    if (value is List) {
      List<String> ids = value.map((e) => e.toString()).toList();
      if (ids.contains(id)) {
        ids.remove(id);
        _cache[key] = ids;
        update(); // Notify listeners of data change

        // Write to GetStorage
        final serialized = _serializeValue(ids);
        _storage.write(key, serialized);
      }
    }
  }

  Future<void> saveEkubCategories(List<EqubCategorys> categories) async {
    _ensureCacheInitializedSync();
    List<Map<String, dynamic>> jsonList =
        categories.map((category) => category.toJson()).toList();
    _cache['ekubCategories'] = jsonList;

    // Write to GetStorage
    final serialized = _serializeValue(jsonList);
    _storage.write('ekubCategories', serialized);
  }

  // Store the target date in persistent storage
  void setTargetDate(DateTime targetDateTime) {
    storeData('targetDate', targetDateTime.toIso8601String());
  }

  // Retrieve the target date from persistent storage
  DateTime getTargetDate() {
    final dateString = retrieveData<String>('targetDate');
    return dateString != null
        ? DateTime.parse(dateString)
        : DateTime.now().add(Duration(days: 1)); // Default target date
  }

  // Calculate the remaining time
  Duration getRemainingTime() {
    final now = DateTime.now();
    final targetDateTime = getTargetDate();
    final duration = targetDateTime.difference(now);
    return duration.isNegative ? Duration.zero : duration;
  }

  // Helper method to format the target date
  String getFormattedTargetDate() {
    return DateFormat('MMMM d').format(getTargetDate());
  }

  // Initialize cache on app start (call this in main or splash screen)
  Future<void> initialize() async {
    await _ensureCacheInitialized();
  }
}
