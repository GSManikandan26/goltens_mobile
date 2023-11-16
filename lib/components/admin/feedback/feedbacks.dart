import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/utils/csv_generator.dart';
import 'package:goltens_mobile/components/admin/feedback/admin_feedback_drawer.dart';
import 'package:goltens_mobile/components/search_bar_delegate.dart';
import 'package:goltens_mobile/components/admin/feedback/feedback_detail.dart';
import 'package:goltens_core/components/admin/scrollable_data_table.dart';
import 'package:goltens_core/models/admin.dart';
import 'package:goltens_core/services/admin.dart';
import 'package:goltens_mobile/pages/others/file_viewer_page.dart';
import 'package:goltens_mobile/utils/functions.dart';

class FeedbacksArgs {
  final String color;
  final String status;

  const FeedbacksArgs({
    Key? key,
    required this.color,
    required this.status,
  });
}

class Feedbacks extends StatefulWidget {
  const Feedbacks({super.key});

  @override
  State<Feedbacks> createState() => _FeedbacksState();
}

class _FeedbacksState extends State<Feedbacks> {
  int currentPage = 1;
  int totalPages = 1;
  int limit = 40;
  bool isLoading = false;
  bool isError = false;
  String color = 'all';
  String status = 'all';
  String? search;
  List<GetFeedbacksResponseData> feedbacks = [];
  List<int> selectedFeedbacks = [];
  FeedbacksArgs? args;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = ModalRoute.of(context)!.settings;
      final argsData = settings.arguments as FeedbacksArgs?;

      if (argsData != null) {
        setState(() {
          args = argsData;
          color = argsData.color;
          status = argsData.status;
        });
      }

      fetchFeedbacks();
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

      fetchFeedbacks();
    }
  }

  Future<void> exportCsvFile() async {
    var res = await AdminService.getFeedbacks(
      page: 1,
      limit: 10000000,
      search: search,
      color: color,
      status: status,
    );

    String csvData = CSVGenerator.generateFeedbacks(res.data);
    final directory = await getDownloadsDirectoryPath();
    File file = File('$directory/feedbacks.csv');
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

  Future<void> fetchFeedbacks() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      var res = await AdminService.getFeedbacks(
        page: currentPage,
        limit: limit,
        search: search,
        color: color,
        status: status,
      );

      setState(() {
        feedbacks = res.data;
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

  void deleteFeedbacks() async {
    try {
      await AdminService.deleteFeedbacks(feedbackIds: selectedFeedbacks);

      if (mounted) {
        const snackBar = SnackBar(content: Text('Feedbacks Deleted'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      await fetchFeedbacks();
      setState(() => selectedFeedbacks = []);
    }
  }

  void nextPage() {
    if (currentPage < totalPages) {
      setState(() => currentPage++);
      fetchFeedbacks();
    }
  }

  void prevPage() {
    if (currentPage > 1) {
      setState(() => currentPage--);
      fetchFeedbacks();
    }
  }

  Color getColorForFeedback(String color) {
    if (color == 'red') return Colors.red;
    if (color == 'yellow') return Colors.yellow;
    if (color == 'green') return Colors.green;
    throw Exception('$color Not Supported');
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

  void openFeedback(GetFeedbacksResponseData feedback) async {
    final reload = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FeedbackDetail(),
        settings: RouteSettings(
          arguments: feedback,
        ),
      ),
    );

    if (reload == null) {
      await fetchFeedbacks();
    }
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (feedbacks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
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
      onRefresh: fetchFeedbacks,
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
                    DataColumn(label: Text('Color Code')),
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Location')),
                    DataColumn(label: Text('Organization')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('Feedback')),
                    DataColumn(label: Text('Source')),
                    DataColumn(label: Text('Causes')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Photo')),
                    DataColumn(label: Text('Reported By')),
                    DataColumn(label: Text('Assigned Person')),
                    DataColumn(label: Text('Action Taken')),
                    DataColumn(label: Text('Photo')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('User Acknowledgement')),
                  ],
                  dataRowMinHeight: 100,
                  dataRowMaxHeight: 100,
                  rows: feedbacks
                      .map(
                        (feedback) => DataRow(
                          cells: <DataCell>[
                            DataCell(
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Container(
                                  color: getColorForFeedback(feedback.color),
                                ),
                              ),
                            ),
                            DataCell(
                              Text('FB${feedback.id}'),
                              onTap: () => openFeedback(feedback),
                            ),
                            DataCell(
                              Text(feedback.location),
                              onTap: () => openFeedback(feedback),
                            ),
                            DataCell(
                              Text(feedback.organizationName),
                              onTap: () => openFeedback(feedback),
                            ),
                            DataCell(
                              Text(feedback.date),
                              onTap: () => openFeedback(feedback),
                            ),
                            DataCell(
                              Text(feedback.time),
                              onTap: () => openFeedback(feedback),
                            ),
                            DataCell(
                              Text(feedback.feedback),
                              onTap: () => openFeedback(feedback),
                            ),
                            DataCell(
                              Text(feedback.source),
                              onTap: () => openFeedback(feedback),
                            ),
                            DataCell(
                              Text(feedback.selectedValues),
                              onTap: () => openFeedback(feedback),
                            ),
                            DataCell(
                              Text(feedback.description),
                              onTap: () => openFeedback(feedback),
                            ),
                            DataCell(
                              SizedBox(
                                width: 200,
                                child: Text(
                                  feedback.files.isNotEmpty
                                      ? Uri.parse(
                                          '$apiUrl/$feedbackData/${feedback.files[0].name}',
                                        ).toString()
                                      : '-',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              onLongPress: () {
                                const snackBar = SnackBar(
                                  content: Text('Link Copied'),
                                );

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
                                Clipboard.setData(
                                  ClipboardData(
                                    text: Uri.parse(
                                      '$apiUrl/$feedbackData/${feedback.files[0].name}',
                                    ).toString(),
                                  ),
                                );
                              },
                              onTap: feedback.files.isNotEmpty
                                  ? () async {
                                      var file = await fetchFile(
                                        Uri.parse(
                                          '$apiUrl/$feedbackData/${feedback.files[0].name}',
                                        ).toString(),
                                      );

                                      if (file != null) {
                                        if (mounted) {
                                          Navigator.pushNamed(
                                            context,
                                            '/file-viewer',
                                            arguments: FileViewerPageArgs(
                                              file: file,
                                              url: Uri.parse(
                                                '$apiUrl/$feedbackData/${feedback.files[0].name}',
                                              ).toString(),
                                              fileType: FileType.image,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  : null,
                            ),
                            DataCell(
                              Text(feedback.reportedBy),
                              onTap: () => openFeedback(feedback),
                            ),
                            DataCell(
                              Text(
                                feedback.feedbackAssignments.isNotEmpty
                                    ? feedback.feedbackAssignments[0].user.name
                                    : '-',
                              ),
                              onTap: () => openFeedback(feedback),
                            ),
                            DataCell(
                              Text(feedback.actionTaken ?? '-'),
                              onTap: () => openFeedback(feedback),
                            ),
                            DataCell(
                              feedback.actionFiles.isNotEmpty
                                  ? Image.network(
                                      '$apiUrl/$feedbackData/${feedback.actionFiles[0].name}',
                                      width: 250,
                                      height: 250,
                                    )
                                  : const Text('-'),
                              onTap: () => openFeedback(feedback),
                            ),
                            DataCell(
                              Text(feedback.status?.name ?? '-'),
                              onTap: () => openFeedback(feedback),
                            ),
                            DataCell(
                              Text(feedback.acknowledgement ?? '-'),
                              onTap: () => openFeedback(feedback),
                            ),
                          ],
                          selected: selectedFeedbacks.contains(feedback.id),
                          onSelectChanged: (isItemSelected) {
                            setState(() {
                              if (isItemSelected == true) {
                                selectedFeedbacks.add(feedback.id);
                              } else {
                                selectedFeedbacks.remove(feedback.id);
                              }
                            });
                          },
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

          await fetchFeedbacks();
          return false;
        }

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            search?.isNotEmpty == true ? 'Results for "$search"' : 'Feedbacks',
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
        drawer:
            args == null ? const AdminFeedbackDrawer(currentIndex: 1) : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: selectedFeedbacks.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 4.0),
                    ElevatedButton(
                      onPressed: deleteFeedbacks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 5),
                          Text('Delete Feedbacks')
                        ],
                      ),
                    )
                  ],
                ),
              )
            : Container(),
        body: buildBody(),
      ),
    );
  }
}
