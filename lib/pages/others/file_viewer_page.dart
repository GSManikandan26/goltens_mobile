// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_mobile/utils/functions.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path/path.dart';
import 'package:video_player/video_player.dart';

class FileViewerPageArgs {
  final File file;
  final String url;
  final FileType fileType;

  const FileViewerPageArgs({
    Key? key,
    required this.file,
    required this.url,
    required this.fileType,
  });
}

class FileViewerPage extends StatefulWidget {
  const FileViewerPage({super.key});

  @override
  State<FileViewerPage> createState() => _FileViewerPageState();
}

class _FileViewerPageState extends State<FileViewerPage> {
  VideoPlayerController? videoController;
  AudioPlayer? audioPlayer;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isPlaying = false;
  ReceivePort port = ReceivePort();

  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(
      port.sendPort,
      'downloader_send_port',
    );

    port.listen((dynamic data) {});
    FlutterDownloader.registerCallback(downloadCallback);
    requestNotificationPermissions();
  }

  @override
  void dispose() {
    super.dispose();
    audioPlayer?.dispose();
    audioPlayer = null;
    videoController?.dispose();
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  Future<void> requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      final PermissionStatus status = await Permission.notification.request();

      if (status.isGranted) {
        // Notification permissions granted
      } else if (status.isDenied) {
        // Permission Denied
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as FileViewerPageArgs;
    final file = args.file;
    final url = args.url;
    final name = basename(file.path);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            onPressed: () async {
              var saved = await saveFile(context, url);

              if (saved) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'successfully saved to internal storage "Download" folder',
                      ),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as FileViewerPageArgs;
    final file = args.file;
    final fileType = args.fileType;
    final url = args.url;
    final name = basename(file.path);

    if (fileType == FileType.any) {
      if (name.endsWith('.pdf')) {
        return PDFView(
          filePath: file.path,
        );
      }
    }

    if (fileType == FileType.image) {
      return PhotoView(
        imageProvider: NetworkImage(url),
      );
    }

    if (fileType == FileType.video) {
      if (videoController == null) {
        videoController = VideoPlayerController.network(
          url,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );

        videoController?.addListener(() => setState(() {}));
        videoController?.setLooping(false);
        videoController?.initialize();
      }

      if (videoController != null) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(padding: const EdgeInsets.only(top: 20.0)),
            Container(
              padding: const EdgeInsets.all(20),
              child: AspectRatio(
                aspectRatio: videoController!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    VideoPlayer(videoController!),
                    _ControlsOverlay(controller: videoController!),
                    VideoProgressIndicator(
                      videoController!,
                      allowScrubbing: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }

      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Sorry, Cannot Play Video',
            ),
          )
        ],
      );
    }

    if (fileType == FileType.audio) {
      if (audioPlayer == null) {
        audioPlayer = AudioPlayer();
        audioPlayer?.setSourceUrl(url);

        audioPlayer?.onPlayerStateChanged.listen((state) {
          if (state == PlayerState.playing) {
            setState(() => isPlaying = true);
          }

          if (state == PlayerState.paused) {
            setState(() => isPlaying = false);
          }
        });

        audioPlayer?.onDurationChanged.listen((newDuration) {
          setState(() => duration = newDuration);
        });

        audioPlayer?.onPositionChanged.listen((newPosition) {
          setState(() => position = newPosition);
        });

        setState(() {});
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Slider(
            min: 0,
            max: duration.inSeconds.toDouble(),
            value: position.inSeconds.toDouble(),
            onChanged: (value) async {
              position = Duration(seconds: value.toInt());
              await audioPlayer?.seek(position);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedTime(
                    timeInSecond: position.inSeconds,
                  ),
                ),
                Text(
                  formattedTime(
                    timeInSecond: (duration - position).inSeconds,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              label: Text(isPlaying ? 'Pause' : 'Play'),
              onPressed: () async {
                if (isPlaying) {
                  await audioPlayer?.pause();
                } else {
                  await audioPlayer?.play(UrlSource(url));
                }
              },
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Sorry, File cannot be opened here, use other apps to open it',
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => openFile(context, file.path),
            icon: const Icon(Icons.file_open),
            label: const Text('Open File'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openFile(BuildContext context, String path) async {
    final result = await OpenFilex.open(path);

    switch (result.type) {
      case ResultType.noAppToOpen:
        if (mounted) {
          if (mounted) {
            const snackBar = SnackBar(
              content: Text('No apps installed to open this file'),
            );

            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
        break;
      case ResultType.permissionDenied:
        if (mounted) {
          if (mounted) {
            const snackBar = SnackBar(
              content: Text('Permission Denied to open this app'),
            );

            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
        break;
      case ResultType.error:
        if (mounted) {
          const snackBar = SnackBar(
            content: Text('Error cannot open file'),
          );

          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
        break;
      case ResultType.done:
        break;
      default:
        break;
    }
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final send = IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  Future<bool> saveFile(
    BuildContext context,
    String url,
  ) async {
    try {
      var downloadsDirectory = await getDownloadsDirectoryPath();

      await FlutterDownloader.enqueue(
        url: url,
        savedDir: downloadsDirectory,
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: true,
        allowCellular: true,
      );

      return true;
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      return false;
    }
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        )
      ],
    );
  }
}
