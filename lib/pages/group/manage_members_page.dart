import 'package:flutter/material.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/models/auth.dart';
import 'package:goltens_core/models/group.dart';
import 'package:goltens_mobile/provider/global_state.dart';
import 'package:goltens_core/services/group.dart';
import 'package:provider/provider.dart';

class ManageMembersPage extends StatefulWidget {
  const ManageMembersPage({super.key});

  @override
  State<ManageMembersPage> createState() => _ManageMembersPageState();
}

class _ManageMembersPageState extends State<ManageMembersPage> {
  List<GetMembersResponseData> members = [];
  List<GetMembersResponseData> searchMembers = [];
  bool isLoading = false;
  bool hasMoreData = true;
  bool hasError = true;

  Future<void> addMember(
    GetMembersResponseData member,
  ) async {
    try {
      final settings = ModalRoute.of(context)!.settings;
      final group = settings.arguments as GetAllGroupsResponseData;
      await GroupService.addMember(group.id, member.id);
      await fetchMembers();

      if (mounted) {
        final snackBar = SnackBar(content: Text('${member.name} Added'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> removeMember(
    GetMembersResponseData member,
  ) async {
    try {
      final settings = ModalRoute.of(context)!.settings;
      final group = settings.arguments as GetAllGroupsResponseData;
      await GroupService.removeMember(group.id, member.id);
      await fetchMembers();

      if (mounted) {
        final snackBar = SnackBar(content: Text('${member.name} Removed'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<GetMembersResponse?> searchUsersNotInGroup(
    String search,
  ) async {
    try {
      final settings = ModalRoute.of(context)!.settings;
      final group = settings.arguments as GetAllGroupsResponseData;

      var res = await GroupService.searchUsersToAdd(
        group.id,
        search,
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

  void showRemoveMemberDialog(
    GetMembersResponseData member,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Do you want to remove ${member.name} from this group",
          ),
          actions: [
            TextButton(
              child: const Text("CANCEL"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                removeMember(member);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                height: 350,
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 16.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextFormField(
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

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    snackBar,
                                  );

                                  return;
                                }

                                var users = await searchUsersNotInGroup(
                                  searchTextController.text,
                                );

                                if (users != null) {
                                  setState(() {
                                    searchMembers = users.data;
                                  });
                                }
                              },
                              icon: const Icon(Icons.search),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      searchMembers.isNotEmpty
                          ? SizedBox(
                              height: 200,
                              child: ListView.builder(
                                itemCount: searchMembers.length,
                                itemBuilder: (
                                  BuildContext context,
                                  int index,
                                ) {
                                  var member = searchMembers[index];

                                  return ListTile(
                                    title: Text(member.name),
                                    leading: CircleAvatar(
                                      child: member.avatar.isNotEmpty == true
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(100.0),
                                              child: Image.network(
                                                '$apiUrl/$avatar/${member.avatar}',
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
                                          : Text(member.name[0]),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.add_circle),
                                      onPressed: () {
                                        addMember(member);
                                        searchMembers.removeWhere(
                                          (el) => el.id == member.id,
                                        );
                                        setState(() {});
                                      },
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(),
                      const SizedBox(height: 10.0),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            searchMembers = [];
                          });

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        icon: const Icon(Icons.done),
                        label: const Text('Done'),
                      )
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        fetchMembers();
      }
    });
  }

  Future<void> fetchMembers() async {
    if (isLoading || !hasMoreData) {
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final settings = ModalRoute.of(context)!.settings;
      final group = settings.arguments as GetAllGroupsResponseData;
      var response = await GroupService.getMembers(group.id);

      setState(() {
        members = response.data;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Widget buildMembersList() {
    final user = context.read<GlobalState>().user;

    if (isLoading && members.isEmpty) {
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
              onPressed: fetchMembers,
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

    return RefreshIndicator(
      onRefresh: fetchMembers,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: members.length,
        itemBuilder: (BuildContext context, int index) {
          GetMembersResponseData member = members[index];
          bool isCurrentUser = user?.data.id == member.id;

          if (isCurrentUser) {
            return ListTile(
              title: Text("${member.name} ${isCurrentUser ? '(You)' : ''}"),
              leading: CircleAvatar(
                child: member.avatar.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(100.0),
                        child: Image.network(
                          '$apiUrl/$avatar/${member.avatar}',
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
                    : Text(member.name[0]),
              ),
            );
          }

          return ListTile(
            title: Text(member.name),
            leading: CircleAvatar(
              child: member.avatar.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(100.0),
                      child: Image.network(
                        '$apiUrl/$avatar/${member.avatar}',
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
                  : Text(member.name[0]),
            ),
            trailing: member.type != UserType.subAdmin
                ? IconButton(
                    icon: const Icon(Icons.remove_circle),
                    onPressed: () => showRemoveMemberDialog(member),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget buildLoader() {
    if (!hasMoreData) {
      return Container();
    }

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

  @override
  Widget build(BuildContext context) {
    final settings = ModalRoute.of(context)!.settings;
    final group = settings.arguments as GetAllGroupsResponseData;

    return Scaffold(
      appBar: AppBar(
        title: Text('${group.name} Members'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'add-member':
                  showAddMemberDialog();
                  break;
                default:
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'add-member',
                  child: Text('Add Member'),
                ),
              ];
            },
          )
        ],
      ),
      body: buildMembersList(),
    );
  }
}
