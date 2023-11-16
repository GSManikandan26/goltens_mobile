import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/models/group.dart';
import 'package:goltens_core/utils/csv_generator.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_core/utils/pdf_generator.dart';
import 'package:goltens_mobile/utils/functions.dart';
import 'package:flutter/material.dart';
import 'package:goltens_core/models/message.dart';
import 'package:goltens_core/services/message.dart';
import 'package:permission_handler/permission_handler.dart';

class ReadStatusPageArgs {
  final GetMessagesResponseData message;
  final GetAllGroupsResponseData group;

  ReadStatusPageArgs({
    required this.message,
    required this.group,
  });
}

class ReadStatusPage extends StatefulWidget {
  const ReadStatusPage({super.key});

  @override
  State<ReadStatusPage> createState() => _ReadStatusPageState();
}

class _ReadStatusPageState extends State<ReadStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  ScrollController scrollController = ScrollController();
  List<ReadStatusUser> readUsers = [];
  List<ReadStatusUser> unReadUsers = [];
  bool isLoading = false;
  bool hasMoreData = true;
  bool hasError = true;
  int page = 1;
  String filter = 'unread';
  final int limit = 20;
  ReceivePort port = ReceivePort();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(tabListener);
    scrollController.addListener(scrollListener);

    IsolateNameServer.registerPortWithName(
      port.sendPort,
      'downloader_send_port',
    );

    port.listen((dynamic data) {});
    FlutterDownloader.registerCallback(downloadCallback);
    requestNotificationPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        fetchReadStatus();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    tabController.dispose();
    scrollController.removeListener(scrollListener);
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final send = IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
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

  void scrollListener() {
    bool outOfRange = scrollController.position.outOfRange;
    double offset = scrollController.offset;

    if (offset >= scrollController.position.maxScrollExtent && !outOfRange) {
      fetchReadStatus();
    }
  }

  void tabListener() {
    switch (tabController.index) {
      case 0:
        setState(() {
          filter = 'unread';
        });
        break;
      case 1:
        setState(() {
          filter = 'read';
        });
        break;
      default:
    }
  }

  Future<void> fetchReadStatus() async {
    if (isLoading || !hasMoreData) {
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final settings = ModalRoute.of(context)!.settings;
      final args = settings.arguments as ReadStatusPageArgs;
      final message = args.message;
      final group = args.group;

      var response = await MessageService.getMessageReadStatus(
        message.id,
        group.id,
      );

      setState(() {
        readUsers = response.readUsers;
        unReadUsers = response.unreadUsers;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Widget buildStatusList(String itemToRender) {
    List<ReadStatusUser> users;

    if (itemToRender == 'unread') {
      users = unReadUsers;
    } else {
      users = readUsers;
    }

    if (isLoading && users.isEmpty) {
      return buildLoader();
    }

    if (hasError) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Error Fetching Data, Please Try Again',
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              onPressed: fetchReadStatus,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.replay_outlined),
                  SizedBox(width: 5),
                  Text('Retry'),
                ],
              ),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchReadStatus,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: scrollController,
        itemCount: users.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index != users.length) {
            ReadStatusUser user = users[index];
            var time = '';

            if (filter == 'read' && user.readAt != null) {
              time = formatDateTime(user.readAt!, 'HH:mm dd/MM/y');
            }

            return ListTile(
              title: Text(user.name),
              leading: CircleAvatar(
                child: user.avatar.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(100.0),
                        child: Image.network(
                          '$apiUrl/$avatar/${user.avatar}',
                          fit: BoxFit.contain,
                          height: 500,
                          width: 500,
                          errorBuilder: (
                            context,
                            obj,
                            stacktrace,
                          ) {
                            return Container();
                          },
                        ),
                      )
                    : Text(user.name[0]),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Text(time)],
              ),
            );
          }

          return null;
        },
      ),
    );
  }

  Widget buildLoader() {
    if (!hasMoreData) {
      return Container();
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Future<void> exportPdfFile() async {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as ReadStatusPageArgs;
    final message = args.message;
    final ByteData image = await rootBundle.load('assets/images/logo.png');
    Uint8List logoImage = (image).buffer.asUint8List();

    final directory = await getDownloadsDirectoryPath();
    Uint8List pdfInBytes = await PDFGenerator.generateReadStatus(
      message.id,
      message.content,
      message.createdAt,
      logoImage,
      readUsers,
      unReadUsers,
    );
    File file = File('$directory/read-status-${message.id}.pdf');
    file.writeAsBytes(pdfInBytes);

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

  Future<void> exportCsvFile() async {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as ReadStatusPageArgs;
    final message = args.message;
    String csvData = CSVGenerator.generateReadStatus(readUsers, unReadUsers);
    final directory = await getDownloadsDirectoryPath();
    File file = File('$directory/read-status-${message.id}.csv');
    file.writeAsString(csvData);

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

  @override
  Widget build(BuildContext context) {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as ReadStatusPageArgs;
    final message = args.message;

    var messageId = formatDateTime(
      message.createdAt,
      'yyMM\'SN${message.id}\'',
    );

    return WillPopScope(
      onWillPop: () async {
        if (tabController.index == 1) {
          // Read Page
          tabController.animateTo(0);
          return false;
        }

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${message.content} - $messageId',
          ),
          actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'export-csv':
                    exportCsvFile();
                    break;
                  case 'export-pdf':
                    exportPdfFile();
                    break;
                  default:
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem(
                    value: 'export-pdf',
                    child: Text('Export .PDF file'),
                  ),
                  const PopupMenuItem(
                    value: 'export-csv',
                    child: Text('Export .CSV file'),
                  ),
                ];
              },
            )
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            controller: tabController,
            tabs: const [
              Tab(text: 'Unread'),
              Tab(text: 'Read'),
            ],
          ),
        ),
        body: TabBarView(
          controller: tabController,
          children: [
            buildStatusList('unread'),
            buildStatusList('read'),
          ],
        ),
      ),
    );
  }
}
