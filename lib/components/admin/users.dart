import 'dart:io';
import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:goltens_core/components/admin/scrollable_data_table.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/models/admin.dart';
import 'package:goltens_core/services/admin.dart';
import 'package:goltens_mobile/components/admin/admin_drawer.dart';
import 'package:goltens_mobile/components/search_bar_delegate.dart';

class Users extends StatefulWidget {
  const Users({super.key});

  @override
  State<Users> createState() => _UsersState();
}

class _UsersState extends State<Users> {
  int currentPage = 1;
  int totalPages = 1;
  int limit = 50;
  bool isLoading = false;
  bool isError = false;
  String? search;
  List<GetUsersResponseData> users = [];
  List<int> selectedUsers = [];
  CroppedFile? avatarPicture;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      fetchUsers();
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

      fetchUsers();
    }
  }

  Future<void> fetchUsers() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      var res = await AdminService.getUsers(
        page: currentPage,
        limit: limit,
        search: search,
      );

      setState(() {
        users = res.data;
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

  void nextPage() {
    if (currentPage < totalPages) {
      setState(() => currentPage++);
      fetchUsers();
    }
  }

  void prevPage() {
    if (currentPage > 1) {
      setState(() => currentPage--);
      fetchUsers();
    }
  }

  void deleteUsers() async {
    try {
      await AdminService.deleteUsers(userIds: selectedUsers);

      if (mounted) {
        const snackBar = SnackBar(content: Text('Users Deleted'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      await fetchUsers();
      setState(() => selectedUsers = []);
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

  void makeUsersAsUserAndSubAdmins() async {
    try {
      await AdminService.makeUsersAsUserAndSubAdmins(
        userIds: selectedUsers,
      );

      if (mounted) {
        const snackBar = SnackBar(
          content: Text(
            'Users are now User & SubAdmins!',
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      fetchUsers();
      setState(() => selectedUsers = []);
    }
  }

  void makeUsersAsSubAdmins() async {
    try {
      await AdminService.makeUsersAsSubAdmins(
        userIds: selectedUsers,
      );

      if (mounted) {
        const snackBar = SnackBar(content: Text('Users are now SubAdmin!'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      fetchUsers();
      setState(() => selectedUsers = []);
    }
  }

  Future<void> createUser(
    String name,
    String email,
    String password,
    String phone,
    String department,
    String employeeNumber,
    CroppedFile? avatar,
  ) async {
    try {
      await AdminService.createUser(
        name: name,
        email: email,
        password: password,
        phone: phone,
        department: department,
        employeeNumber: employeeNumber,
        localFilePath: avatar?.path,
        type: UserType.user,
      );

      await fetchUsers();

      if (mounted) {
        const snackBar = SnackBar(content: Text('User Created'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      avatarPicture = null;
    }
  }

  Future<void> updateUser(
    int id,
    String name,
    String email,
    String? password,
    String phone,
    String department,
    String employeeNumber,
    bool active,
    CroppedFile? avatar, {
    bool deleteAvatar = false,
  }) async {
    try {
      await AdminService.updateUser(
        id: id,
        localFilePath: avatar?.path,
        name: name,
        email: email,
        password: password,
        phone: phone,
        department: department,
        employeeNumber: employeeNumber,
        active: active,
        deleteAvatar: deleteAvatar,
      );

      await fetchUsers();

      if (mounted) {
        const snackBar = SnackBar(content: Text('User Updated'));
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

  void showUserDialog({
    required String title,
    required bool showPassword,
    required bool isEditMode,
    required GetUsersResponseData? user,
  }) {
    TextEditingController nameTextController = TextEditingController(
      text: user?.name,
    );

    TextEditingController emailTextController = TextEditingController(
      text: user?.email,
    );

    TextEditingController passwordTextController = TextEditingController(
      text: '',
    );

    TextEditingController phoneTextController = TextEditingController(
      text: user?.phone,
    );

    SingleValueDropDownController departmentController =
        SingleValueDropDownController(
      data: DropDownValueModel(
        name: user?.department ?? '',
        value: user?.department,
      ),
    );

    TextEditingController employeeNumberTextController = TextEditingController(
      text: user?.employeeNumber,
    );

    int? selectedActiveIndex = user?.active == true ? 0 : 1;
    bool showPasswordText = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.only(left: 25, right: 25),
          title: Center(child: Text(title)),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
          ),
          content: StatefulBuilder(
            builder: (
              BuildContext context,
              StateSetter setState,
            ) {
              final formKey = GlobalKey<FormState>();

              final avatarUrl = user?.avatar?.isNotEmpty == true
                  ? '$apiUrl/$avatar/${user?.avatar}'
                  : null;

              void removeAvatar() {
                updateUser(
                  user?.id ?? 0,
                  user?.name ?? '',
                  user?.email ?? '',
                  null,
                  user?.phone ?? '',
                  user?.department ?? '',
                  user?.employeeNumber ?? '',
                  user?.active ?? true,
                  null,
                  deleteAvatar: true,
                );

                Navigator.pop(context);
              }

              return SizedBox(
                height: isEditMode ? 450 : 550,
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 16.0),
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
                                                    100.0,
                                                  ),
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
                                                  user?.name[0] ?? '-',
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
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                              controller: nameTextController,
                              validator: (value) {
                                if (value != null && value.isEmpty) {
                                  return 'Please enter name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                              controller: emailTextController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value != null && value.isEmpty) {
                                  return 'Please enter email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            showPassword
                                ? TextFormField(
                                    decoration: InputDecoration(
                                      labelText: isEditMode
                                          ? 'New Password'
                                          : 'Password',
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          !showPasswordText
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                        onPressed: () => setState(
                                          () => showPasswordText =
                                              !showPasswordText,
                                        ),
                                      ),
                                    ),
                                    controller: passwordTextController,
                                    obscureText: !showPasswordText,
                                    validator: (value) {
                                      if (isEditMode &&
                                          value?.isEmpty == true) {
                                        return null;
                                      }

                                      if (value != null && value.isEmpty) {
                                        return 'Please enter password';
                                      }

                                      if (value != null && value.length < 6) {
                                        return 'Password must be atleast 6 characters long';
                                      }

                                      return null;
                                    },
                                  )
                                : Container(),
                            showPassword
                                ? const SizedBox(height: 16.0)
                                : Container(),
                            IntlPhoneField(
                              decoration: InputDecoration(
                                labelText: 'Phone',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                              initialValue: phoneTextController.text,
                              onChanged: (phone) {
                                phoneTextController.text = phone.completeNumber;
                              },
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value != null &&
                                    value.completeNumber.isEmpty) {
                                  return 'Please enter your phone number';
                                }

                                try {
                                  value?.isValidNumber();
                                  return null;
                                } on Exception {
                                  return 'Invalid Number';
                                }
                              },
                            ),
                            const SizedBox(height: 16.0),
                            DropDownTextField(
                              clearOption: false,
                              controller: departmentController,
                              validator: (value) {
                                if (value != null && value.isEmpty) {
                                  return 'Please select your department';
                                }
                                return null;
                              },
                              textFieldDecoration: InputDecoration(
                                labelText: 'Department',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                              dropDownItemCount: departmentList.length,
                              dropDownList: departmentList.map((department) {
                                return DropDownValueModel(
                                  name: department,
                                  value: department,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: employeeNumberTextController,
                              decoration: InputDecoration(
                                labelText: 'Employee Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                              validator: (value) {
                                if (value != null && value.isEmpty) {
                                  return 'Please enter employee number';
                                }

                                return null;
                              },
                            ),
                            Visibility(
                              visible: isEditMode,
                              child: Column(
                                children: [
                                  const SizedBox(height: 16.0),
                                  Row(
                                    children: [
                                      Radio<int>(
                                        value: 0,
                                        groupValue: selectedActiveIndex,
                                        onChanged: (val) {
                                          setState(
                                              () => selectedActiveIndex = val);
                                        },
                                      ),
                                      const Text('Active'),
                                      Radio<int>(
                                        value: 1,
                                        groupValue: selectedActiveIndex,
                                        onChanged: (val) {
                                          setState(
                                              () => selectedActiveIndex = val);
                                        },
                                      ),
                                      const Text('InActive'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState?.validate() == true) {
                            formKey.currentState?.save();
                            Navigator.pop(context);

                            if (isEditMode) {
                              updateUser(
                                user?.id ?? 0,
                                nameTextController.text,
                                emailTextController.text,
                                passwordTextController.text,
                                phoneTextController.text,
                                departmentController.dropDownValue?.value,
                                employeeNumberTextController.text,
                                selectedActiveIndex == 0 ? true : false,
                                avatarPicture,
                              );
                            } else {
                              createUser(
                                nameTextController.text,
                                emailTextController.text,
                                passwordTextController.text,
                                phoneTextController.text,
                                departmentController.dropDownValue?.value,
                                employeeNumberTextController.text,
                                avatarPicture,
                              );
                            }
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.done),
                            const SizedBox(width: 5.0),
                            Text(isEditMode ? 'Update User' : 'Create User'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'No Users Available',
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchUsers,
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
                    DataColumn(label: Text('Avatar')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Department')),
                    DataColumn(label: Text('Employee Number')),
                    DataColumn(label: Text('Admin Approved')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Active')),
                    DataColumn(label: Text('Edit')),
                  ],
                  rows: users.map((user) {
                    final avatarUrl = user.avatar?.isNotEmpty == true
                        ? '$apiUrl/$avatar/${user.avatar}'
                        : null;

                    return DataRow(
                      cells: <DataCell>[
                        DataCell(
                          CircleAvatar(
                            radius: 16,
                            child: avatarUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(100.0),
                                    child: Image.network(
                                      avatarUrl,
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
                        DataCell(Text(user.adminApproved.name)),
                        DataCell(Text(user.type.name)),
                        DataCell(Text(user.active ? 'Yes' : 'No')),
                        DataCell(
                          IconButton(
                            onPressed: () => showUserDialog(
                              title: 'Update User',
                              isEditMode: true,
                              showPassword: true,
                              user: user,
                            ),
                            icon: const Icon(Icons.edit),
                          ),
                        ),
                      ],
                      selected: selectedUsers.contains(user.id),
                      onSelectChanged: (isItemSelected) {
                        setState(() {
                          if (isItemSelected == true) {
                            selectedUsers.add(user.id);
                          } else {
                            selectedUsers.remove(user.id);
                          }
                        });
                      },
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

          await fetchUsers();
          return false;
        }

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            search?.isNotEmpty == true ? 'Results for "$search"' : 'Users',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: startSearch,
            ),
            PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'create-user':
                    showUserDialog(
                      title: 'Create User',
                      isEditMode: false,
                      showPassword: true,
                      user: null,
                    );
                    break;
                  default:
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem(
                    value: 'create-user',
                    child: Text('Create User'),
                  ),
                ];
              },
            )
          ],
        ),
        drawer: const AdminDrawer(currentIndex: 2),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: selectedUsers.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 4.0),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      onPressed: makeUsersAsUserAndSubAdmins,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.manage_accounts),
                          SizedBox(width: 5),
                          Text('Make Both User & SubAdmin')
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
                      onPressed: makeUsersAsSubAdmins,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.manage_accounts),
                          SizedBox(width: 5),
                          Text('Make SubAdmin Only')
                        ],
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    ElevatedButton(
                      onPressed: deleteUsers,
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
                          Text('Delete Users')
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
