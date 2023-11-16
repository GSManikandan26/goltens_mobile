import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/models/risk_assessment.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_mobile/pages/others/file_viewer_page.dart';
import 'package:goltens_core/services/risk_assessment.dart';
import 'package:goltens_mobile/utils/functions.dart';

class AssessmentDetailPageArgs {
  final String groupName;
  final int groupId;

  const AssessmentDetailPageArgs({
    Key? key,
    required this.groupName,
    required this.groupId,
  });
}

class AssessmentDetailPage extends StatefulWidget {
  const AssessmentDetailPage({super.key});

  @override
  State<AssessmentDetailPage> createState() => _AssessmentDetailPageState();
}

class _AssessmentDetailPageState extends State<AssessmentDetailPage> {
  ScrollController assessmentsScrollController = ScrollController();
  final int limit = 50;
  int assessmentsPage = 1;
  List<GetAssessmentsResponseData> assessments = [];
  String? assessmentsSearch;
  bool isAssessmentsLoading = false;
  bool hasAssessmentsError = false;
  bool hasMoreAssessments = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      fetchAssessments(false);
      assessmentsScrollController.addListener(assessmentsScrollListener);
    });
  }

  @override
  void dispose() {
    assessmentsScrollController.removeListener(assessmentsScrollListener);
    super.dispose();
  }

  void assessmentsScrollListener() {
    bool outOfRange = assessmentsScrollController.position.outOfRange;
    double offset = assessmentsScrollController.offset;

    if (offset >= assessmentsScrollController.position.maxScrollExtent &&
        outOfRange) {
      fetchAssessments(false);
    }
  }

  Future<void> fetchAssessments(bool refresh) async {
    if (!refresh) {
      if (isAssessmentsLoading || !hasMoreAssessments) return;
    } else {
      if (isAssessmentsLoading) return;

      setState(() {
        assessmentsPage = 1;
        assessments = [];
      });
    }

    setState(() {
      isAssessmentsLoading = true;
    });

    try {
      final settings = ModalRoute.of(context)!.settings;
      final args = settings.arguments as AssessmentDetailPageArgs;

      final response = await RiskAssessmentService.getRiskAssessmentItems(
        assessmentsPage,
        limit,
        args.groupId,
        assessmentsSearch,
      );

      setState(() {
        assessments.addAll(response.data);
        isAssessmentsLoading = false;
        hasMoreAssessments = assessments.length == limit;
      });
    } catch (e) {
      setState(() {
        isAssessmentsLoading = false;
        hasAssessmentsError = true;
      });
    }
  }

  Future<void> retryFetchAssessments() async {
    setState(() {
      hasAssessmentsError = false;
    });

    await fetchAssessments(true);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as AssessmentDetailPageArgs;

    return Scaffold(
      appBar: AppBar(
        title: Text('${args.groupName} - Assessments'),
      ),
      body: buildAssessmentList(),
    );
  }

  Widget buildAssessmentList() {
    if (isAssessmentsLoading && assessments.isEmpty) {
      return buildLoader();
    }

    if (hasAssessmentsError) {
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
              onPressed: retryFetchAssessments,
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

    if (assessments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'No Assessments Available',
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => fetchAssessments(true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: assessmentsScrollController,
        itemCount: assessments.length,
        itemBuilder: (context, index) {
          return buildAssessmentListItem(assessments[index]);
        },
      ),
    );
  }

  Widget buildLoader() {
    if (!hasMoreAssessments) {
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

  Widget buildAssessmentListItem(
    GetAssessmentsResponseData assessment,
  ) {
    var time = formatDateTime(assessment.createdAt, 'HH:mm dd/MM/y');

    return ListTile(
      title: Text(assessment.name),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(time),
        ],
      ),
      onTap: () async {
        var url = '$apiUrl/$riskAssessmentDir/${assessment.name}';
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
}
