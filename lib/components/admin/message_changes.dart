import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goltens_core/models/admin.dart';
import 'package:goltens_core/services/admin.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_core/utils/pdf_generator.dart';
import 'package:goltens_mobile/utils/functions.dart';

class MessageChanges extends StatefulWidget {
  const MessageChanges({super.key});

  @override
  State<MessageChanges> createState() => _MessageChangesState();
}

class _MessageChangesState extends State<MessageChanges> {
  ScrollController scrollController = ScrollController();
  List<MessageChangeData> data = [];
  bool isLoading = false;
  bool hasMoreData = true;
  bool hasError = true;
  int page = 1;
  final int limit = 20;
  ReceivePort port = ReceivePort();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        fetchReadStatus();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.removeListener(scrollListener);
  }

  void scrollListener() {
    bool outOfRange = scrollController.position.outOfRange;
    double offset = scrollController.offset;

    if (offset >= scrollController.position.maxScrollExtent && !outOfRange) {
      fetchReadStatus();
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
      final message = settings.arguments as GetMessageResponseData;
      var response = await AdminService.getMessageChanges(message.id);

      setState(() {
        data = response.data;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> exportPdfFile() async {
    final settings = ModalRoute.of(context)!.settings;
    final message = settings.arguments as GetMessageResponseData;
    var messageId = formatDateTime(
      message.createdAt,
      'yyMM\'SN${message.id}\'',
    );
    final ByteData image = await rootBundle.load('assets/images/logo.png');
    Uint8List logoImage = (image).buffer.asUint8List();
    final directory = await getDownloadsDirectoryPath();

    // Save the PDF file
    Uint8List pdfInBytes = await PDFGenerator.generateMessageChanges(
      message.id,
      message.content,
      logoImage,
      message.createdAt,
      data,
    );

    File file = File('$directory/message-history-$messageId.pdf');
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

  Widget buildStatusList() {
    if (isLoading) {
      return buildLoader();
    }

    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'No Message History',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      );
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
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: scrollController,
        separatorBuilder: (BuildContext context, int index) {
          return const Divider();
        },
        itemCount: data.length,
        itemBuilder: (BuildContext context, int index) {
          var readInfo = data[index].reads.map((e) {
            var time = formatDateTime(e.readAt, 'HH:mm dd/mm/y');

            return '${e.reply} (${e.mode}) - $time';
          }).join('\n');

          return ListTile(
            title: Text('${data[index].name} (${data[index].email})'),
            subtitle: Text(readInfo),
          );
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

  @override
  Widget build(BuildContext context) {
    final settings = ModalRoute.of(context)!.settings;
    final message = settings.arguments as GetMessageResponseData;

    var messageId = formatDateTime(
      message.createdAt,
      'yyMM\'SN${message.id}\'',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${message.title} - $messageId',
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'export-pdf':
                  exportPdfFile();
                  break;
                default:
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'export-pdf',
                child: Text('Export PDF'),
              ),
            ],
          ),
        ],
      ),
      body: buildStatusList(),
    );
  }
}
