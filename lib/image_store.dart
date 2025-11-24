import 'dart:typed_data';
import 'package:hive/hive.dart';

class ImageStore {
  static const String boxName = 'report_images';

  static Box<Uint8List> get _box => Hive.box<Uint8List>(boxName) as Box<Uint8List>;

  static Future<void> saveReportImage(String reportId, Uint8List bytes) async {
    await _box.put(reportId, bytes);
  }

  static Uint8List? loadReportImageSync(String reportId) {
    return _box.get(reportId) as Uint8List?;
  }

  static bool hasImageSync(String reportId) {
    return _box.containsKey(reportId);
  }

  static Future<void> deleteReportImage(String reportId) async {
    await _box.delete(reportId);
  }
}
