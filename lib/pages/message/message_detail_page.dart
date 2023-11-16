import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:goltens_core/components/message_card.dart';
import 'package:goltens_core/models/group.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_core/components/countdown_timer.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/models/message.dart';
import 'package:goltens_mobile/pages/message/read_status_page.dart';
import 'package:goltens_mobile/pages/others/file_viewer_page.dart';
import 'package:goltens_core/services/message.dart';
import 'package:goltens_mobile/utils/functions.dart';
import 'package:provider/provider.dart';
import 'package:goltens_core/models/auth.dart';
import 'package:goltens_mobile/provider/global_state.dart';

class MessageDetailPageArgs {
  final GetMessagesResponseData message;
  final GetAllGroupsResponseData group;

  const MessageDetailPageArgs({
    required this.message,
    required this.group,
  });
}

class MessageDetailPage extends StatefulWidget {
  const MessageDetailPage({super.key});

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  @override
  Widget build(BuildContext context) {
    final user = context.read<GlobalState>().user;

    switch (user?.data.type) {
      case UserType.admin:
      case UserType.subAdmin:
      case UserType.userAndSubAdmin:
        return const MessageDetailAdminPage();
      case UserType.user:
        return const MessageDetailUserPage();
      case null:
        throw Exception('User Not Logged In');
    }
  }
}

class MessageDetailUserPage extends StatefulWidget {
  const MessageDetailUserPage({super.key});

  @override
  State<MessageDetailUserPage> createState() => _MessageDetailUserPageState();
}

class _MessageDetailUserPageState extends State<MessageDetailUserPage> {
  GetMessageResponseData? messageDetail;
  bool showOptions = false;
  bool isLoading = false;
  bool hasError = false;
  bool messageRead = false;

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
    final args = settings.arguments as MessageDetailPageArgs;
    final message = args.message;

    if (isLoading) {
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      var res = await MessageService.getMessage(message.id);

      setState(() {
        isLoading = false;
        messageDetail = res.data;
        messageRead = res.data.messageReadByUser != null;
        showOptions = messageRead && res.data.messageReadByUser?.reply == null;
      });
    } catch (e) {
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

  void onTimerFinished() async {
    showReplyOptionsDialog(null, null);
  }

  Future<void> readMessage(String mode, String reply) async {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as MessageDetailPageArgs;
    final message = args.message;
    final group = args.group;

    try {
      await MessageService.readMessage(message.id, group.id, reply, mode);

      setState(() {
        showOptions = false;
      });

      await fetchMessage();

      if (mounted) {
        const snackBar = SnackBar(content: Text('Message Read Successfully'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      setState(() {
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as MessageDetailPageArgs;
    final message = args.message;

    var messageId = formatDateTime(
      message.createdAt,
      'yyMM\'SN${message.id}\'',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${message.title} - $messageId'),
      ),
      body: buildBody(message),
    );
  }

  void showReplyOptionsDialog(int? modeIndex, int? replyIndex) {
    int? selectedModeIndex = modeIndex;
    int? selectedReplyIndex = replyIndex;

    showModalBottomSheet(
      isDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setState,
          ) {
            return SizedBox(
              height: 225,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Select Options',
                        style: TextStyle(
                          fontSize: 20.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Radio<int>(
                            value: 0,
                            groupValue: selectedModeIndex,
                            onChanged: (val) {
                              setState(() => selectedModeIndex = val);
                            },
                          ),
                          const Text('Physical'),
                          Radio<int>(
                            value: 1,
                            groupValue: selectedModeIndex,
                            onChanged: (val) {
                              setState(() => selectedModeIndex = val);
                            },
                          ),
                          const Text('Virtual'),
                        ],
                      ),
                      Row(
                        children: [
                          Radio<int>(
                            value: 0,
                            groupValue: selectedReplyIndex,
                            onChanged: (val) {
                              if (selectedModeIndex == null) return;
                              setState(() => selectedReplyIndex = val);
                            },
                          ),
                          const Text('I Understood'),
                          Radio<int>(
                            value: 1,
                            groupValue: selectedReplyIndex,
                            onChanged: (val) {
                              if (selectedModeIndex == null) return;
                              setState(() => selectedReplyIndex = val);
                            },
                          ),
                          const Text("Need Clarification"),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final mode = selectedModeIndex == 0
                              ? "Physical Mode"
                              : "Virtual Mode";

                          final reply = selectedReplyIndex == 0
                              ? "I read and understood"
                              : "Need Clarification";

                          await readMessage(mode, reply);

                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.done),
                            SizedBox(width: 5.0),
                            Text('Done')
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
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

  Widget buildBody(GetMessagesResponseData message) {
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

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        var time = formatDateTime(message.createdAt, 'HH:mm dd/MM/y');
        String? imageUrl;

        if (message.files.isNotEmpty) {
          var image = message.files.firstWhere(
            (element) => element.fileType == 'image',
            orElse: () => Files(name: '', fileType: ''),
          );

          var pdf = message.files.firstWhere(
            (element) => element.name.endsWith('.pdf'),
            orElse: () => Files(name: '', fileType: ''),
          );

          if (pdf.name.isNotEmpty) {
            imageUrl = pdf.name.replaceAll('.pdf', '.jpg');
          }

          if (image.name.isNotEmpty) {
            imageUrl = image.name;
          }
        }

        var messageId = formatDateTime(
          message.createdAt,
          'yyMM\'SN${message.id}\'',
        );

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
                      message.files.isNotEmpty
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
                      !messageRead
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                              ),
                              child: CountdownTimer(
                                seconds: message.timer,
                                onTimerFinished: onTimerFinished,
                              ),
                            )
                          : Container(),
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
          padding: const EdgeInsets.only(bottom: 100.0),
          itemCount: messageDetail!.read.length,
          itemBuilder: (BuildContext context, int index) {
            var state = context.read<GlobalState>();
            var readObject = messageDetail!.read[index];
            var time = formatDateTime(readObject.readAt, 'HH:mm dd/MM/y');
            var isUsersMessage = state.user?.data.id == readObject.user.id;

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
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const SizedBox(width: 8.0),
                              isUsersMessage
                                  ? PopupMenuButton<String>(
                                      splashRadius: 20.0,
                                      onSelected: (String value) {
                                        switch (value) {
                                          case 'change-option':
                                            final mode = readObject.mode ==
                                                    "Physical Mode"
                                                ? 0
                                                : 1;

                                            final reply = readObject.reply ==
                                                    "I understand that"
                                                ? 0
                                                : 1;

                                            showReplyOptionsDialog(
                                              mode,
                                              reply,
                                            );
                                            break;
                                          default:
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return [
                                          const PopupMenuItem(
                                            value: 'change-option',
                                            child: Text('Change Option'),
                                          ),
                                        ];
                                      },
                                    )
                                  : Container(),
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
                            ],
                          ),
                          const SizedBox(height: 4.0),
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
                                    : Text(readObject.user.name[0]),
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

class MessageDetailAdminPage extends StatefulWidget {
  const MessageDetailAdminPage({super.key});

  @override
  State<MessageDetailAdminPage> createState() => _MessageDetailAdminPageState();
}

class _MessageDetailAdminPageState extends State<MessageDetailAdminPage> {
  GetMessageResponseData? messageDetail;
  bool showOptions = false;
  bool isLoading = false;
  bool hasError = false;
  bool messageRead = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final settings = ModalRoute.of(context)!.settings;
        final args = settings.arguments as MessageDetailPageArgs;
        final message = args.message;
        final group = args.group;

        fetchMessage();

        try {
          await MessageService.readMessage(message.id, group.id, null, null);
        } catch (err) {
          // Do Nothing
        }
      }
    });
  }

  Future<void> fetchMessage() async {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as MessageDetailPageArgs;
    final message = args.message;

    if (isLoading) {
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      var res = await MessageService.getMessage(message.id);

      setState(() {
        isLoading = false;
        messageDetail = res.data;
        messageRead = res.data.messageReadByUser != null;
        showOptions = messageRead && res.data.messageReadByUser?.reply == null;
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

  Future<void> deleteMessage(
    GetMessagesResponseData message,
  ) async {
    try {
      await MessageService.deleteMessage(message.id);

      if (mounted) {
        if (mounted) {
          const snackBar = SnackBar(content: Text('Message Deleted'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void showDeleteDialog(
    GetMessagesResponseData message,
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
      await MessageService.updateMessage(
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
    GetMessagesResponseData message,
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

  @override
  Widget build(BuildContext context) {
    final user = context.read<GlobalState>().user;
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as MessageDetailPageArgs;
    final message = args.message;
    final group = args.group;
    var isOwner = message.createdBy.id == user?.data.id;

    var messageId = formatDateTime(
      message.createdAt,
      'yyMM\'SN${message.id}\'',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${messageDetail?.title} - $messageId'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'info':
                  Navigator.pushNamed(
                    context,
                    '/read-status',
                    arguments: ReadStatusPageArgs(
                      message: message,
                      group: group,
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
            itemBuilder: (BuildContext context) => !isOwner
                ? [
                    const PopupMenuItem<String>(
                      value: 'info',
                      child: Text('Info'),
                    ),
                  ]
                : [
                    const PopupMenuItem<String>(
                      value: 'info',
                      child: Text('Info'),
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

  Widget buildBody(GetMessagesResponseData message) {
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

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        var messageId = formatDateTime(
          messageDetail?.createdAt ?? DateTime(0),
          'yyMM\'SN${message.id}\'',
        );

        var time = formatDateTime(message.createdAt, 'HH:mm dd/MM/y');

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
                                    : Text(readObject.user.name[0]),
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
