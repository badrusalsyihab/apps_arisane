import 'dart:io';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';

// Semua "upload gambar apapun" (bukti transfer, foto grup, nota kas)
// disimpan di Google Drive milik akun yang login, lalu link-nya
// (bukan file-nya) yang disimpan di Firestore (kolom proofUrl/photoUrl).
class GoogleDriveService {
  static const _folderName = 'ArisanApp Uploads';

  Future<drive.DriveApi> _getDriveApi() async {
    final client = await AuthService.googleSignIn.authenticatedClient();
    if (client == null) {
      throw Exception('Belum login Google, tidak bisa akses Drive');
    }
    return drive.DriveApi(client);
  }

  Future<String> _ensureFolder(drive.DriveApi api) async {
    final existing = await api.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and name='$_folderName' and trashed=false",
      spaces: 'drive',
    );
    if (existing.files != null && existing.files!.isNotEmpty) {
      return existing.files!.first.id!;
    }
    final folder = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder);
    return created.id!;
  }

  /// Upload file gambar (bukti transfer, foto grup, nota kas, dll).
  /// Mengembalikan direct link gambar yang bisa dipakai di NetworkImage.
  Future<String> uploadImage(XFile imageFile, {required String fileNamePrefix}) async {
    final api = await _getDriveApi();
    final folderId = await _ensureFolder(api);

    final fileBytes = await File(imageFile.path).readAsBytes();
    final driveFile = drive.File()
      ..name = '${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.jpg'
      ..parents = [folderId];

    final media = drive.Media(Stream.value(fileBytes), fileBytes.length);
    final uploaded = await api.files.create(driveFile, uploadMedia: media);

    // Set permission publik "anyone with link can view" supaya bisa
    // ditampilkan di app tanpa perlu re-auth tiap anggota yang lihat.
    await api.permissions.create(
      drive.Permission(type: 'anyone', role: 'reader'),
      uploaded.id!,
    );

    return 'https://drive.google.com/uc?export=view&id=${uploaded.id}';
  }
}
