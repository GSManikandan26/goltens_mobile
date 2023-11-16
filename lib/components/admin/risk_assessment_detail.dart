import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goltens_core/models/risk_assessment.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_mobile/components/admin/admin_drawer.dart';
import 'package:goltens_mobile/components/search_bar_delegate.dart';
import 'package:goltens_core/components/admin/scrollable_data_table.dart';
import 'package:goltens_core/models/admin.dart';
import 'package:goltens_mobile/pages/others/file_viewer_page.dart';
import 'package:goltens_core/services/admin.dart';
import 'package:goltens_mobile/utils/functions.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/services/risk_assessment.dart';

class RiskAssessmentDetail extends StatefulWidget {
  const RiskAssessmentDetail({super.key});

  @override
  State<RiskAssessmentDetail> createState() => _RiskAssessmentDetailState();
}

class _RiskAssessmentDetailState extends State<RiskAssessmentDetail> {
  int currentPage = 1;
  int totalPages = 1;
  int limit = 50;
  String? search;
  bool isLoading = false;
  bool isError = false;
  List<GetAssessmentsResponseData> data = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      fetchAssessments();
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

      fetchAssessments();
    }
  }

  Future<void> fetchAssessments() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final settings = ModalRoute.of(context)!.settings;
    final groupDetail = settings.arguments as GetGroupsResponseData;

    try {
      var res = await RiskAssessmentService.getRiskAssessmentItems(
        currentPage,
        limit,
        groupDetail.id,
        search,
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

  Future<void> uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      try {
        setState(() {
          isLoading = true;
        });

        if (mounted) {
          final settings = ModalRoute.of(context)!.settings;
          final groupDetail = settings.arguments as GetGroupsResponseData;

          await AdminService.uploadRiskAssesment(
            localFilePath: File(result.paths[0] ?? '').path,
            groupId: groupDetail.id,
          );
        }

        setState(() {
          isLoading = false;
        });

        await fetchAssessments();
      } catch (e) {
        if (mounted) {
          final snackBar = SnackBar(content: Text(e.toString()));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);

          setState(() {
            isLoading = false;
            isError = true;
          });
        }
      }
    }
  }

  void nextPage() {
    if (currentPage < totalPages) {
      setState(() => currentPage++);
      fetchAssessments();
    }
  }

  void prevPage() {
    if (currentPage > 1) {
      setState(() => currentPage--);
      fetchAssessments();
    }
  }

  Future<void> updateRiskAssesment(
    int id,
    String name,
  ) async {
    try {
      await AdminService.updateRiskAssesment(id: id, name: name);
      await fetchAssessments();

      if (mounted) {
        const snackBar = SnackBar(content: Text('Updated Successfully'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void showEditRiskAssesmentDialog(
    GetAssessmentsResponseData assessment,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(25.0),
          title: const Center(child: Text("Edit Risk Assessment")),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
          ),
          content: StatefulBuilder(
            builder: (
              BuildContext context,
              StateSetter setState,
            ) {
              var formKey = GlobalKey<FormState>();

              var nameTextController = TextEditingController(
                text: assessment.name.replaceAll(".pdf", ""),
              );

              return SizedBox(
                height: 150,
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 16.0),
                      Form(
                        key: formKey,
                        child: TextFormField(
                          controller: nameTextController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isEmpty) {
                              return 'Please enter a name';
                            }

                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 28.0),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        onPressed: () {
                          if (formKey.currentState?.validate() == true) {
                            formKey.currentState?.save();
                            Navigator.pop(context);
                            updateRiskAssesment(
                              assessment.id,
                              nameTextController.text,
                            );
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.done),
                            SizedBox(width: 5.0),
                            Text('Update Risk Assessment')
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> deleteRiskAssesment(int id) async {
    try {
      await AdminService.deleteRiskAssesment(id: id);
      await fetchAssessments();

      if (mounted) {
        const snackBar = SnackBar(content: Text('Deleted'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
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
                'No Risk Assessments Available',
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchAssessments,
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
                    columns: const <DataColumn>[
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Created At')),
                      DataColumn(label: Text('File Link')),
                      DataColumn(label: Text('Edit')),
                      DataColumn(label: Text('Delete')),
                    ],
                    rows: data.map(
                      (item) {
                        var time = formatDateTime(
                          item.createdAt,
                          'HH:mm dd/MM/y',
                        );

                        var url = Uri.parse(
                          '$apiUrl/$riskAssessmentDir/${item.name}',
                        );

                        return DataRow(
                          cells: <DataCell>[
                            DataCell(Text(item.name)),
                            DataCell(Text(time)),
                            DataCell(
                              onLongPress: () {
                                const snackBar = SnackBar(
                                  content: Text('Link Copied'),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  snackBar,
                                );

                                Clipboard.setData(
                                  ClipboardData(text: url.toString()),
                                );
                              },
                              Text(
                                url.toString(),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              onTap: () async {
                                var file = await fetchPdf(url.toString());

                                if (file != null) {
                                  if (mounted) {
                                    Navigator.pushNamed(
                                      context,
                                      '/file-viewer',
                                      arguments: FileViewerPageArgs(
                                        file: file,
                                        url: url.toString(),
                                        fileType: FileType.any,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            DataCell(
                              IconButton(
                                onPressed: () => showEditRiskAssesmentDialog(
                                  item,
                                ),
                                icon: const Icon(Icons.edit),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                onPressed: () => deleteRiskAssesment(item.id),
                                color: Colors.redAccent,
                                icon: const Icon(Icons.delete),
                              ),
                            ),
                          ],
                        );
                      },
                    ).toList(),
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
    final settings = ModalRoute.of(context)!.settings;
    final groupDetail = settings.arguments as GetGroupsResponseData;

    return WillPopScope(
      onWillPop: () async {
        if (search?.isNotEmpty == true) {
          setState(() {
            search = null;
            currentPage = 1;
          });

          await fetchAssessments();
          return false;
        }

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            search?.isNotEmpty == true
                ? 'Results for "$search"'
                : '${groupDetail.name} - Assessments',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: startSearch,
            ),
            PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'upload-file':
                    uploadFile();
                    break;
                  default:
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem(
                    value: 'upload-file',
                    child: Text('Upload'),
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
