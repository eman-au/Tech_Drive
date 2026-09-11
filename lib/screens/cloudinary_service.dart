import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "dqbbi53py";
  static const String uploadPreset = "unsigned_worker_upload"; // ✅ CORRECT PRESET NAME

  static Future<String?> uploadImage(File file) async {
    try {
      print("📤 [Cloudinary] Starting upload...");
      print("📤 [Cloudinary] File path: ${file.path}");

      final exists = await file.exists();
      print("📤 [Cloudinary] File exists: $exists");
      print("📤 [Cloudinary] File size: ${await file.length()} bytes");

      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      final request = http.MultipartRequest("POST", uri);
      request.fields['upload_preset'] = uploadPreset;

      // Add the file
      final multipartFile = await http.MultipartFile.fromPath("file", file.path);
      request.files.add(multipartFile);

      print("📤 [Cloudinary] Sending request to: $uri");
      print("📤 [Cloudinary] Using upload preset: $uploadPreset");

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("📥 [Cloudinary] Response status: ${response.statusCode}");
      print("📥 [Cloudinary] Response body: $responseBody");

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final imageUrl = data['secure_url'];
        print("✅ [Cloudinary] Upload successful!");
        print("✅ [Cloudinary] URL: $imageUrl");
        return imageUrl;
      } else {
        print("❌ [Cloudinary] Upload failed with status: ${response.statusCode}");
        print("❌ [Cloudinary] Response: $responseBody");
        return null;
      }
    } catch (e) {
      print("❌ [Cloudinary] Exception: $e");
      return null;
    }
  }
}