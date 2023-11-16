import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goltens_core/models/admin.dart';
import 'package:goltens_core/models/master_list.dart';
import 'package:goltens_core/utils/csv_generator.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_mobile/components/admin/admin_drawer.dart';
import 'package:goltens_core/components/admin/scrollable_data_table.dart';
import 'package:goltens_mobile/components/search_bar_delegate.dart';
import 'package:goltens_mobile/pages/others/file_viewer_page.dart';
import 'package:goltens_core/services/admin.dart';
import 'package:goltens_core/services/master_list.dart';
import 'package:goltens_mobile/utils/functions.dart';
import 'package:goltens_core/constants/constants.dart';

class MasterList extends StatefulWidget {
  const MasterList({super.key});

  @override
  State<MasterList> createState() => _MasterListState();
}

class _MasterListState extends State<MasterList>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  int currentPage = 1;
  int totalPages = 1;
  int limit = 50;
  int groupsLimit = 50;
  String? search;
  bool isLoading = false;
  bool isError = false;
  String filter = 'unread';
  List<ReadStatusUser> readUsers = [];
  List<ReadStatusUser> unReadUsers = [];
  List<GetMasterListResponseData> data = [];
  List<GetGroupsResponseData> groupsData = [];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(tabListener);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      fetchGroups();
      fetchMasterList();
    });
  }

  @override
  void dispose() {
    super.dispose();
    tabController.removeListener(tabListener);
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

      fetchMasterList();
    }
  }

  Future<void> fetchGroups() async {
    try {
      var res = await AdminService.getGroups(
        page: 1,
        limit: groupsLimit,
        search: '',
      );

      setState(() {
        groupsData = res.data;
        isError = false;
      });
    } catch (err) {
      setState(() {
        isError = true;
      });
    }
  }

  Future<void> fetchMasterList() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      var res = await MasterListService.getMasterList(
        page: currentPage,
        limit: limit,
        search: search,
      );

      setState(() {
        data = res.data;
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
      fetchMasterList();
    }
  }

  void prevPage() {
    if (currentPage > 1) {
      setState(() => currentPage--);
      fetchMasterList();
    }
  }

  Future<void> exportCsvFile() async {
    var res = await MasterListService.getMasterList(
      page: 1,
      limit: 10000000,
      search: '',
    );

    String csvData = CSVGenerator.generateMasterList(groupsData, res.data);
    final directory = await getDownloadsDirectoryPath();
    File file = File('$directory/master-list.csv');
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

  Future<void> fetchReadStatus(int messageId, int groupId) async {
    if (isLoading) {
      return;
    }

    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      var response = await AdminService.getMessageReadStatus(
        messageId,
        groupId,
      );

      setState(() {
        readUsers = response.readUsers;
        unReadUsers = response.unreadUsers;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  Future<void> showReadInfoDialog(
    GetMasterListResponseData message,
    GetGroupsResponseData group,
  ) async {
    await fetchReadStatus(message.id, group.id);
    if (!mounted) return;

    var messageId = formatDateTime(
      message.createdAt,
      'yyMM\'SN${message.id}\'',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Read Info of "${message.title} - $messageId" (${group.name})',
          ),
          content: StatefulBuilder(
            builder: (
              BuildContext context,
              StateSetter setState,
            ) {
              return SizedBox(
                height: 380,
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      controller: tabController,
                      labelColor: Theme.of(context).primaryColor,
                      tabs: const [
                        Tab(text: 'Unread'),
                        Tab(text: 'Read'),
                      ],
                      onTap: (index) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          Center(child: buildStatusList('unread')),
                          Center(child: buildStatusList('read')),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildLoader() {
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

    if (isError) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
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
              onPressed: () => fetchMasterList,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
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

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: users.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index != users.length) {
          ReadStatusUser user = users[index];
          var time = '';

          if (filter == 'read' && user.readAt != null) {
            time = formatDateTime(user.readAt!, 'HH:mm dd/MM/y');
          }

          String userReply = user.reply != null ? '(${user.reply})' : '';

          return ListTile(
            title: Text(user.name),
            subtitle: Text(userReply),
            leading: CircleAvatar(
              radius: 12,
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
    );
  }

  List<DataColumn> generateDataColumns() {
    final dataColumns = <DataColumn>[
      const DataColumn(label: Text('SNO')),
      const DataColumn(label: Text('Title')),
      const DataColumn(label: Text('Group\'s Assigned')),
      const DataColumn(label: Text('Created By')),
      const DataColumn(label: Text('Created Date')),
      const DataColumn(label: Text('Time')),
      const DataColumn(label: Text('File Link')),
    ];

    for (var group in groupsData) {
      dataColumns.add(
        DataColumn(
          label: Text(
            '${group.name}\n(Read / Clarify / Unread)',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return dataColumns;
  }

  List<DataCell> generateDataCell(GetMasterListResponseData item) {
    final createdDate = formatDateTime(item.createdAt, 'dd/MM/y');
    final time = formatDateTime(item.createdAt, 'HH:mm');

    final messageId = formatDateTime(
      item.createdAt,
      'yyMM\'SN${item.id}\'',
    );

    final Uri url;

    if (item.files.isNotEmpty) {
      url = Uri.parse('$apiUrl/$groupData/${item.files[0].name}');
    } else {
      url = Uri.parse('');
    }

    final groupsAssigned = item.groups.map((e) => e.name).toList();

    final dataCells = <DataCell>[
      DataCell(Text(messageId)),
      DataCell(Text(item.title)),
      DataCell(Text(groupsAssigned.join('/'))),
      DataCell(Text(item.createdBy.name)),
      DataCell(Text(createdDate)),
      DataCell(Text(time)),
      DataCell(
        onLongPress: () {
          const snackBar = SnackBar(
            content: Text('Link Copied'),
          );

          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          Clipboard.setData(ClipboardData(text: url.toString()));
        },
        SizedBox(
          width: 150,
          child: Text(
            url.toString(),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        onTap: item.files.isNotEmpty
            ? () async {
                var file = await fetchFile(url.toString());

                if (file != null) {
                  if (mounted) {
                    Navigator.pushNamed(
                      context,
                      '/file-viewer',
                      arguments: FileViewerPageArgs(
                        file: file,
                        url: url.toString(),
                        fileType: nameToFileType(item.files[0].fileType),
                      ),
                    );
                  }
                }
              }
            : null,
      ),
    ];

    for (var group in groupsData) {
      final groupExists = item.groups.any((el) => el.id == group.id);

      if (groupExists) {
        final value = item.groups.firstWhere((el) => el.id == group.id);
        final readCount = value.readUsersCount;
        final clarifyCount = value.clarifyUsersCount;
        final unreadCount = value.unReadUsersCount;

        dataCells.add(
          DataCell(
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$readCount',
                      style: const TextStyle(color: Colors.green),
                    ),
                    const TextSpan(
                      text: ' / ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: '$clarifyCount',
                      style: const TextStyle(color: Colors.amber),
                    ),
                    const TextSpan(
                      text: ' / ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: '$unreadCount',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            onTap: () => showReadInfoDialog(item, group),
          ),
        );
      } else {
        dataCells.add(
          DataCell(
            Center(
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: '0',
                      style: TextStyle(color: Colors.green),
                    ),
                    TextSpan(
                      text: ' / ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: '0',
                      style: TextStyle(color: Colors.amber),
                    ),
                    TextSpan(
                      text: ' / ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: '0',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            onTap: () => showReadInfoDialog(item, group),
          ),
        );
      }
    }

    return dataCells;
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'No Files Available',
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchMasterList,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                child: ScrollableDataTable(
                  child: DataTable(
                    columns: generateDataColumns(),
                    rows: data
                        .map((item) => DataRow(cells: generateDataCell(item)))
                        .toList(),
                  ),
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
                  Text('${totalPages == 0 ? 0 : currentPage} / $totalPages'),
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

          await fetchMasterList();
          return false;
        }

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            search?.isNotEmpty == true
                ? 'Results for "$search"'
                : 'Master List',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: startSearch,
            ),
            PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'export-csv':
                    exportCsvFile();
                    break;
                  default:
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem(
                    value: 'export-csv',
                    child: Text('Export CSV'),
                  ),
                ];
              },
            )
          ],
        ),
        drawer: const AdminDrawer(currentIndex: 7),
        body: buildBody(),
      ),
    );
  }
}
