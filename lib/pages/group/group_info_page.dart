import 'package:flutter/material.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/models/auth.dart';
import 'package:goltens_core/models/group.dart';
import 'package:goltens_mobile/provider/global_state.dart';
import 'package:goltens_core/services/admin.dart';
import 'package:goltens_core/services/group.dart';
import 'package:provider/provider.dart';

class GroupInfoPage extends StatefulWidget {
  const GroupInfoPage({super.key});

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  List<GetMembersResponseData> members = [];
  List<GetMembersResponseData> searchMembers = [];
  bool isLoading = false;
  bool hasMoreData = true;
  bool hasError = true;

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

  Future<void> deleteGroup() async {
    try {
      final settings = ModalRoute.of(context)!.settings;
      final group = settings.arguments as GetAllGroupsResponseData;
      var res = await AdminService.deleteGroup(groupId: group.id);

      if (mounted) {
        final snackBar = SnackBar(content: Text(res.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
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
        itemCount: members.length + 1,
        itemBuilder: (BuildContext context, int index) {
          // Delete Button
          if (index == members.length) {
            if (user?.data.type == UserType.admin) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  onPressed: deleteGroup,
                ),
              );
            } else {
              return Container();
            }
          }

          GetMembersResponseData member = members[index];
          bool isCurrentUser = user?.data.id == member.id;

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
        title: Text('${group.name} Info'),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 60.0,
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
                          : Text(
                              group.name[0],
                              style: const TextStyle(
                                fontSize: 60.0,
                              ),
                            ),
                    ),
                    const SizedBox(height: 15.0),
                    Text(
                      group.name,
                      style: const TextStyle(fontSize: 28.0),
                    ),
                    const SizedBox(height: 15.0),
                    const Divider(),
                    const SizedBox(height: 15.0),
                    const Text(
                      'Members',
                      style: TextStyle(fontSize: 18.0),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            )
          ];
        },
        body: buildMembersList(),
      ),
    );
  }
}
