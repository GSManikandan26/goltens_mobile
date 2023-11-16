import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:goltens_core/utils/functions.dart';
import 'package:goltens_core/utils/pdf_generator.dart';
import 'package:goltens_mobile/pages/others/file_viewer_page.dart';
import 'package:goltens_mobile/provider/global_state.dart';
import 'package:goltens_mobile/utils/functions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:goltens_mobile/components/feedback/feedback_drawer.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/models/feedback.dart';
import 'package:goltens_core/services/feedback.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  DateTime selectedDate = DateTime.now().toUtc();
  List<Map<String, dynamic>> filesArr = [];
  List<Map<String, dynamic>> actionFilesArr = [];
  bool isLoading = false;
  FeedbackData? feedback;

  List<String> locations = [
    '2nd Level Office',
    '2nd Level Non Service Warehouse',
    '2nd Level In-situ Shop',
    'ISD Shop',
    'Chrome Shop',
    'Machine Shop',
    'Welding Shop',
    'SCM Store & Logistic Office',
    'In-situ & Workshop Storage Room',
    'Engine Storage Room',
    'SCM & GT & GWW Office',
    'Reception Area',
    'GT Production Office',
    'Car Park & Open Yard'
  ];

  List<String> organizations = [
    'Goltens Singapore',
    'Goltens Trading Engineering',
    'Goltens Toei',
  ];

  List<String> feedbackOptions = [
    'Safety',
    'Quality',
    'Delivery',
    'Cost',
  ];

  List<String> sourceOptions = [
    'Safety / Waste Walk',
    'HOP Walk',
    'At Work / Observation',
    'WSH Monthly Inspection',
    'TBM inputs'
  ];

  String? selectedLocation;
  String? selectedOrganization;
  String? selectedFeedback;
  String? selectedSource;
  Status? selectedStatus;

  TextEditingController descriptionController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  TextEditingController actionTakenController = TextEditingController();
  TextEditingController acknowledgementController = TextEditingController();
  TextEditingController responsiblePersonController = TextEditingController();

  Color redColor = Colors.grey;
  Color yellowColor = Colors.grey;
  Color greenColor = Colors.green;

  List<bool> checkboxValues = [
    false,
    false,
    false,
    false,
    false,
  ];

  List<String> checkboxStrings = [
    'Unsafe Act',
    'Unsafe Equipment',
    'Unsafe Use of Equipment',
    'Unsafe Condition',
    'Continual Improvement'
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      dateController.text = formatDateTime(selectedDate, 'd/MM/y');
      timeController.text = formatDateTime(selectedDate, 'hh:mm aa');

      final settings = ModalRoute.of(context)!.settings;
      final feedbackData = settings.arguments as FeedbackData?;

      if (feedbackData == null) return;

      setState(() {
        feedback = feedbackData;
        selectedLocation = feedback?.location;
        selectedOrganization = feedback?.organizationName;

        dateController.text = feedback?.date ?? '';
        timeController.text = feedback?.time ?? '';

        selectedFeedback = feedback?.feedback;
        selectedSource = feedback?.source;

        redColor = Colors.grey;
        yellowColor = Colors.grey;
        greenColor = Colors.grey;

        if (feedback?.color == 'red') redColor = Colors.red;
        if (feedback?.color == 'yellow') yellowColor = Colors.yellow;
        if (feedback?.color == 'green') greenColor = Colors.green;

        for (String str in feedback?.selectedValues.split(",") ?? []) {
          int index = checkboxStrings.indexOf(str);
          if (index != -1) {
            checkboxValues[index] = true;
          }
        }

        descriptionController.text = feedback?.description ?? '';
        nameController.text = feedback?.reportedBy ?? '';

        responsiblePersonController.text = feedback?.responsiblePerson ?? '';
        actionTakenController.text = feedback?.actionTaken ?? '';
        acknowledgementController.text = feedback?.acknowledgement ?? '';
        selectedStatus = feedback?.status;
      });
    });
  }

  String? validateForm() {
    if (selectedLocation == null) return 'Select Location';
    if (selectedOrganization == null) return 'Select Organization';
    if (selectedFeedback == null) return 'Select Feedback';
    if (selectedSource == null) return 'Select Source';

    if (checkboxValues.every((element) => !element)) return 'Select a Checkbox';

    if (descriptionController.text.isEmpty) return 'Enter Description';
    if (nameController.text.isEmpty) return 'Enter Reported By';

    return null;
  }

  Future<File> exportPdfFile() async {
    List<Uint8List?> bytesArray = [];
    List<Uint8List?> actionBytesArray = [];

    await Future.forEach<FeedbackFile>(
      feedback?.files ?? [],
      (item) async {
        final imageUrl = '$apiUrl/$feedbackData/${item.name}';
        final bundle = NetworkAssetBundle(Uri.parse(imageUrl));
        var bytes = (await bundle.load(imageUrl)).buffer.asUint8List();
        bytesArray.add(bytes);
      },
    );

    await Future.forEach<FeedbackFile>(
      feedback?.actionFiles ?? [],
      (item) async {
        final imageUrl = '$apiUrl/$feedbackData/${item.name}';
        final bundle = NetworkAssetBundle(Uri.parse(imageUrl));
        var bytes = (await bundle.load(imageUrl)).buffer.asUint8List();
        actionBytesArray.add(bytes);
      },
    );

    final ByteData image = await rootBundle.load('assets/images/logo.png');
    Uint8List logoImage = (image).buffer.asUint8List();

    // Save the PDF file
    Uint8List pdfInBytes = await PDFGenerator.generateFeedbackDetail(
      feedback?.id ?? 0,
      feedback?.createdBy.name ?? '',
      feedback?.createdBy.email ?? '',
      feedback?.createdBy.phone ?? '',
      feedback?.location ?? '',
      feedback?.organizationName ?? '',
      feedback?.date ?? '',
      feedback?.time ?? '',
      feedback?.feedback ?? '',
      feedback?.source ?? '',
      feedback?.color ?? '',
      feedback?.selectedValues ?? '',
      feedback?.description ?? '',
      feedback?.reportedBy ?? '',
      feedback?.feedbackAssignments.isNotEmpty == true
          ? feedback?.feedbackAssignments[0].user.name ?? ''
          : '',
      feedback?.actionTaken ?? '',
      feedback?.status.toString().split('.').last ?? '',
      logoImage,
      feedback?.files ?? [],
      bytesArray,
      feedback?.actionFiles ?? [],
      actionBytesArray,
    );

    final directory = await getDownloadsDirectoryPath();
    File file = File('$directory/feedback-data-${feedback?.id}.pdf');
    file.writeAsBytes(pdfInBytes);
    return file;
  }

  Future<void> shareSubmitResponse(FeedbackData feedback) async {
    File file = await exportPdfFile();

    final Email email = Email(
      body: 'Submitted Feedback Form Of SERIAL ID: ${feedback.id} (PDF)',
      subject: '',
      recipients: ['Muthu.Manjunathan@goltens.com'],
      attachmentPaths: [file.path],
      isHTML: false,
    );

    await FlutterEmailSender.send(email);
  }

  Future<void> onFormSubmit() async {
    String? validationError = validateForm();

    if (validationError != null) {
      final snackBar = SnackBar(content: Text(validationError));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    try {
      var color = '';
      if (redColor == Colors.red) color = 'red';
      if (yellowColor == Colors.yellow) color = 'yellow';
      if (greenColor == Colors.green) color = 'green';

      var selectedValues = '';

      for (int i = 0; i < checkboxValues.length; i++) {
        if (checkboxValues[i]) {
          if (checkboxValues.isNotEmpty) {
            selectedValues += checkboxStrings[i];
          }

          selectedValues += ',';
        }
      }

      setState(() => isLoading = true);

      var response = await FeedbackService.createFeedback(
        selectedLocation ?? '',
        selectedOrganization ?? '',
        formatDateTime(selectedDate, 'd/MM/y'),
        formatDateTime(selectedDate, 'hh:mm aa'),
        selectedFeedback ?? '',
        selectedSource ?? '',
        color,
        selectedValues,
        descriptionController.text,
        filesArr,
        nameController.text,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Form Submitted Successfully"),
              actions: [
                TextButton(
                  child: const Text("OK"),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );

        shareSubmitResponse(response.data);
        onFormReset();
      }
    } catch (err) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(err.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> onFormReset() async {
    setState(() {
      selectedDate = DateTime.now();

      redColor = Colors.grey;
      yellowColor = Colors.grey;
      greenColor = Colors.green;

      selectedLocation = null;
      selectedOrganization = null;
      selectedFeedback = null;
      selectedSource = null;

      filesArr = [];
      descriptionController.text = '';
      nameController.text = '';

      checkboxValues = [
        false,
        false,
        false,
        false,
        false,
      ];
    });
  }

  Widget bottomSheetIcon(
    IconData icons,
    Color color,
    String text,
    void Function() onPress,
  ) {
    return InkWell(
      onTap: onPress,
      borderRadius: const BorderRadius.all(Radius.circular(100.0)),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(
              icons,
              size: 29,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 12),
          )
        ],
      ),
    );
  }

  Future<void> selectImage(ImageSource imageSource) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: imageSource);

    if (image == null) return;

    if (feedback == null) {
      setState(() {
        filesArr.add({'file': image, 'type': FileType.image});
      });
    } else {
      setState(() {
        actionFilesArr.add({'file': image, 'type': FileType.image});
      });
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void showImagePickerSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (builder) => SizedBox(
        height: 155,
        width: MediaQuery.of(context).size.width,
        child: Card(
          margin: const EdgeInsets.all(18.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 20,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    bottomSheetIcon(
                      Icons.camera_alt,
                      Colors.indigo,
                      "Camera",
                      () => selectImage(ImageSource.camera),
                    ),
                    const SizedBox(width: 40),
                    bottomSheetIcon(
                      Icons.photo,
                      Colors.pink,
                      "Gallery",
                      () => selectImage(ImageSource.gallery),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void toggleCheckbox(int index) {
    setState(() {
      checkboxValues[index] = !checkboxValues[index];
    });
  }

  void selectColor(String color) {
    setState(() {
      redColor = color == 'red' ? Colors.red : Colors.transparent;
      yellowColor = color == 'yellow' ? Colors.yellow : Colors.transparent;
      greenColor = color == 'green' ? Colors.green : Colors.transparent;
    });
  }

  Widget buildSerialCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => feedback == null ? selectColor('red') : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: redColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                  ),
                  child: const Text(
                    'Red',
                    style: TextStyle(
                      fontSize: 18.0,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => feedback == null
                      ? selectColor(
                          'yellow',
                        )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellowColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                  ),
                  child: const Text(
                    'Yellow',
                    style: TextStyle(
                      fontSize: 18.0,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => feedback == null
                      ? selectColor(
                          'green',
                        )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                  ),
                  child: const Text(
                    'Green',
                    style: TextStyle(
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildColorStatus() {
    return Row(
      children: [
        Text(
          redColor == Colors.red ? 'Stop Work and Report' : '',
          style: const TextStyle(
            fontSize: 18.0,
          ),
        ),
        Text(
          yellowColor == Colors.yellow ? 'Use Caution and Report' : '',
          style: const TextStyle(
            fontSize: 18.0,
          ),
        ),
        Text(
          greenColor == Colors.green ? 'Continue and Report' : '',
          style: const TextStyle(
            fontSize: 18.0,
          ),
        ),
      ],
    );
  }

  void showCompleteAssignmentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.only(left: 25, right: 25),
          title: const Center(child: Text("Complete Assignment")),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
          ),
          content: StatefulBuilder(
            builder: (
              BuildContext context,
              StateSetter setState,
            ) {
              return SizedBox(
                height: 160,
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 20),
                      const Text('Have you completed the given task ?'),
                      const SizedBox(height: 3),
                      const Text('This action is irreversible'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        onPressed: () async {
                          completeAssignment();
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.done),
                            SizedBox(width: 5.0),
                            Text('Complete Assignment')
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

  Future<void> sendAcknowledgement() async {
    if (acknowledgementController.text.isEmpty) {
      const snackBar = SnackBar(content: Text('Enter Acknowledgement'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    try {
      await FeedbackService.sendAcknowledgement(
        feedbackId: feedback?.id ?? 0,
        acknowledgement: acknowledgementController.text,
      );

      if (mounted) {
        const snackBar = SnackBar(
          content: Text('Acknowledgement Sent Successfully'),
        );

        setState(() {
          feedback?.acknowledgement = acknowledgementController.text;
        });

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> completeAssignment() async {
    try {
      await FeedbackService.completeFeedbackAssignment(
        feedbackId: feedback?.id ?? 0,
        actionTaken: actionTakenController.text,
        filesArr: actionFilesArr,
      );

      if (mounted) {
        const snackBar = SnackBar(content: Text('Assignment Completed'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      if (mounted) {
        var user = context.read<GlobalState>().user?.data;

        setState(() {
          if (feedback != null) {
            for (var assignment in feedback!.feedbackAssignments) {
              if (assignment.userId == user?.id &&
                  assignment.feedbackId == feedback?.id) {
                assignment.assignmentCompleted = true;
                break;
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    var currentUser = context.read<GlobalState>().user?.data;
    FeedbackAssignment? feedbackAssignment;

    if (feedback != null) {
      for (var assignment in feedback!.feedbackAssignments) {
        if (assignment.userId == currentUser?.id &&
            assignment.feedbackId == feedback?.id) {
          feedbackAssignment = assignment;
          break;
        }
      }
    }

    var isCurrentUserAssigned = currentUser?.id == feedbackAssignment?.userId;

    var shouldShowAcknowledgement =
        feedback?.feedbackAssignments.isNotEmpty == true &&
            feedback?.feedbackAssignments[0].assignmentCompleted == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
      ),
      drawer: feedback != null ? null : const FeedbackDrawer(currentIndex: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6.0),
              IgnorePointer(
                ignoring: feedback != null,
                child: DropdownButtonFormField<String>(
                  value: selectedLocation,
                  onChanged: (value) {
                    setState(() {
                      selectedLocation = value;
                    });
                  },
                  items: locations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(
                        location,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              IgnorePointer(
                ignoring: feedback != null,
                child: DropdownButtonFormField<String>(
                  value: selectedOrganization,
                  onChanged: (value) {
                    setState(() {
                      selectedOrganization = value;
                    });
                  },
                  items: organizations.map((organization) {
                    return DropdownMenuItem<String>(
                      value: organization,
                      child: Text(
                        organization,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Organization Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: dateController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: TextFormField(
                      controller: timeController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: IgnorePointer(
                      ignoring: feedback != null,
                      child: DropdownButtonFormField<String>(
                        value: selectedFeedback,
                        onChanged: (value) {
                          setState(() {
                            selectedFeedback = value;
                          });
                        },
                        items: feedbackOptions.map((feedback) {
                          return DropdownMenuItem<String>(
                            value: feedback,
                            child: Text(
                              feedback,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Feedback',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: feedback != null,
                      child: DropdownButtonFormField<String>(
                        value: selectedSource,
                        isExpanded: true,
                        onChanged: (value) {
                          setState(() {
                            selectedSource = value;
                          });
                        },
                        items: sourceOptions.map((source) {
                          return DropdownMenuItem<String>(
                            value: source,
                            child: Text(
                              source,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Source',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              buildSerialCard(),
              const SizedBox(height: 16.0),
              buildColorStatus(),
              const SizedBox(height: 16.0),
              Column(
                children: [
                  CheckboxListTile(
                    title: Text(checkboxStrings[0]),
                    value: checkboxValues[0],
                    onChanged: (value) => toggleCheckbox(0),
                    contentPadding: const EdgeInsets.all(0.0),
                    controlAffinity: ListTileControlAffinity.leading,
                    enabled: feedback == null,
                  ),
                  CheckboxListTile(
                    title: Text(checkboxStrings[1]),
                    value: checkboxValues[1],
                    onChanged: (value) => toggleCheckbox(1),
                    contentPadding: const EdgeInsets.all(0.0),
                    controlAffinity: ListTileControlAffinity.leading,
                    enabled: feedback == null,
                  ),
                  CheckboxListTile(
                    title: Text(checkboxStrings[2]),
                    value: checkboxValues[2],
                    onChanged: (value) => toggleCheckbox(2),
                    contentPadding: const EdgeInsets.all(0.0),
                    controlAffinity: ListTileControlAffinity.leading,
                    enabled: feedback == null,
                  ),
                  CheckboxListTile(
                    title: Text(checkboxStrings[3]),
                    value: checkboxValues[3],
                    onChanged: (value) => toggleCheckbox(3),
                    contentPadding: const EdgeInsets.all(0.0),
                    controlAffinity: ListTileControlAffinity.leading,
                    enabled: feedback == null,
                  ),
                  CheckboxListTile(
                    title: Text(checkboxStrings[4]),
                    value: checkboxValues[4],
                    onChanged: (value) => toggleCheckbox(4),
                    contentPadding: const EdgeInsets.all(0.0),
                    controlAffinity: ListTileControlAffinity.leading,
                    enabled: feedback == null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(fontSize: 18.0),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 20),
              TextFormField(
                minLines: 3,
                maxLines: null,
                controller: descriptionController,
                keyboardType: TextInputType.multiline,
                enabled: feedback == null,
                decoration: InputDecoration(
                  label: const Text('Description'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Photos',
                style: TextStyle(fontSize: 18.0),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 20),
              feedback != null && feedback?.files.isEmpty == true
                  ? const Text('No Photos')
                  : Container(),
              Column(
                children: feedback?.files.mapIndexed((index, file) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            child: Image.network(
                              '$apiUrl/$feedbackData/${file.name}',
                              width: 180,
                            ),
                            onTap: () async {
                              var url = '$apiUrl/$feedbackData/${file.name}';

                              var fetchedFile = await fetchFile(url);

                              if (fetchedFile != null) {
                                if (mounted) {
                                  Navigator.pushNamed(
                                    context,
                                    '/file-viewer',
                                    arguments: FileViewerPageArgs(
                                      file: fetchedFile,
                                      url: url,
                                      fileType: FileType.image,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList() ??
                    [],
              ),
              Column(
                children: filesArr.mapIndexed((index, fileObj) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.file(
                        File(fileObj['file'].path),
                        width: 180,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            filesArr.removeWhere(
                              (elem) => elem['file'] == fileObj['file'],
                            );

                            setState(() => filesArr = filesArr);
                          });
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Remove Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              ),
              feedback == null
                  ? ElevatedButton.icon(
                      onPressed: showImagePickerSheet,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Upload Photo'),
                    )
                  : Container(),
              const SizedBox(height: 16),
              const Text(
                'Reported By / Employee No',
                style: TextStyle(fontSize: 18.0),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 20),
              TextFormField(
                keyboardType: TextInputType.name,
                controller: nameController,
                enabled: feedback == null,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Visibility(
                visible: feedback != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assigned User',
                      style: TextStyle(fontSize: 20.0),
                    ),
                    const SizedBox(height: 20),
                    feedback != null &&
                            feedback?.feedbackAssignments.isEmpty == true
                        ? const Text('No User Assigned')
                        : Container(),
                    Column(
                      children: feedback?.feedbackAssignments
                              .map(
                                (obj) => ListTile(
                                  leading: CircleAvatar(
                                    child: obj.user.avatar.isNotEmpty == true
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              100.0,
                                            ),
                                            child: Image.network(
                                              '$apiUrl/$avatar/${obj.user.avatar}',
                                              errorBuilder: (
                                                context,
                                                obj,
                                                stacktrace,
                                              ) {
                                                return Container();
                                              },
                                            ),
                                          )
                                        : Text(obj.user.name[0]),
                                  ),
                                  title: Text(
                                    '${obj.user.name} ${isCurrentUserAssigned ? '(You)' : ''}',
                                  ),
                                  subtitle: Text(obj.user.email),
                                ),
                              )
                              .toList() ??
                          const [
                            Text('No Assigned User'),
                          ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              Visibility(
                visible: shouldShowAcknowledgement,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Send Acknowledgement',
                      style: TextStyle(fontSize: 20.0),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      minLines: 3,
                      maxLines: null,
                      enabled: feedback?.acknowledgement == null,
                      controller: acknowledgementController,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        label: const Text('Acknowledgement'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: feedback?.acknowledgement == null
                                ? sendAcknowledgement
                                : null,
                            icon: const Icon(Icons.done),
                            label: const Text('Send Acknowledgement'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Visibility(
                visible: feedback != null && isCurrentUserAssigned,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Action Taken',
                      style: TextStyle(fontSize: 20.0),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      minLines: 3,
                      maxLines: null,
                      controller: actionTakenController,
                      enabled: feedbackAssignment?.assignmentCompleted == false,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        label: const Text('Action Taken'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    feedback != null && feedback?.actionFiles.isEmpty == true
                        ? const Text('No Photos')
                        : Container(),
                    Column(
                      children: feedback?.actionFiles.mapIndexed((index, file) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  child: Image.network(
                                    '$apiUrl/$feedbackData/${file.name}',
                                    width: 180,
                                  ),
                                  onTap: () async {
                                    var url =
                                        '$apiUrl/$feedbackData/${file.name}';

                                    var fetchedFile = await fetchFile(url);

                                    if (fetchedFile != null) {
                                      if (mounted) {
                                        Navigator.pushNamed(
                                          context,
                                          '/file-viewer',
                                          arguments: FileViewerPageArgs(
                                            file: fetchedFile,
                                            url: url,
                                            fileType: FileType.image,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          }).toList() ??
                          [],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: actionFilesArr.mapIndexed((index, fileObj) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.file(
                              File(fileObj['file'].path),
                              width: 180,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  actionFilesArr.removeWhere(
                                    (elem) => elem['file'] == fileObj['file'],
                                  );

                                  setState(
                                    () => actionFilesArr = actionFilesArr,
                                  );
                                });
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('Remove Image'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),
                    ),
                    feedbackAssignment?.assignmentCompleted == false
                        ? ElevatedButton.icon(
                            onPressed: showImagePickerSheet,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Upload Photo'),
                          )
                        : Container(),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                feedbackAssignment?.assignmentCompleted == true
                                    ? null
                                    : showCompleteAssignmentDialog,
                            icon: const Icon(Icons.done),
                            label: Text(
                              feedbackAssignment?.assignmentCompleted == true
                                  ? 'Assignment Completed'
                                  : 'Complete Assignment',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              feedback == null
                  ? Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : onFormSubmit,
                            icon: const Icon(Icons.done),
                            label: const Text('SUBMIT'),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : onFormReset,
                            icon: const Icon(Icons.restart_alt_sharp),
                            label: const Text('RESET'),
                          ),
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
