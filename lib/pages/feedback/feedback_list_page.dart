import 'package:flutter/material.dart';
import 'package:goltens_core/models/feedback.dart';
import 'package:goltens_mobile/pages/feedback/feedback_page.dart';
import 'package:goltens_core/services/feedback.dart';

class FeedbackListPage extends StatefulWidget {
  const FeedbackListPage({super.key});

  @override
  State<FeedbackListPage> createState() => _FeedbackListPageState();
}

class _FeedbackListPageState extends State<FeedbackListPage> {
  int page = 1;
  String filter = 'all';
  final int limit = 50;
  bool isLoading = false;
  bool hasMoreData = true;
  bool hasError = false;
  List<FeedbackData> feedbacks = [];
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = ModalRoute.of(context)!.settings;
      final filterValue = settings.arguments as String;
      scrollController.addListener(scrollListener);
      setState(() => filter = filterValue);
      fetchFeedbacks(false);
    });
  }

  void scrollListener() {
    bool outOfRange = scrollController.position.outOfRange;
    double offset = scrollController.offset;

    if (offset >= scrollController.position.maxScrollExtent && outOfRange) {
      fetchFeedbacks(false);
    }
  }

  Future<void> fetchFeedbacks(bool refresh) async {
    if (!refresh) {
      if (isLoading || !hasMoreData) return;
    } else {
      if (isLoading) return;

      setState(() {
        page = 1;
        feedbacks = [];
      });
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await FeedbackService.getFeedbacks(
        page: page,
        limit: limit,
        filter: filter,
      );

      setState(() {
        feedbacks.addAll(response.data);
        isLoading = false;
        page += 1;
        hasMoreData = feedbacks.length == limit;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Widget buildBody() {
    if (isLoading && feedbacks.isEmpty) {
      return buildLoader();
    }

    if (hasError) {
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
              onPressed: () => fetchFeedbacks(true),
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

    if (feedbacks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'No Feedbacks Available',
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => fetchFeedbacks(true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: scrollController,
        itemCount: feedbacks.length + 1,
        itemBuilder: (context, index) {
          if (index == feedbacks.length) {
            return buildLoader();
          } else {
            return buildFeedbackListItem(feedbacks[index]);
          }
        },
      ),
    );
  }

  Widget buildFeedbackListItem(FeedbackData feedback) {
    return ListTile(
      title: Text(
        'Feedback - FB${feedback.id} on ${feedback.date} ${feedback.time}',
      ),
      subtitle: Text(
        feedback.description,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FeedbackPage(),
            settings: RouteSettings(arguments: feedback),
          ),
        );
      },
    );
  }

  Widget buildLoader() {
    if (!hasMoreData) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedbacks Submitted'),
      ),
      body: buildBody(),
    );
  }
}
