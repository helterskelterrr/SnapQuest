import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StorageService {
  // ── Cloudinary config ──────────────────────────────────────────
  // 1. Buat akun gratis di https://cloudinary.com
  // 2. Ganti nilai di bawah dengan cloud name kamu
  // 3. Buat unsigned upload preset di:
  //    Settings → Upload → Upload presets → Add upload preset
  //    Set signing mode = "Unsigned", simpan nama preset-nya
  static const _cloudName = 'da32regjy';
  static const _uploadPreset = 'snapquest';

  static const _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload user avatar. Returns download URL.
  Future<String> uploadAvatar(String userId, File imageFile) async {
    final compressed = await _compressImage(imageFile);
    try {
      return await _uploadToCloudinary(
        file: compressed,
        folder: 'avatars',
        publicId: userId,
      );
    } finally {
      if (compressed.path != imageFile.path) {
        try { await compressed.delete(); } catch (_) {}
      }
    }
  }

  /// Upload submission photo. Returns download URL.
  Future<String> uploadSubmission(
    String challengeId,
    String userId,
    File imageFile,
  ) async {
    final compressed = await _compressImage(imageFile);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return await _uploadToCloudinary(
        file: compressed,
        folder: 'submissions/$challengeId',
        publicId: '${userId}_$timestamp',
      );
    } finally {
      if (compressed.path != imageFile.path) {
        try { await compressed.delete(); } catch (_) {}
      }
    }
  }

  Future<String> _uploadToCloudinary({
    required File file,
    required String folder,
    required String publicId,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
    request.fields['upload_preset'] = _uploadPreset;
    request.fields['folder'] = folder;
    request.fields['public_id'] = publicId;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      final decoded = jsonDecode(body);
      throw Exception(decoded['error']?['message'] ?? 'Upload gagal');
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    return decoded['secure_url'] as String;
  }

  Future<File> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastDot = filePath.lastIndexOf('.');
      final targetPath =
          '${filePath.substring(0, lastDot)}_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        minWidth: 800,
        minHeight: 1,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      if (result == null) return file;
      return File(result.path);
    } catch (_) {
      return file;
    }
  }
}