import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/models/auth.dart';
import 'package:goltens_core/models/group.dart';
import 'package:goltens_core/models/other_files.dart';
import 'package:goltens_core/models/risk_assessment.dart';
import 'package:goltens_core/models/user_orientation.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_mobile/pages/risk_assessment/risk_assessment_detail.dart';
import 'package:goltens_mobile/pages/others/file_viewer_page.dart';
import 'package:goltens_core/services/auth.dart';
import 'package:goltens_core/services/group.dart';
import 'package:goltens_core/services/user_orientation.dart';
import 'package:goltens_core/services/other_files.dart';
import 'package:goltens_mobile/provider/global_state.dart';
import 'package:goltens_mobile/utils/functions.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  ScrollController groupsScrollController = ScrollController();
  ScrollController otherFilesScrollController = ScrollController();
  ScrollController userOrientationScrollController = ScrollController();
  final int limit = 15;

  int groupsPage = 1;
  List<GetAllGroupsResponseData> groups = [];
  bool isGroupsLoading = false;
  bool hasGroupsError = false;
  bool hasMoreGroups = true;

  int assessmentsPage = 1;
  List<GetAssessmentsResponseData> assessments = [];
  String? assessmentsSearch;
  bool isAssessmentsLoading = false;
  bool hasAssessmentsError = false;
  bool hasMoreAssessments = true;

  int otherFilesPage = 1;
  List<GetOtherFilesResponseData> otherFiles = [];
  String? otherFilesSearch;
  bool isOtherFilesLoading = false;
  bool hasOtherFilesError = false;
  bool hasMoreOtherFiles = true;

  int userOrientationPage = 1;
  List<GetUserOrientationItemsData> userOrientationItems = [];
  String? userOrientationSearch;
  bool isUserOrientationLoading = false;
  bool hasUserOrientationError = false;
  bool hasMoreuserOrientationItems = true;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    groupsScrollController.addListener(groupsScrollListener);
    otherFilesScrollController.addListener(otherFilesScrollListener);
    fetchGroups(false);
    fetchOtherFiles(false);
    fetchUserOrientationItems(false);
  }

  @override
  void dispose() {
    tabController.dispose();
    groupsScrollController.removeListener(groupsScrollListener);
    otherFilesScrollController.removeListener(otherFilesScrollListener);
    userOrientationScrollController.removeListener(orientationScrollListener);
    super.dispose();
  }

  void groupsScrollListener() {
    bool outOfRange = groupsScrollController.position.outOfRange;
    double offset = groupsScrollController.offset;

    if (offset >= groupsScrollController.position.maxScrollExtent &&
        outOfRange) {
      fetchGroups(false);
    }
  }

  void otherFilesScrollListener() {
    bool outOfRange = otherFilesScrollController.position.outOfRange;
    double offset = otherFilesScrollController.offset;

    if (offset >= otherFilesScrollController.position.maxScrollExtent &&
        outOfRange) {
      fetchOtherFiles(false);
    }
  }

  void orientationScrollListener() {
    bool outOfRange = userOrientationScrollController.position.outOfRange;
    double offset = userOrientationScrollController.offset;

    if (offset >= userOrientationScrollController.position.maxScrollExtent &&
        outOfRange) {
      fetchUserOrientationItems(false);
    }
  }

  Future<void> fetchGroups(bool refresh) async {
    if (!refresh) {
      if (isGroupsLoading || !hasMoreGroups) return;
    } else {
      if (isGroupsLoading) return;

      setState(() {
        groupsPage = 1;
        groups = [];
      });
    }

    setState(() {
      isGroupsLoading = true;
    });

    try {
      final response = await GroupService.getAllGroups(groupsPage, limit);
      final data = response.data;

      setState(() {
        groups.addAll(data);
        isGroupsLoading = false;
        groupsPage += 1;
        hasMoreGroups = groups.length == limit;
      });
    } catch (e) {
      setState(() {
        isGroupsLoading = false;
        hasGroupsError = true;
      });
    }
  }

  Future<void> fetchOtherFiles(bool refresh) async {
    if (!refresh) {
      if (isOtherFilesLoading || !hasMoreOtherFiles) return;
    } else {
      if (isOtherFilesLoading) return;

      setState(() {
        otherFilesPage = 1;
        otherFiles = [];
      });
    }

    setState(() {
      isOtherFilesLoading = true;
    });

    try {
      final response = await OtherFilesService.getOtherFilesItems(
        otherFilesPage,
        limit,
        otherFilesSearch,
      );

      setState(() {
        otherFiles.addAll(response.data);
        isOtherFilesLoading = false;
        hasMoreOtherFiles = otherFiles.length == limit;
      });
    } catch (e) {
      setState(() {
        isOtherFilesLoading = false;
        hasOtherFilesError = true;
      });
    }
  }

  Future<void> fetchUserOrientationItems(bool refresh) async {
    if (!refresh) {
      if (isUserOrientationLoading || !hasMoreuserOrientationItems) return;
    } else {
      if (isUserOrientationLoading) return;

      setState(() {
        userOrientationPage = 1;
        userOrientationItems = [];
      });
    }

    setState(() {
      isOtherFilesLoading = true;
    });

    try {
      final response = await UserOrientationService.getAllUserOrientationItems(
        userOrientationPage,
        limit,
        userOrientationSearch,
      );

      setState(() {
        userOrientationItems.addAll(response.data);
        isUserOrientationLoading = false;
        hasMoreuserOrientationItems = userOrientationItems.length == limit;
      });
    } catch (e) {
      setState(() {
        isUserOrientationLoading = false;
        hasUserOrientationError = true;
      });
    }
  }

  Future<void> retryFetchGroups() async {
    setState(() {
      hasGroupsError = false;
    });

    await fetchGroups(true);
  }

  Future<void> retryFetchOtherFiles() async {
    setState(() {
      hasOtherFilesError = false;
    });

    await fetchOtherFiles(true);
  }

  Future<void> retryFetchUserOrientationItems() async {
    setState(() {
      hasUserOrientationError = false;
    });

    await fetchUserOrientationItems(true);
  }

  Future<void> readUserOrientationItem(
    GetUserOrientationItemsData userOrientation,
  ) async {
    try {
      await UserOrientationService.readUserOrientationItem(userOrientation.id);
    } catch (e) {
      if (mounted) {
        const snackBar = SnackBar(
          content: Text('Cannot Read User Orientation'),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<GlobalState>().user?.data;

    List<PopupMenuItem<String>> popupMenuItems = [
      const PopupMenuItem(
        value: 'go-to-feedback',
        child: Text('Go To Feedback'),
      ),
      const PopupMenuItem(
        value: 'logout',
        child: Text('Logout'),
      ),
    ];

    if (user?.type == UserType.subAdmin) {
      popupMenuItems.insert(
        0,
        const PopupMenuItem(
          value: 'go-to-master-list',
          child: Text('Go To Master List'),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (tabController.index == 2) {
          // Other Files Page
          tabController.animateTo(1);
          return false;
        }

        if (tabController.index == 1) {
          // Risk Assessments Page
          tabController.animateTo(0);
          return false;
        }

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Communication App'),
          bottom: TabBar(
            controller: tabController,
            indicatorColor: Colors.white,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Groups'),
              Tab(text: 'Assessments'),
              Tab(text: 'Other Files'),
              Tab(text: 'User Orientation'),
            ],
          ),
          actions: <Widget>[
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              icon: const Icon(Icons.account_circle),
            ),
            PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'go-to-feedback':
                    Navigator.pushNamed(context, '/feedback');
                    break;
                  case 'go-to-master-list':
                    Navigator.pushNamed(context, '/master-list');
                    break;
                  case 'logout':
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title:
                              const Text("Are you sure you want to logout ?"),
                          actions: [
                            TextButton(
                              child: const Text("CANCEL"),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: const Text("OK"),
                              onPressed: () async {
                                await AuthService.logout();

                                if (mounted) {
                                  await authNavigate(context);
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                    break;
                  default:
                }
              },
              itemBuilder: (BuildContext context) {
                return popupMenuItems;
              },
            )
          ],
        ),
        body: TabBarView(
          controller: tabController,
          children: [
            buildGroupList(),
            buildAssessmentList(),
            buildOtherFilesList(),
            buildUserOrientationItemsList(),
          ],
        ),
      ),
    );
  }

  Widget buildGroupList() {
    if (isGroupsLoading && groups.isEmpty) {
      return buildLoader();
    }

    if (hasGroupsError) {
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
              onPressed: retryFetchGroups,
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

    if (groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
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
      );
    }

    return RefreshIndicator(
      onRefresh: () => fetchGroups(true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: groupsScrollController,
        itemCount: groups.length + 1,
        itemBuilder: (context, index) {
          if (index == groups.length) {
            return buildLoader();
          } else {
            return buildGroupListItem(groups[index]);
          }
        },
      ),
    );
  }

  Widget buildAssessmentList() {
    if (isGroupsLoading && groups.isEmpty) {
      return buildLoader();
    }

    if (hasGroupsError) {
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
              onPressed: retryFetchGroups,
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

    if (groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
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
      );
    }

    return RefreshIndicator(
      onRefresh: () => fetchGroups(true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: userOrientationScrollController,
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return buildAssessmentListItem(groups[index]);
        },
      ),
    );
  }

  Widget buildOtherFilesList() {
    if (isOtherFilesLoading && otherFiles.isEmpty) {
      return buildLoader();
    }

    if (hasOtherFilesError) {
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
              onPressed: retryFetchOtherFiles,
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

    if (otherFiles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'No Other Files Available',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => fetchOtherFiles(true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: otherFilesScrollController,
        itemCount: otherFiles.length,
        itemBuilder: (context, index) {
          return buildOtherFileListItem(otherFiles[index]);
        },
      ),
    );
  }

  Widget buildUserOrientationItemsList() {
    if (isUserOrientationLoading && userOrientationItems.isEmpty) {
      return buildLoader();
    }

    if (hasUserOrientationError) {
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
              onPressed: retryFetchUserOrientationItems,
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

    if (userOrientationItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'No User Orientation Files Available',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => fetchUserOrientationItems(true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: userOrientationScrollController,
        itemCount: userOrientationItems.length,
        itemBuilder: (context, index) {
          return buildUserOrientationListItem(userOrientationItems[index]);
        },
      ),
    );
  }

  Widget buildLoader() {
    bool hasMoreData = !hasMoreGroups ||
        !hasMoreAssessments ||
        !hasMoreOtherFiles ||
        !hasMoreuserOrientationItems;

    if (hasMoreData) {
      return Container();
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }

  Future<File?> fetchPdf(String url) async {
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

  Widget buildGroupListItem(GetAllGroupsResponseData group) {
    var unreadMessages = group.unreadMessages;
    var time = '';

    if (unreadMessages.isNotEmpty) {
      time = formatDateTime(unreadMessages.last.createdAt, 'HH:mm dd/MM');
    }

    return ListTile(
      leading: CircleAvatar(
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
      title: Text(group.name),
      subtitle: Text(
        unreadMessages.isNotEmpty
            ? '${unreadMessages.last.content.replaceAll('\n', '')}...'
            : '- No New Messages -',
        maxLines: 2,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(time),
          const SizedBox(height: 5.0),
          unreadMessages.isNotEmpty
              ? Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unreadMessages.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : const SizedBox()
        ],
      ),
      onTap: () async {
        final reload = await Navigator.pushNamed(
          context,
          '/group-detail',
          arguments: group,
        );

        if (reload == null) {
          await fetchGroups(true); // Refresh Messages on Pop
        }
      },
    );
  }

  Widget buildAssessmentListItem(
    GetAllGroupsResponseData group,
  ) {
    return ListTile(
      leading: CircleAvatar(
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
      title: Text(group.name),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/assessment-detail',
          arguments: AssessmentDetailPageArgs(
            groupName: group.name,
            groupId: group.id,
          ),
        );
      },
    );
  }

  Widget buildOtherFileListItem(
    GetOtherFilesResponseData otherFile,
  ) {
    var time = formatDateTime(otherFile.createdAt, 'HH:mm dd/MM');

    return ListTile(
      title: Text(otherFile.name),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(time),
        ],
      ),
      onTap: () async {
        var url = '$apiUrl/$otherFileDir/${otherFile.name}';
        var file = await fetchPdf(url);

        if (file != null) {
          if (mounted) {
            Navigator.pushNamed(
              context,
              '/file-viewer',
              arguments: FileViewerPageArgs(
                file: file,
                url: url,
                fileType: FileType.any,
              ),
            );
          }
        }
      },
    );
  }

  Widget buildUserOrientationListItem(
    GetUserOrientationItemsData userOrientation,
  ) {
    var time = formatDateTime(userOrientation.createdAt, 'HH:mm dd/MM');

    return ListTile(
      title: Text(userOrientation.name),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(time),
        ],
      ),
      onTap: () async {
        var url = '$apiUrl/$userOrientationDir/${userOrientation.name}';
        var file = await fetchPdf(url);

        await readUserOrientationItem(userOrientation);

        if (file != null) {
          if (mounted) {
            Navigator.pushNamed(
              context,
              '/file-viewer',
              arguments: FileViewerPageArgs(
                file: file,
                url: url,
                fileType: FileType.any,
              ),
            );
          }
        }
      },
    );
  }
}
