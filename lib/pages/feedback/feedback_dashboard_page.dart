import 'package:flutter/material.dart';
import 'package:goltens_core/models/feedback.dart';
import 'package:goltens_mobile/components/feedback/feedback_drawer.dart';
import 'package:goltens_mobile/pages/feedback/feedback_list_page.dart';
import 'package:goltens_core/services/feedback.dart';

class FeedbackDashboardPage extends StatefulWidget {
  const FeedbackDashboardPage({super.key});

  @override
  State<FeedbackDashboardPage> createState() => _FeedbackDashboardPageState();
}

class _FeedbackDashboardPageState extends State<FeedbackDashboardPage> {
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
      var res = await FeedbackService.getFeedbackDashboardData();

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

  void openFeedbackList(String filter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FeedbackListPage(),
        settings: RouteSettings(arguments: filter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: const FeedbackDrawer(currentIndex: 1),
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
                        onTap: () => openFeedbackList('all'),
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
                                  dashboardData?.totalFeedbacks.toString() ??
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
                        onTap: () => openFeedbackList('green'),
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
                                  dashboardData?.greenFeedbacks.toString() ??
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
                        onTap: () => openFeedbackList('yellow'),
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
                                  dashboardData?.yellowFeedbacks.toString() ??
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
                        onTap: () => openFeedbackList('red'),
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
                                  dashboardData?.redFeedbacks.toString() ?? '-',
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
