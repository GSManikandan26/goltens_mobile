import 'package:flutter/material.dart';
import 'package:goltens_mobile/components/admin/feedback/admin_feedback_drawer.dart';
import 'package:goltens_mobile/components/admin/feedback/feedbacks.dart';
import 'package:goltens_core/models/admin.dart';
import 'package:goltens_core/services/admin.dart';

class FeedbackAdminDashboard extends StatefulWidget {
  const FeedbackAdminDashboard({super.key});

  @override
  State<FeedbackAdminDashboard> createState() => _FeedbackAdminDashboardState();
}

class _FeedbackAdminDashboardState extends State<FeedbackAdminDashboard> {
  int currentPage = 1;
  int totalPages = 1;
  int limit = 50;
  bool isLoading = false;
  bool isError = false;
  String? search;
  FeedbackDashboardData? dashboardData;

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
      var res = await AdminService.getFeedbackDashboardData();

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

  void openFeedbackList(String color, String status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Feedbacks(),
        settings: RouteSettings(
          arguments: FeedbacksArgs(
            color: color,
            status: status,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Dashboard'),
      ),
      drawer: const AdminFeedbackDrawer(currentIndex: 0),
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
                        onTap: () => openFeedbackList('all', 'all'),
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
                                  Icons.feedback,
                                  size: 48.0,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const Text(
                                  'Total Feedbacks',
                                  style: TextStyle(fontSize: 18.0),
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  dashboardData?.totalFeedback.toString() ??
                                      '-',
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
                        onTap: () => openFeedbackList('red', 'all'),
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
                                  Icons.feedback,
                                  size: 48.0,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const Text(
                                  'Red Feedbacks',
                                  style: TextStyle(fontSize: 18.0),
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  dashboardData?.redFeedback.toString() ?? '-',
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
                        onTap: () => openFeedbackList('yellow', 'all'),
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
                                  Icons.feedback,
                                  size: 48.0,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const Text(
                                  'Yellow Feedbacks',
                                  style: TextStyle(fontSize: 18.0),
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  dashboardData?.yellowFeedback.toString() ??
                                      '-',
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
                        onTap: () => openFeedbackList('green', 'all'),
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
                                  Icons.feedback,
                                  size: 48.0,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const Text(
                                  'Green Feedbacks',
                                  style: TextStyle(fontSize: 18.0),
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  dashboardData?.greenFeedback.toString() ??
                                      '-',
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
                        onTap: () => openFeedbackList('all', 'inProgress'),
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
                                  Icons.refresh_outlined,
                                  size: 48.0,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const Text(
                                  'In Progress',
                                  style: TextStyle(fontSize: 18.0),
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  dashboardData?.inProgress.toString() ?? '-',
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
                        onTap: () => openFeedbackList('all', 'rejected'),
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
                                  Icons.close,
                                  size: 48.0,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const Text(
                                  'Rejected',
                                  style: TextStyle(fontSize: 18.0),
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  dashboardData?.rejected.toString() ?? '-',
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
                        onTap: () => openFeedbackList('all', 'closed'),
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
                                  Icons.done,
                                  size: 48.0,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const Text(
                                  'Closed',
                                  style: TextStyle(fontSize: 18.0),
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  dashboardData?.closed.toString() ?? '-',
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
                        onTap: () =>
                            openFeedbackList('all', 'closedWithoutAction'),
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
                                  'Closed Without Action',
                                  style: TextStyle(fontSize: 18.0),
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  dashboardData?.closedWithoutAction
                                          .toString() ??
                                      '-',
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
                  ],
                ),
        ),
      ),
    );
  }
}
