import 'package:flutter/material.dart';
import 'package:goltens_core/models/admin.dart';
import 'package:goltens_mobile/components/admin/admin_drawer.dart';
import 'package:goltens_mobile/components/search_bar_delegate.dart';
import 'package:goltens_core/components/admin/scrollable_data_table.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/services/admin.dart';

class PendingRequests extends StatefulWidget {
  const PendingRequests({super.key});

  @override
  State<PendingRequests> createState() => _PendingRequestsState();
}

class _PendingRequestsState extends State<PendingRequests> {
  int currentPage = 1;
  int totalPages = 1;
  int limit = 50;
  bool isLoading = false;
  bool isError = false;
  String? search;
  List<GetUsersResponseData> pendingRequests = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      fetchPendingRequests();
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

      fetchPendingRequests();
    }
  }

  Future<void> fetchPendingRequests() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      var res = await AdminService.getPendingRequests(
        page: currentPage,
        limit: limit,
        search: search,
      );

      setState(() {
        pendingRequests = res.data;
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
      fetchPendingRequests();
    }
  }

  void prevPage() {
    if (currentPage > 1) {
      setState(() => currentPage--);
      fetchPendingRequests();
    }
  }

  void updateAdminApproved(
    GetUsersResponseData user,
    AdminApproved adminApproved,
  ) async {
    try {
      await AdminService.updateAdminApproved(
        id: user.id,
        adminApproved: adminApproved,
      );

      fetchPendingRequests();

      if (mounted) {
        final snackBar = SnackBar(
          content: Text(
            adminApproved == AdminApproved.approved
                ? 'Request Accepted'
                : 'Request Rejected',
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (pendingRequests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'No Pending Requests Available',
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchPendingRequests,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScrollableDataTable(
                child: DataTable(
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Avatar')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Department')),
                    DataColumn(label: Text('Employee Number')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Accept')),
                    DataColumn(label: Text('Reject')),
                  ],
                  rows: pendingRequests
                      .map(
                        (user) => DataRow(
                          cells: <DataCell>[
                            DataCell(
                              CircleAvatar(
                                radius: 16,
                                child: user.avatar?.isNotEmpty == true
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
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
                            ),
                            DataCell(Text(user.name)),
                            DataCell(Text(user.email)),
                            DataCell(Text(user.phone)),
                            DataCell(Text(user.department)),
                            DataCell(Text(user.employeeNumber)),
                            DataCell(Text(user.type.name)),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.done),
                                color: Theme.of(context).primaryColor,
                                onPressed: () => updateAdminApproved(
                                  user,
                                  AdminApproved.approved,
                                ),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                onPressed: () => updateAdminApproved(
                                  user,
                                  AdminApproved.rejected,
                                ),
                                color: Colors.redAccent,
                                icon: const Icon(Icons.block),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
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

          await fetchPendingRequests();
          return false;
        }

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            search?.isNotEmpty == true
                ? 'Results for "$search"'
                : 'Pending Requests',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: startSearch,
            )
          ],
        ),
        drawer: const AdminDrawer(currentIndex: 1),
        body: buildBody(),
      ),
    );
  }
}
