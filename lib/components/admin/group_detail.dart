import 'dart:io';

import 'package:flutter/material.dart';
import 'package:goltens_core/models/admin.dart';
import 'package:goltens_core/components/admin/scrollable_data_table.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/services/admin.dart';
import 'package:goltens_core/utils/csv_generator.dart';
import 'package:goltens_mobile/utils/functions.dart';

class GroupDetail extends StatefulWidget {
  const GroupDetail({super.key});

  @override
  State<GroupDetail> createState() => _GroupDetailState();
}

class _GroupDetailState extends State<GroupDetail> {
  GetGroupResponseData? group;
  List<int> selectedRows = [];
  List<int> selectedRowsToAdd = [];
  List<GetUsersResponseData> searchMembers = [];
  bool isLoading = false;
  bool isError = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = ModalRoute.of(context)!.settings;
      final group = settings.arguments as GetGroupResponseData?;
      fetchGroup(group?.id ?? 0);
    });
  }

  Future<void> fetchGroup(int id) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      var res = await AdminService.getGroup(id: id);
      setState(() {
        isError = false;
        isLoading = false;
        group = res.data;
      });
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      setState(() {
        isError = true;
        isLoading = false;
        group = null;
      });
    }
  }

  void makeSubAdminsAsMembers() async {
    final settings = ModalRoute.of(context)!.settings;
    final group = settings.arguments as GetGroupResponseData?;

    try {
      await AdminService.makeSubAdminsAsGroupMembers(
        groupId: group!.id,
        subAdminIds: selectedRows,
      );

      if (mounted) {
        const snackBar = SnackBar(content: Text('Members Updated'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      fetchGroup(group!.id);
      setState(() => selectedRows = []);
    }
  }

  void makeMembersAsSubAdmins() async {
    final settings = ModalRoute.of(context)!.settings;
    final group = settings.arguments as GetGroupResponseData?;

    try {
      await AdminService.makeGroupMembersAsSubAdmins(
        groupId: group!.id,
        memberIds: selectedRows,
      );

      if (mounted) {
        const snackBar = SnackBar(content: Text('Members Updated'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      fetchGroup(group!.id);
      setState(() => selectedRows = []);
    }
  }

  void deleteMembers() async {
    try {
      await AdminService.removeGroupMembers(
        groupId: group!.id,
        memberIds: selectedRows,
      );

      if (mounted) {
        const snackBar = SnackBar(content: Text('Members Deleted'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      fetchGroup(group!.id);
      setState(() => selectedRows = []);
    }
  }

  Future<GetUsersResponse?> searchUsersNotInGroup(
    String search,
  ) async {
    try {
      var res = await AdminService.searchUsersNotInGroup(
        groupId: group!.id,
        searchTerm: search,
      );

      return res;
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
      return null;
    }
  }

  Future<void> exportCsvFile() async {
    String csvData = CSVGenerator.generateGroupMembersList(
      group?.name ?? '',
      group?.members ?? [],
    );

    final directory = await getDownloadsDirectoryPath();
    File file = File('$directory/${group?.name}-members-list.csv');
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

  void addMember() {
    setState(() => selectedRows = []);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.only(left: 25, right: 25),
          title: const Center(child: Text("Add Members")),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
          ),
          content: StatefulBuilder(
            builder: (
              BuildContext context,
              StateSetter setState,
            ) {
              var searchTextController = TextEditingController();

              return SizedBox(
                height: 400,
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: searchTextController,
                        decoration: InputDecoration(
                          labelText: 'Search...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () async {
                              if (searchTextController.text.isEmpty) {
                                const snackBar = SnackBar(
                                  content: Text(
                                    'Enter something to search for...,',
                                  ),
                                );

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    snackBar,
                                  );
                                }

                                return;
                              }

                              var users = await searchUsersNotInGroup(
                                searchTextController.text,
                              );

                              if (users != null) {
                                setState(() {
                                  selectedRowsToAdd = [];
                                  searchMembers = users.data;
                                });
                              }
                            },
                            icon: const Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      searchMembers.isNotEmpty
                          ? SizedBox(
                              height: 200,
                              child: ScrollableDataTable(
                                child: DataTable(
                                  showCheckboxColumn: true,
                                  columns: const <DataColumn>[
                                    DataColumn(label: Text('Avatar')),
                                    DataColumn(label: Text('Name')),
                                    DataColumn(label: Text('Email')),
                                    DataColumn(label: Text('Phone')),
                                    DataColumn(label: Text('Department')),
                                    DataColumn(label: Text('Employee Number')),
                                    DataColumn(label: Text('Type')),
                                  ],
                                  rows: searchMembers
                                      .map(
                                        (user) => DataRow(
                                          cells: <DataCell>[
                                            DataCell(
                                              CircleAvatar(
                                                radius: 16,
                                                child: user.avatar
                                                            ?.isNotEmpty ==
                                                        true
                                                    ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          100.0,
                                                        ),
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
                                          ],
                                          selected: selectedRowsToAdd.contains(
                                            user.id,
                                          ),
                                          onSelectChanged: (isItemSelected) {
                                            setState(() {
                                              if (isItemSelected == true) {
                                                selectedRowsToAdd.add(user.id);
                                              } else {
                                                selectedRowsToAdd
                                                    .remove(user.id);
                                              }
                                            });
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            )
                          : Container(),
                      const SizedBox(height: 15.0),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        onPressed: searchMembers.isNotEmpty
                            ? () {
                                Navigator.pop(context);
                                addMembersToGroup();
                              }
                            : null,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_add),
                            SizedBox(width: 5.0),
                            Text('Add Members')
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

  void addMembersToGroup() async {
    try {
      await AdminService.addGroupMembers(
        groupId: group!.id,
        memberIds: selectedRowsToAdd,
      );

      if (mounted) {
        const snackBar = SnackBar(content: Text('Members Added'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      fetchGroup(group!.id);

      setState(() {
        selectedRows = [];
        searchMembers = [];
      });
    }
  }

  Widget buildBody() {
    if (group?.members.isEmpty == true) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'No Group Members Available',
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => fetchGroup(group?.id ?? 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: isLoading
                ? [const CircularProgressIndicator()]
                : [
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 1.8,
                      child: ScrollableDataTable(
                        child: DataTable(
                          showCheckboxColumn: true,
                          columns: const <DataColumn>[
                            DataColumn(label: Text('Avatar')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Phone')),
                            DataColumn(label: Text('Department')),
                            DataColumn(label: Text('Employee Number')),
                            DataColumn(label: Text('Type')),
                          ],
                          rows: group?.members
                                  .map(
                                    (user) => DataRow(
                                      cells: <DataCell>[
                                        DataCell(
                                          CircleAvatar(
                                            radius: 16,
                                            child: user.avatar?.isNotEmpty ==
                                                    true
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      100.0,
                                                    ),
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
                                      ],
                                      selected: selectedRows.contains(user.id),
                                      onSelectChanged: (isItemSelected) {
                                        setState(() {
                                          if (isItemSelected == true) {
                                            selectedRows.add(user.id);
                                          } else {
                                            selectedRows.remove(user.id);
                                          }
                                        });
                                      },
                                    ),
                                  )
                                  .toList() ??
                              [],
                        ),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group?.name ?? 'Loading...'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'add-members':
                  addMember();
                  break;
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
                const PopupMenuItem(
                  value: 'add-members',
                  child: Text('Add Members'),
                ),
              ];
            },
          )
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: selectedRows.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      onPressed: makeSubAdminsAsMembers,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.manage_accounts),
                          SizedBox(width: 5),
                          Text('Make Members')
                        ],
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      onPressed: makeMembersAsSubAdmins,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.manage_accounts),
                          SizedBox(width: 5),
                          Text('Make SubAdmin')
                        ],
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    ElevatedButton(
                      onPressed: deleteMembers,
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
                          Text('Remove Members')
                        ],
                      ),
                    )
                  ]),
            )
          : Container(),
      body: buildBody(),
    );
  }
}
