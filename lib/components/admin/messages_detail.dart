import 'dart:io';
import 'package:goltens_core/components/message_card.dart';
import 'package:goltens_core/models/admin.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_mobile/components/admin/message_detail.dart';
import 'package:goltens_mobile/components/chat_text_field.dart';
import 'package:flutter/material.dart';
import 'package:goltens_core/services/admin.dart';
import 'package:goltens_mobile/components/search_bar_delegate.dart';
import 'package:goltens_mobile/utils/functions.dart';

class MessagesDetail extends StatefulWidget {
  const MessagesDetail({super.key});

  @override
  State<MessagesDetail> createState() => _MessagesDetailState();
}

class _MessagesDetailState extends State<MessagesDetail>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  ScrollController scrollController = ScrollController();
  String filter = 'unread';
  List<ReadStatusUser> readUsers = [];
  List<ReadStatusUser> unReadUsers = [];
  GetGroupsResponseData? group;
  bool isLoading = false;
  bool isError = false;
  int limit = 50;
  int currentPage = 1;
  int totalPages = 1;
  String? search;
  bool hasMoreData = true;
  List<GetMessagesResponseData> messages = [];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(tabListener);
    scrollController.addListener(scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = ModalRoute.of(context)!.settings;
      final groupDetail = settings.arguments as GetGroupsResponseData;
      setState(() => group = groupDetail);
      fetchMessages(group?.id ?? 0, false);
    });
  }

  void scrollListener() {
    bool outOfRange = scrollController.position.outOfRange;
    double offset = scrollController.offset;

    if (offset >= scrollController.position.maxScrollExtent && !outOfRange) {
      fetchMessages(group?.id ?? 0, false);
    }
  }

  Future<void> startSearch() async {
    var searchQuery = await showSearch(
      context: context,
      delegate: SearchBarDelegate(),
      query: search,
    );

    if (searchQuery != null) {
      setState(() {
        search = searchQuery;
        currentPage = 1;
      });

      fetchMessages(group?.id ?? 0, true);
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

  @override
  void dispose() {
    tabController.dispose();
    scrollController.removeListener(scrollListener);
    super.dispose();
  }

  Future<void> fetchMessages(int groupId, bool refresh) async {
    if (refresh) {
      if (isLoading) return;

      setState(() {
        isLoading = true;
        currentPage = 1;
        messages = [];
      });
    } else {
      if (isLoading || !hasMoreData) return;

      setState(() {
        isLoading = true;
      });
    }

    try {
      var getMessagesResponse = await AdminService.getMessagesOfGroup(
        groupId: groupId,
        page: currentPage,
        limit: limit,
        search: search,
      );

      setState(() {
        messages.addAll(getMessagesResponse.data);
        isLoading = false;
        hasMoreData = getMessagesResponse.data.length == limit;
        currentPage++;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void sendMessage(
    String title,
    String content,
    int timer,
    List<Map<String, dynamic>> filesArr,
  ) async {
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

    try {
      await AdminService.createMessage(
        [group?.id ?? 0],
        title,
        content,
        timer,
        filesArr,
      );

      await fetchMessages(group?.id ?? 0, true);
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        const snackBar = SnackBar(content: Text('Message Created'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        Navigator.of(context).pop();
      }
    } finally {
      setState(() {
        filesArr = [];
      });
    }
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

  Widget buildMessageList() {
    if (isLoading && messages.isEmpty) {
      return buildLoader();
    }

    if (messages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'No Messages Available',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => fetchMessages(group?.id ?? 0, true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100.0),
        controller: scrollController,
        itemCount: messages.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == messages.length) {
            return buildLoader();
          }

          GetMessagesResponseData message = messages[index];
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

          return MessageCard(
            messageId: messageId,
            title: message.title,
            content: message.content,
            showFullContent: false,
            createdByAvatar: message.createdBy.avatar,
            createdByName: message.createdBy.name,
            imageUrl: imageUrl,
            isUnread: null,
            files: message.files,
            time: time,
            onTap: () async {
              final reload = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessageDetail(),
                  settings: RouteSettings(
                    arguments: MessageDetailArgs(
                      message: message,
                      group: group,
                    ),
                  ),
                ),
              );

              if (reload == null) {
                fetchMessages(group?.id ?? 0, true);
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (search?.isNotEmpty == true) {
          setState(() {
            search = null;
            currentPage = 1;
          });

          await fetchMessages(group?.id ?? 0, true);
          return false;
        }

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            search?.isNotEmpty == true
                ? 'Result for "$search"'
                : '${group?.name} Messages',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: startSearch,
            )
          ],
        ),
        body: Stack(
          children: [
            buildMessageList(),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ChatTextField(onMessageSend: sendMessage),
            )
          ],
        ),
      ),
    );
  }
}
