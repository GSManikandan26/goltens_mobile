import 'dart:io';
import 'package:flutter/material.dart';
import 'package:goltens_core/models/admin.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_mobile/components/admin/admin_drawer.dart';
import 'package:goltens_mobile/components/admin/group_detail.dart';
import 'package:goltens_mobile/components/search_bar_delegate.dart';
import 'package:goltens_core/components/admin/scrollable_data_table.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/services/admin.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class Groups extends StatefulWidget {
  const Groups({super.key});

  @override
  State<Groups> createState() => _GroupsState();
}

class _GroupsState extends State<Groups> {
  int currentPage = 1;
  int totalPages = 1;
  int limit = 50;
  bool isLoading = false;
  bool isError = false;
  String? search;
  List<GetGroupsResponseData> groups = [];
  CroppedFile? avatarPicture;

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

  Future<GetGroupResponseData?> fetchGroup(int id) async {
    if (isLoading) return null;

    setState(() {
      isLoading = true;
    });

    try {
      var res = await AdminService.getGroup(id: id);
      setState(() {
        isError = false;
        isLoading = false;
      });
      return res.data;
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      setState(() {
        isError = true;
        isLoading = false;
      });

      return null;
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

  Future<void> createGroup(CroppedFile? avatar, String name) async {
    try {
      await AdminService.createGroup(localFilePath: avatar?.path, name: name);
      await fetchGroups();

      if (mounted) {
        const snackBar = SnackBar(content: Text('Group Created'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      setState(() => avatarPicture = null);
    }
  }

  Future<void> updateGroup(
    int id,
    CroppedFile? avatar,
    String name, {
    bool deleteAvatar = false,
  }) async {
    try {
      await AdminService.updateGroup(
        id: id,
        localFilePath: avatar?.path,
        name: name,
        deleteAvatar: deleteAvatar,
      );

      await fetchGroups();

      if (mounted) {
        const snackBar = SnackBar(content: Text('Group Updated'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      setState(() => avatarPicture = null);
    }
  }

  Future<CroppedFile?> chooseAvatar() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null && mounted) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        maxHeight: 500,
        maxWidth: 500,
        cropStyle: CropStyle.circle,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Avatar',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Crop Avatar',
          ),
          WebUiSettings(
            context: context,
            presentStyle: CropperPresentStyle.dialog,
            boundary: const CroppieBoundary(
              width: 520,
              height: 520,
            ),
            viewPort: const CroppieViewPort(
              width: 480,
              height: 480,
              type: 'circle',
            ),
            enableExif: true,
            enableZoom: true,
            showZoomer: true,
          ),
        ],
      );

      if (croppedFile != null) {
        return croppedFile;
      }
    }

    return null;
  }

  void showGroupDialog({
    required String title,
    required bool isEditMode,
    required GetGroupsResponseData? group,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        var formKey = GlobalKey<FormState>();
        var nameTextController = TextEditingController(text: group?.name);

        final avatarUrl = group?.avatar?.isNotEmpty == true
            ? '$apiUrl/$groupsAvatar/${group?.avatar}'
            : null;

        void removeAvatar() {
          updateGroup(
            group?.id ?? 0,
            null,
            group?.name ?? '-',
            deleteAvatar: true,
          );

          Navigator.pop(context);
        }

        return AlertDialog(
          contentPadding: const EdgeInsets.all(25.0),
          title: Center(child: Text(title)),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
          ),
          content: StatefulBuilder(
            builder: (
              BuildContext context,
              StateSetter setState,
            ) {
              return SizedBox(
                height: 280,
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(60),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(60.0),
                          onTap: () async {
                            var avatar = await chooseAvatar();
                            setState(() => avatarPicture = avatar);
                          },
                          child: isEditMode
                              ? avatarPicture != null
                                  ? CircleAvatar(
                                      radius: 60.0,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                        child: Image.file(
                                          File(avatarPicture?.path ?? ''),
                                        ),
                                      ),
                                    )
                                  : Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        CircleAvatar(
                                          radius: 60.0,
                                          child: avatarUrl != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          100.0),
                                                  child: Image.network(
                                                    avatarUrl,
                                                    errorBuilder: (
                                                      context,
                                                      obj,
                                                      stacktrace,
                                                    ) {
                                                      return Container();
                                                    },
                                                  ),
                                                )
                                              : Text(
                                                  group?.name[0] ?? '-',
                                                  style: const TextStyle(
                                                    fontSize: 60.0,
                                                  ),
                                                ),
                                        ),
                                        avatarUrl != null
                                            ? Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Material(
                                                  type:
                                                      MaterialType.transparency,
                                                  child: Container(
                                                    width: 38,
                                                    height: 38,
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: IconButton(
                                                        icon: const Icon(
                                                          Icons.delete,
                                                        ),
                                                        iconSize: 24,
                                                        onPressed: removeAvatar,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(),
                                              ),
                                      ],
                                    )
                              : CircleAvatar(
                                  radius: 60.0,
                                  child: avatarPicture != null
                                      ? CircleAvatar(
                                          radius: 60.0,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(100.0),
                                            child: Image.file(
                                              File(avatarPicture?.path ?? ''),
                                            ),
                                          ),
                                        )
                                      : const Text('Select Avatar'),
                                ),
                        ),
                      ),
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

                            if (isEditMode) {
                              updateGroup(
                                group?.id ?? 0,
                                avatarPicture,
                                nameTextController.text,
                              );
                            } else {
                              createGroup(
                                avatarPicture,
                                nameTextController.text,
                              );
                            }
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.done),
                            const SizedBox(width: 5.0),
                            Text(isEditMode ? 'Update Group' : 'Create Group')
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

  Future<void> deleteGroup(GetGroupsResponseData group) async {
    try {
      var res = await AdminService.deleteGroup(groupId: group.id);

      if (mounted) {
        final snackBar = SnackBar(content: Text(res.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      await fetchGroups();
    }
  }

  void showDeleteGroupDialog(GetGroupsResponseData group) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Are you sure you want to delete this group ${group.name} ?",
          ),
          actions: [
            TextButton(
              child: const Text("CANCEL"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () async {
                await deleteGroup(group);

                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> openGroup(GetGroupsResponseData group) async {
    var groupDetail = await fetchGroup(group.id);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const GroupDetail(),
          settings: RouteSettings(
            arguments: groupDetail,
          ),
        ),
      );
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              ScrollableDataTable(
                child: DataTable(
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Avatar')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Members')),
                    DataColumn(label: Text('Created At')),
                    DataColumn(label: Text('Edit')),
                    DataColumn(label: Text('Delete')),
                    DataColumn(label: Text('View')),
                  ],
                  rows: groups.map((group) {
                    var createdAt = formatDateTime(
                      group.createdAt,
                      'HH:mm dd/MM/y',
                    );

                    return DataRow(
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
                          onTap: () => openGroup(group),
                        ),
                        DataCell(
                          Text(group.name),
                          onTap: () => openGroup(group),
                        ),
                        DataCell(
                          Text(group.members.length.toString()),
                          onTap: () => openGroup(group),
                        ),
                        DataCell(
                          Text(createdAt),
                          onTap: () => openGroup(group),
                        ),
                        DataCell(
                          IconButton(
                            onPressed: () => showGroupDialog(
                              title: 'Update Group',
                              isEditMode: true,
                              group: group,
                            ),
                            icon: const Icon(Icons.edit),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            onPressed: () => showDeleteGroupDialog(group),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            onPressed: () => openGroup(group),
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
            search?.isNotEmpty == true ? 'Results for "$search"' : 'Groups',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: startSearch,
            ),
            PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'create-group':
                    showGroupDialog(
                      title: 'Create Group',
                      isEditMode: false,
                      group: null,
                    );
                    break;
                  default:
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem(
                    value: 'create-group',
                    child: Text('Create Group'),
                  ),
                ];
              },
            )
          ],
        ),
        drawer: const AdminDrawer(currentIndex: 5),
        body: buildBody(),
      ),
    );
  }
}
