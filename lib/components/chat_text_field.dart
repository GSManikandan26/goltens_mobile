import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatTextField extends StatefulWidget {
  final Function(
    String,
    String,
    int,
    List<Map<String, dynamic>>,
  ) onMessageSend;

  const ChatTextField({
    super.key,
    required this.onMessageSend,
  });

  @override
  State<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends State<ChatTextField> {
  TextEditingController titleTextController = TextEditingController();
  TextEditingController contentTextController = TextEditingController();
  bool isSending = false;
  int timer = 60;
  List<Map<String, dynamic>> filesArr = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 6.0,
          vertical: 10.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            color: Colors.grey.shade200,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 80.0),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: TextField(
                      controller: contentTextController,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.0),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: IconButton(
                    onPressed: showFileAttachmentOptions,
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: SizedBox(
                    width: 100.0,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: showTimerOptions,
                          icon: const Icon(Icons.alarm, color: Colors.grey),
                        ),
                        IconButton(
                          onPressed: showConfirmationDialog,
                          icon: const Icon(Icons.send, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Center(child: Text("Confirm Your Message")),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
          ),
          content: StatefulBuilder(
            builder: (
              BuildContext context,
              StateSetter setState,
            ) {
              var formKey = GlobalKey<FormState>();

              var timerTextController = TextEditingController(
                text: timer.toString(),
              );

              return SizedBox(
                height: 275,
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
                              onChanged: (String newTime) {
                                timer = int.parse(newTime);
                              },
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
                        children: filesArr.map((fileObj) {
                          var icon = Icons.insert_drive_file;

                          switch (fileObj['type']) {
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
                              '${fileObj['file'].path.split('/').last}',
                              overflow: TextOverflow.clip,
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                filesArr.removeWhere(
                                  (elem) => elem['file'] == fileObj['file'],
                                );

                                setState(() => filesArr = filesArr);
                              },
                              icon: const Icon(Icons.close),
                            ),
                            onTap: () {},
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 15.0),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.send),
                        label: const Text('Send Message'),
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
                            sendMessage();
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

  void sendMessage() {
    widget.onMessageSend(
      titleTextController.text,
      contentTextController.text,
      timer,
      filesArr,
    );

    contentTextController.clear();

    setState(() {
      timer = 60;
      filesArr = [];
    });
  }

  void showFileAttachmentOptions() {
    Future<void> pickFiles(FileType fileType) async {
      try {
        if (fileType == FileType.image) {
          final pickedFile = await ImagePicker().pickImage(
            source: ImageSource.gallery,
          );

          if (pickedFile != null) {
            filesArr.add({'file': pickedFile, 'type': fileType});

            if (mounted) {
              Navigator.pop(context);

              const snackBar = SnackBar(
                content: Text('Photo Added'),
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            }
          }

          return;
        }

        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: fileType,
          allowMultiple: true,
        );

        if (result != null) {
          List<File> files = result.paths.map((path) {
            if (path != null) {
              return File(path);
            } else {
              throw Exception('Cannot load files');
            }
          }).toList();

          for (var file in files) {
            filesArr.add({'file': file, 'type': fileType});
          }

          if (mounted) {
            Navigator.pop(context);

            final snackBar = SnackBar(
              content: Text('${files.length} Files Added'),
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
        }

        if (mounted) {
          final snackBar = SnackBar(content: Text(e.toString()));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }
    }

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (builder) => SizedBox(
        height: 270,
        width: MediaQuery.of(context).size.width,
        child: Card(
          margin: const EdgeInsets.all(18.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 20,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    bottomSheetIcon(
                      Icons.insert_drive_file,
                      Colors.indigo,
                      "Document",
                      () async => await pickFiles(FileType.any),
                    ),
                    const SizedBox(width: 40),
                    bottomSheetIcon(
                      Icons.photo,
                      Colors.pink,
                      "Photos",
                      () async => await pickFiles(FileType.image),
                    ),
                  ],
                ),
                Visibility(
                  visible: !Platform.isIOS,
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          bottomSheetIcon(
                            Icons.headset,
                            Colors.orange,
                            "Audio",
                            () async => await pickFiles(FileType.audio),
                          ),
                          const SizedBox(width: 40),
                          bottomSheetIcon(
                            Icons.video_camera_back_rounded,
                            Colors.teal,
                            "Video",
                            () async => await pickFiles(FileType.video),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget bottomSheetIcon(
    IconData icons,
    Color color,
    String text,
    void Function() onPress,
  ) {
    return InkWell(
      onTap: onPress,
      borderRadius: const BorderRadius.all(Radius.circular(100.0)),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(
              icons,
              size: 29,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 12),
          )
        ],
      ),
    );
  }

  void showTimerOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              final formKey = GlobalKey<FormState>();

              final timerTextController = TextEditingController(
                text: timer.toString(),
              );

              return Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: 0,
                ),
                child: SizedBox(
                  height: 200.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Message Timer',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      Form(
                        key: formKey,
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'Time in (Seconds)',
                            helperText: 'Time for user to read this message',
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
                      ),
                      const SizedBox(height: 15.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              if (formKey.currentState?.validate() == true) {
                                setState(() {
                                  Navigator.pop(context);
                                  timer = int.parse(timerTextController.text);
                                });
                              }
                            },
                            child: const Text('OK'),
                          )
                        ],
                      )
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
}
