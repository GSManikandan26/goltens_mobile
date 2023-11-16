import 'package:flutter/material.dart';
import 'package:goltens_core/models/admin.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_mobile/components/admin/admin_drawer.dart';
import 'package:goltens_mobile/components/admin/messages_detail.dart';
import 'package:goltens_core/components/admin/scrollable_data_table.dart';
import 'package:goltens_mobile/components/search_bar_delegate.dart';
import 'package:goltens_mobile/components/chat_text_field.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/services/admin.dart';

class Messages extends StatefulWidget {
  const Messages({super.key});

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  ScrollController scrollController = ScrollController();
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = false;
  bool isError = false;
  int limit = 50;
  String? search;
  List<GetGroupsResponseData> groups = [];
  List<Map<String, dynamic>> filesArr = [];
  GetGroupsResponseData? selectedGroup;
  List<GetGroupSearchResponseData> searchedGroups = [];
  List<int> selectedGroupsToSendMessage = [];
  GetMessagesResponseData? selectedMessage;
  List<String> selectedGroups = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      fetchGroups();
    });
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

      fetchGroups();
    }
  }

  Future<void> fetchGroups() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      var res = await AdminService.getGroups(
        page: currentPage,
        limit: limit,
        search: search,
      );

      setState(() {
        groups = res.data;
        isError = false;
        isLoading = false;
        totalPages = res.totalPages;
      });
    } catch (err) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  void nextPage() {
    if (currentPage < totalPages) {
      setState(() => currentPage++);
      fetchGroups();
    }
  }

  void prevPage() {
    if (currentPage > 1) {
      setState(() => currentPage--);
      fetchGroups();
    }
  }

  Future<GetGroupSearchResponse?> searchGroups(
    String search,
  ) async {
    try {
      var res = await AdminService.searchGroups(
        searchTerm: search,
      );

      return res;
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
      return null;
    }
  }

  void selectGroupsToSend(
    String title,
    String message,
    int timer,
    List<Map<String, dynamic>> filesArr,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.only(left: 25, right: 25),
          title: const Center(child: Text("Select Groups To Message")),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
          ),
          content: StatefulBuilder(
            builder: (
              BuildContext context,
              StateSetter setState,
            ) {
              var searchTextController = TextEditingController();

              return SizedBox(
                height: 400,
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: searchTextController,
                        decoration: InputDecoration(
                          labelText: 'Search...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () async {
                              if (searchTextController.text.isEmpty) {
                                const snackBar = SnackBar(
                                  content: Text(
                                    'Enter something to search for...,',
                                  ),
                                );

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    snackBar,
                                  );
                                }

                                return;
                              }

                              var groups = await searchGroups(
                                searchTextController.text,
                              );

                              if (groups != null) {
                                setState(() {
                                  searchedGroups = groups.data;
                                });
                              }
                            },
                            icon: const Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      searchedGroups.isNotEmpty
                          ? SizedBox(
                              height: 200,
                              child: ScrollableDataTable(
                                child: DataTable(
                                  showCheckboxColumn: true,
                                  columns: const <DataColumn>[
                                    DataColumn(label: Text('Avatar')),
                                    DataColumn(label: Text('Name')),
                                  ],
                                  rows: searchedGroups
                                      .map(
                                        (group) => DataRow(
                                          cells: <DataCell>[
                                            DataCell(
                                              CircleAvatar(
                                                radius: 16,
                                                child: group.avatar.isNotEmpty
                                                    ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          100.0,
                                                        ),
                                                        child: Image.network(
                                                          '$apiUrl/$groupsAvatar/${group.avatar}',
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
                                                    : Text(group.name[0]),
                                              ),
                                            ),
                                            DataCell(Text(group.name)),
                                          ],
                                          selected: selectedGroupsToSendMessage
                                              .contains(
                                            group.id,
                                          ),
                                          onSelectChanged: (isItemSelected) {
                                            setState(() {
                                              if (isItemSelected == true) {
                                                selectedGroupsToSendMessage
                                                    .add(group.id);
                                              } else {
                                                selectedGroupsToSendMessage
                                                    .remove(group.id);
                                              }
                                            });
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            )
                          : Container(),
                      const SizedBox(height: 15.0),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        onPressed: searchedGroups.isNotEmpty
                            ? () {
                                sendMessage(title, message, timer, filesArr);
                              }
                            : null,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 5.0),
                            Text('Send Message')
                          ],
                        ),
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

  void sendMessage(
    String title,
    String message,
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
        selectedGroupsToSendMessage,
        title,
        message,
        timer,
        filesArr,
      );

      if (mounted) Navigator.of(context).pop();
      const snackBar = SnackBar(content: Text('Message Created'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        Navigator.of(context).pop();
      }
    } finally {
      selectedGroupsToSendMessage = [];
      searchedGroups = [];
      await fetchGroups();
    }
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'No Groups Available',
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchGroups,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScrollableDataTable(
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Avatar')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Members')),
                    DataColumn(label: Text('Created At')),
                    DataColumn(label: Text('View')),
                  ],
                  rows: groups.map((group) {
                    var createdAt = formatDateTime(
                      group.createdAt,
                      'HH:mm dd/MM/y',
                    );

                    return DataRow(
                      onSelectChanged: (bool? selected) {
                        if (selected == true) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MessagesDetail(),
                              settings: RouteSettings(arguments: group),
                            ),
                          );
                        }
                      },
                      cells: <DataCell>[
                        DataCell(
                          CircleAvatar(
                            radius: 16,
                            child: group.avatar?.isNotEmpty == true
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(100.0),
                                    child: Image.network(
                                      '$apiUrl/$groupsAvatar/${group.avatar}',
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
                                : Text(group.name[0]),
                          ),
                        ),
                        DataCell(Text(group.name)),
                        DataCell(Text(group.members.length.toString())),
                        DataCell(Text(createdAt)),
                        DataCell(
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MessagesDetail(),
                                  settings: RouteSettings(arguments: group),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_right_outlined),
                          ),
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: currentPage == 1 ? null : prevPage,
                    splashRadius: 15.0,
                  ),
                  Text(
                    '${totalPages == 0 ? 0 : currentPage} / $totalPages',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: currentPage == totalPages ? null : nextPage,
                    splashRadius: 15.0,
                  ),
                ],
              ),
            ],
          ),
        ),
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

          await fetchGroups();
          return false;
        }

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            search?.isNotEmpty == true ? 'Results for "$search"' : 'Messages',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: startSearch,
            ),
          ],
        ),
        drawer: const AdminDrawer(currentIndex: 6),
        floatingActionButton: Visibility(
          visible: !isLoading && groups.isNotEmpty,
          child: ChatTextField(onMessageSend: selectGroupsToSend),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: buildBody(),
      ),
    );
  }
}
