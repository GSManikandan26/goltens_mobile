// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goltens_core/models/auth.dart';
import 'package:goltens_core/services/auth.dart';
import 'package:goltens_mobile/provider/global_state.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

// Not Working on Xcode 15 change to another library
Future<bool> hasInternetConnection() async {
  return await InternetConnectionChecker().hasConnection;
}

Future<String> getDownloadsDirectoryPath() async {
  bool dirDownloadExists = true;

  String directory;

  if (Platform.isIOS) {
    var downloads = await getApplicationDocumentsDirectory();
    directory = downloads.path;
  } else {
    directory = "/storage/emulated/0/Download";
    dirDownloadExists = await Directory(directory).exists();

    if (dirDownloadExists) {
      directory = "/storage/emulated/0/Download";
    } else {
      directory = "/storage/emulated/0/Downloads";
    }
  }

  return directory;
}

Future<File> loadFileFromNetwork(String url) async {
  var dio = Dio();

  final response = await dio.get(
    url,
    options: Options(responseType: ResponseType.bytes),
  );

  final bytes = response.data;
  return _storeFile(url, bytes);
}

Future<File> _storeFile(String url, List<int> bytes) async {
  final filename = basename(url);
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

FileType nameToFileType(String name) {
  switch (name) {
    case 'image':
      return FileType.image;
    case 'video':
      return FileType.video;
    case 'audio':
      return FileType.audio;
    default:
      return FileType.any;
  }
}

Future<void> authNavigate(BuildContext context) async {
  try {
    final userResponse = await AuthService.getMe();

    if (context.mounted) {
      context.read<GlobalState>().setUserResponse(userResponse);

      // If User => Admin Then Goto Admin Dashboard
      if (userResponse.data.type == UserType.admin) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin-choose-app',
          (r) => false,
        );

        return;
      }

      switch (userResponse.data.adminApproved) {
        case AdminApproved.approved:
          if (userResponse.data.type == UserType.userAndSubAdmin) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/choose-user-type',
              (r) => false,
            );
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/choose-app',
              (r) => false,
            );
          }

          break;
        case AdminApproved.pending:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin-approval',
            (r) => false,
          );

          break;
        case AdminApproved.rejected:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin-rejected',
            (r) => false,
          );
          break;
      }
    }
  } on DioError catch (e) {
    // Force Exit if Server not Available
    if (e.type == DioErrorType.receiveTimeout ||
        e.type == DioErrorType.connectTimeout) {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else if (Platform.isIOS) {
        exit(0);
      }
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/auth',
        (r) => false,
      );
    }
  }
}
