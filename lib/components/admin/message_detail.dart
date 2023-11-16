import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:goltens_core/components/message_card.dart';
import 'package:goltens_core/models/admin.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_mobile/components/admin/message_changes.dart';
import 'package:goltens_mobile/components/admin/read_status.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_mobile/pages/others/file_viewer_page.dart';
import 'package:goltens_core/services/admin.dart';
import 'package:goltens_mobile/utils/functions.dart';

class MessageDetailArgs {
  final GetMessagesResponseData message;
  final GetGroupsResponseData? group;

  MessageDetailArgs({
    required this.message,
    required this.group,
  });
}

class MessageDetail extends StatefulWidget {
  const MessageDetail({super.key});

  @override
  State<MessageDetail> createState() => _MessageDetailAdminPageState();
}

class _MessageDetailAdminPageState extends State<MessageDetail> {
  GetMessageResponseData? messageDetail;
  bool isLoading = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        fetchMessage();
      }
    });
  }

  Future<void> fetchMessage() async {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as MessageDetailArgs;
    final message = args.message;

    if (isLoading) {
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      var res = await AdminService.getMessage(messageId: message.id);

      setState(() {
        isLoading = false;
        messageDetail = res.data;
      });
    } catch (e) {
      if (mounted) {
        if (mounted) {
          final snackBar = SnackBar(content: Text(e.toString()));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }

        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    }
  }

  Future<void> deleteMessage(GetMessageResponseData message) async {
    try {
      await AdminService.deleteMessage(
        messageId: message.id,
      );

      if (mounted) {
        const snackBar = SnackBar(content: Text('Message Deleted'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void showDeleteDialog(
    GetMessageResponseData message,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure you want delete this message ?"),
          actions: [
            TextButton(
              child: const Text("CANCEL"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () async {
                await deleteMessage(message);

                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateMessage(
    int messageId,
    String title,
    String content,
    String timer,
  ) async {
    try {
      await AdminService.updateMessage(
        messageId,
        title,
        content,
        int.parse(timer),
        messageDetail?.files ?? [],
      );

      await fetchMessage();

      if (mounted) {
        const snackBar = SnackBar(content: Text('Message Updated'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void showEditDialog(
    GetMessageResponseData message,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Center(child: Text("Update Message")),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
          ),
          content: StatefulBuilder(
            builder: (
              BuildContext context,
              StateSetter setState,
            ) {
              var formKey = GlobalKey<FormState>();

              var titleTextController = TextEditingController(
                text: messageDetail?.title,
              );

              var contentTextController = TextEditingController(
                text: messageDetail?.content,
              );

              var timerTextController = TextEditingController(
                text: messageDetail?.timer.toString(),
              );

              return SizedBox(
                height: 340,
                width: 410,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 16.0),
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: titleTextController,
                              maxLines: null,
                              decoration: InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                              validator: (value) {
                                if (value != null && value.isEmpty) {
                                  return 'Please enter title';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: contentTextController,
                              maxLines: null,
                              decoration: InputDecoration(
                                labelText: 'Content',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                              validator: (value) {
                                if (value != null && value.isEmpty) {
                                  return 'Please enter content';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Time in (Seconds)',
                                helperText:
                                    'Time for user to read this message',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                              controller: timerTextController,
                              validator: (value) {
                                if (value != null && value.isEmpty) {
                                  return 'Please enter valid second';
                                }

                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      Column(
                        children: messageDetail?.files.map((fileObj) {
                              var icon = Icons.insert_drive_file;

                              switch (nameToFileType(fileObj.fileType)) {
                                case FileType.image:
                                  icon = Icons.photo;
                                  break;
                                case FileType.video:
                                  icon = Icons.video_camera_back_rounded;
                                  break;
                                case FileType.audio:
                                  icon = Icons.headset;
                                  break;
                                default:
                              }

                              return ListTile(
                                leading: Icon(icon),
                                title: Text(
                                  fileObj.name.split('/').last,
                                  overflow: TextOverflow.clip,
                                ),
                                trailing: IconButton(
                                  onPressed: () {
                                    messageDetail?.files.removeWhere(
                                      (elem) => elem.name == fileObj.name,
                                    );

                                    setState(
                                      () => messageDetail = messageDetail,
                                    );
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                                onTap: () {},
                              );
                            }).toList() ??
                            [],
                      ),
                      const SizedBox(height: 15.0),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.send),
                        label: const Text('Update Message'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        onPressed: () async {
                          if (formKey.currentState?.validate() == true) {
                            formKey.currentState?.save();
                            Navigator.pop(context);
                            updateMessage(
                              message.id,
                              titleTextController.text,
                              contentTextController.text,
                              timerTextController.text,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<File?> fetchFile(String url) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return const Dialog(
          // The background color
          backgroundColor: Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 15),
                Text('Loading...')
              ],
            ),
          ),
        );
      },
    );

    File file;

    try {
      file = await loadFileFromNetwork(url);
      if (mounted) Navigator.of(context).pop();
      return file;
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }

    if (mounted) Navigator.of(context).pop();
    return null;
  }

  Widget buildLoader() {
    if (!isLoading) {
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
    final message = messageDetail;

    if (message == null) {
      return Scaffold(
        body: buildLoader(),
      );
    }

    var messageId = formatDateTime(
      message.createdAt,
      'yyMM\'SN${message.id}\'',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${message.title} - $messageId'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'info':
                  final settings = ModalRoute.of(context)!.settings;
                  final args = settings.arguments as MessageDetailArgs;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReadStatus(),
                      settings: RouteSettings(
                        arguments: ReadStatusArgs(
                          message: args.message,
                          group: args.group,
                        ),
                      ),
                    ),
                  );
                  break;
                case 'changes':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MessageChanges(),
                      settings: RouteSettings(arguments: message),
                    ),
                  );
                  break;
                case 'edit':
                  showEditDialog(message);
                  break;
                case 'delete':
                  showDeleteDialog(message);
                  break;
                default:
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'info',
                child: Text('Info'),
              ),
              const PopupMenuItem<String>(
                value: 'changes',
                child: Text('Tracking History'),
              ),
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      body: buildBody(message),
    );
  }

  Widget buildBody(GetMessageResponseData message) {
    if (isLoading || messageDetail == null) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: CircularProgressIndicator(),
          )
        ],
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
              onPressed: fetchMessage,
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

    var messageId = formatDateTime(
      message.createdAt,
      'yyMM\'SN${message.id}\'',
    );

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        var time = formatDateTime(
          messageDetail?.createdAt ?? DateTime(0),
          'HH:mm dd/MM/y',
        );

        String? imageUrl;

        if (message.files.isNotEmpty) {
          var image = messageDetail?.files.firstWhere(
            (element) => element.fileType == 'image',
            orElse: () => Files(name: '', fileType: ''),
          );

          var pdf = messageDetail?.files.firstWhere(
            (element) => element.name.endsWith('.pdf'),
            orElse: () => Files(name: '', fileType: ''),
          );

          if (pdf?.name.isNotEmpty == true) {
            imageUrl = pdf?.name.replaceAll('.pdf', '.jpg');
          }

          if (image?.name.isNotEmpty == true) {
            imageUrl = image?.name;
          }
        }

        return [
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      MessageCard(
                        messageId: messageId,
                        title: message.title,
                        content: message.content,
                        showFullContent: true,
                        createdByAvatar: message.createdBy.avatar,
                        createdByName: message.createdBy.name,
                        imageUrl: imageUrl,
                        isUnread: null,
                        files: message.files,
                        time: time,
                        onTap: () async {},
                      ),
                      const SizedBox(height: 5.0),
                      messageDetail?.files.isNotEmpty == true
                          ? const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 15.0,
                                vertical: 8.0,
                              ),
                              child: Text(
                                'Files',
                                style: TextStyle(
                                  fontSize: 16.0,
                                ),
                              ),
                            )
                          : Container(),
                      Column(
                        children: messageDetail?.files.map((fileObj) {
                              var icon = Icons.insert_drive_file;

                              switch (nameToFileType(fileObj.fileType)) {
                                case FileType.image:
                                  icon = Icons.photo;
                                  break;
                                case FileType.video:
                                  icon = Icons.video_camera_back_rounded;
                                  break;
                                case FileType.audio:
                                  icon = Icons.headset;
                                  break;
                                default:
                              }

                              return ListTile(
                                leading: Icon(icon),
                                title: Text(
                                  fileObj.name.split('/').last,
                                  overflow: TextOverflow.clip,
                                ),
                                onTap: () async {
                                  var url = '$apiUrl'
                                      '/$groupData'
                                      '/${fileObj.name}';

                                  var file = await fetchFile(url);

                                  if (file != null) {
                                    if (mounted) {
                                      Navigator.pushNamed(
                                        context,
                                        '/file-viewer',
                                        arguments: FileViewerPageArgs(
                                          file: file,
                                          url: url,
                                          fileType: nameToFileType(
                                            fileObj.fileType,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              );
                            }).toList() ??
                            [],
                      ),
                      const SizedBox(height: 10.0),
                      const Divider(height: 5)
                    ],
                  ),
                ),
              ],
            ),
          )
        ];
      },
      body: RefreshIndicator(
        onRefresh: fetchMessage,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80.0),
          itemCount: messageDetail!.read.length,
          itemBuilder: (BuildContext context, int index) {
            var readObject = messageDetail!.read[index];
            var time = formatDateTime(readObject.readAt, 'HH:mm dd/MM/y');

            if (readObject.reply?.isNotEmpty == true) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              '${readObject.reply} (${readObject.mode})',
                              style: const TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 12,
                                child: readObject.user.avatar.isNotEmpty == true
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                        child: Image.network(
                                          '$apiUrl/$avatar/${readObject.user.avatar}',
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
                                    : Text(
                                        readObject.user.name[0],
                                      ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                readObject.user.name,
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }
}
