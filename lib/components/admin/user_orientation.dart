import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goltens_core/models/user_orientation.dart';
import 'package:goltens_core/services/user_orientation.dart';
import 'package:goltens_core/utils/csv_generator.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_core/utils/pdf_generator.dart';
import 'package:goltens_mobile/components/admin/admin_drawer.dart';
import 'package:goltens_core/components/admin/scrollable_data_table.dart';
import 'package:goltens_mobile/pages/others/file_viewer_page.dart';
import 'package:goltens_core/services/admin.dart';
import 'package:goltens_mobile/utils/functions.dart';
import 'package:goltens_mobile/components/search_bar_delegate.dart';
import 'package:goltens_core/constants/constants.dart';

class UserOrientation extends StatefulWidget {
  const UserOrientation({super.key});

  @override
  State<UserOrientation> createState() => _UserOrientationState();
}

class _UserOrientationState extends State<UserOrientation> {
  int currentPage = 1;
  int totalPages = 1;
  int limit = 50;
  String? search;
  bool isLoading = false;
  bool isError = false;
  ScrollController scrollController = ScrollController();
  List<GetUserOrientationItemsData> data = [];
  GetUserOrientationItemsData? selectedUserOrientationItem;
  List<UserOrientationRead> userOrientationReads = [];
  int userOrientationPage = 1;
  int userOrientationTotalPages = 1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      scrollController.addListener(scrollListener);
      fetchUserOrientationItems();
    });
  }

  void scrollListener() {
    bool outOfRange = scrollController.position.outOfRange;
    double offset = scrollController.offset;

    if (offset >= scrollController.position.maxScrollExtent && outOfRange) {
      fetchUserOrientationInfo();
    }
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

      fetchUserOrientationItems();
    }
  }

  Future<void> fetchUserOrientationItems() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      currentPage = 1;
    });

    try {
      var res = await UserOrientationService.getAllUserOrientationItems(
        currentPage,
        limit,
        search,
      );

      setState(() {
        data = res.data;
        isError = false;
        isLoading = false;
        totalPages = res.totalPages;
        currentPage++;
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

        await AdminService.uploadUserOrientationItem(
          localFilePath: File(result.paths[0] ?? '').path,
        );

        setState(() {
          isLoading = false;
        });

        await fetchUserOrientationItems();
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
      fetchUserOrientationItems();
    }
  }

  void prevPage() {
    if (currentPage > 1) {
      setState(() => currentPage--);
      fetchUserOrientationItems();
    }
  }

  Future<void> updateUserOrientationItem(
    int id,
    String name,
  ) async {
    try {
      await AdminService.updateUserOrientationItem(id: id, name: name);
      await fetchUserOrientationItems();

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

  void showEditUserOrientationItemDialog(
    GetUserOrientationItemsData userOrientation,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(25.0),
          title: const Center(child: Text("Edit User Orientation")),
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
                text: userOrientation.name.replaceAll(".pdf", ""),
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
                            updateUserOrientationItem(
                              userOrientation.id,
                              nameTextController.text,
                            );
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.done),
                            SizedBox(width: 5.0),
                            Text('Update User Orientation Item')
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

  Future<void> deleteUserOrientationItem(int id) async {
    try {
      await AdminService.deleteUserOrientationItem(id: id);
      await fetchUserOrientationItems();

      if (mounted) {
        const snackBar = SnackBar(content: Text('Deleted Successfully'));
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

  Future<void> exportPdfFile() async {
    final ByteData image = await rootBundle.load('assets/images/logo.png');
    Uint8List logoImage = (image).buffer.asUint8List();

    final directory = await getDownloadsDirectoryPath();
    Uint8List pdfInBytes = await PDFGenerator.generateUserOrientationReadInfo(
      selectedUserOrientationItem?.id ?? 0,
      selectedUserOrientationItem?.name ?? '',
      selectedUserOrientationItem?.createdAt ?? DateTime.now(),
      logoImage,
      userOrientationReads,
    );

    File file = File(
      '$directory/user-orientation-info-${selectedUserOrientationItem?.id}.pdf',
    );

    file.writeAsBytes(pdfInBytes);

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

  Future<void> exportCsvFile() async {
    final directory = await getDownloadsDirectoryPath();

    String csvData = CSVGenerator.generateUserOrientationReadInfo(
      userOrientationReads,
    );

    File file = File(
      '$directory/user-orientation-info-${selectedUserOrientationItem?.id}.csv',
    );

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

  Widget buildLoader() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Widget buildStatusList() {
    if (isLoading && userOrientationReads.isEmpty) {
      return buildLoader();
    }

    if (isError) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
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
              onPressed: fetchUserOrientationItems,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
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

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: scrollController,
      itemCount: userOrientationReads.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index != userOrientationReads.length) {
          UserOrientationRead readObject = userOrientationReads[index];
          var time = formatDateTime(readObject.readAt, 'HH:mm dd/MM/y');

          return ListTile(
            title: Text(readObject.user.name),
            leading: CircleAvatar(
              radius: 12,
              child: readObject.user.avatar.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(100.0),
                      child: Image.network(
                        '$apiUrl/$avatar/${readObject.user.avatar}',
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
                  : Text(readObject.user.name[0]),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [Text(time)],
            ),
          );
        }

        return null;
      },
    );
  }

  Future<void> fetchUserOrientationInfo() async {
    if (isLoading) {
      return;
    }

    setState(() {
      isLoading = true;
      isError = false;
      userOrientationPage = 1;
    });

    try {
      var response = await AdminService.getUserOrientationItem(
        id: selectedUserOrientationItem?.id ?? 0,
        page: userOrientationPage,
        limit: limit,
      );

      setState(() {
        userOrientationReads = response.data.userOrientationReads;
        userOrientationTotalPages = response.totalPages;
        isLoading = false;
        userOrientationPage++;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  void showUserOrientationItemInfoDialog(
    GetUserOrientationItemsData userOrientation,
  ) async {
    selectedUserOrientationItem = userOrientation;
    await fetchUserOrientationInfo();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'User Orientation Info of "${userOrientation.name} - ${userOrientation.id}"',
          ),
          content: StatefulBuilder(
            builder: (
              BuildContext context,
              StateSetter setState,
            ) {
              return SizedBox(
                height: 380,
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Expanded(
                      child: buildStatusList(),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: TextButton(
                onPressed: exportPdfFile,
                child: const Text('EXPORT PDF'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: TextButton(
                onPressed: exportCsvFile,
                child: const Text('EXPORT CSV'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        );
      },
    );
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
                'No User Orientation Files Available',
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchUserOrientationItems,
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
                      DataColumn(label: Text('Info')),
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
                          '$apiUrl/$userOrientationDir/${item.name}',
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
                              SizedBox(
                                width: 150,
                                child: Text(
                                  url.toString(),
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                                onPressed: () =>
                                    showUserOrientationItemInfoDialog(
                                  item,
                                ),
                                icon: const Icon(Icons.info),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                onPressed: () =>
                                    showEditUserOrientationItemDialog(
                                  item,
                                ),
                                icon: const Icon(Icons.edit),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                onPressed: () =>
                                    deleteUserOrientationItem(item.id),
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
    return WillPopScope(
      onWillPop: () async {
        if (search?.isNotEmpty == true) {
          setState(() {
            search = null;
            currentPage = 1;
          });

          await fetchUserOrientationItems();
          return false;
        }

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            search?.isNotEmpty == true
                ? 'Results for "$search"'
                : 'User Orientation',
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
        drawer: const AdminDrawer(currentIndex: 10),
        body: buildBody(),
      ),
    );
  }
}
