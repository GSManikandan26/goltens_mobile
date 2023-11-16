import 'package:flutter/material.dart';
import 'package:goltens_core/models/admin.dart';
import 'package:goltens_mobile/components/admin/admin_drawer.dart';
import 'package:goltens_mobile/components/admin/groups.dart';
import 'package:goltens_mobile/components/admin/messages.dart';
import 'package:goltens_mobile/components/admin/pending_requests.dart';
import 'package:goltens_mobile/components/admin/risk_assessments.dart';
import 'package:goltens_mobile/components/admin/sub_admins.dart';
import 'package:goltens_mobile/components/admin/users.dart';
import 'package:goltens_core/services/admin.dart';

class CommunicationDashboard extends StatefulWidget {
  const CommunicationDashboard({super.key});

  @override
  State<CommunicationDashboard> createState() => _CommunicationDashboardState();
}

class _CommunicationDashboardState extends State<CommunicationDashboard> {
  int currentPage = 1;
  int totalPages = 1;
  int limit = 50;
  bool isLoading = false;
  bool isError = false;
  String? search;
  DashboardResponseData? dashboardData;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      fetchDashboardData();
    });
  }

  Future<void> fetchDashboardData() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      var res = await AdminService.getDashboardData();

      setState(() {
        dashboardData = res.data;
        isError = false;
        isLoading = false;
      });
    } catch (err) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication Dashboard'),
      ),
      drawer: const AdminDrawer(currentIndex: 0),
      body: RefreshIndicator(
        onRefresh: fetchDashboardData,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: isLoading
              ? const CircularProgressIndicator()
              : GridView.count(
                  scrollDirection: Axis.vertical,
                  crossAxisCount: 2,
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0,
                  childAspectRatio: 0.95,
                  children: [
                    Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Users(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 30.0,
                            horizontal: 16.0,
                          ),
                          child: SizedBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_circle_rounded,
                                  size: 48.0,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const Text(
                                  'Total Users',
                                  style: TextStyle(fontSize: 18.0),
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  dashboardData?.totalUsers.toString() ?? '-',
                                  style: const TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SubAdmins(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 30.0,
                            horizontal: 16.0,
                          ),
                          child: SizedBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.manage_accounts,
                                  size: 48.0,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const Text(
                                  'Total SubAdmins',
                                  style: TextStyle(fontSize: 18.0),
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  dashboardData?.totalSubAdmins.toString() ??
                                      '-',
                                  style: const TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Groups(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 30.0,
                            horizontal: 16.0,
                          ),
                          child: SizedBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.group,
                                  size: 48.0,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const Text(
                                  'Total Groups',
                                  style: TextStyle(fontSize: 18.0),
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  dashboardData?.totalGroups.toString() ?? '-',
                                  style: const TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PendingRequests(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 30.0,
                            horizontal: 16.0,
                          ),
                          child: SizedBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.done_all,
                                  size: 48.0,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const Text(
                                  'Pending Requests',
                                  style: TextStyle(fontSize: 18.0),
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  dashboardData?.totalPendingRequests
                                          .toString() ??
                                      '-',
                                  style: const TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Messages(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 30.0,
                            horizontal: 16.0,
                          ),
                          child: SizedBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.message,
                                  size: 48.0,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const Text(
                                  'Total Messages',
                                  style: TextStyle(fontSize: 18.0),
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  dashboardData?.totalMessages.toString() ??
                                      '-',
                                  style: const TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RiskAssessments(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 30.0,
                            horizontal: 16.0,
                          ),
                          child: SizedBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.list_alt_sharp,
                                  size: 48.0,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const Text(
                                  'Assessments',
                                  style: TextStyle(fontSize: 18.0),
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  dashboardData?.totalRiskAssessments
                                          .toString() ??
                                      '-',
                                  style: const TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
