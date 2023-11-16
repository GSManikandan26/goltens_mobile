import 'package:flutter/material.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_mobile/components/admin/admin_drawer.dart';
import 'package:goltens_mobile/components/admin/risk_assessment_detail.dart';
import 'package:goltens_mobile/components/search_bar_delegate.dart';
import 'package:goltens_core/components/admin/scrollable_data_table.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/models/admin.dart';
import 'package:goltens_core/services/admin.dart';

class RiskAssessments extends StatefulWidget {
  const RiskAssessments({super.key});

  @override
  State<RiskAssessments> createState() => _RiskAssessmentsState();
}

class _RiskAssessmentsState extends State<RiskAssessments>
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
                              builder: (context) =>
                                  const RiskAssessmentDetail(),
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
                                  builder: (context) =>
                                      const RiskAssessmentDetail(),
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
            search?.isNotEmpty == true
                ? 'Results for "$search"'
                : 'Risk Assessments',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: startSearch,
            ),
          ],
        ),
        drawer: const AdminDrawer(currentIndex: 8),
        body: buildBody(),
      ),
    );
  }
}
