import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:goltens_core/models/auth.dart';
import 'package:goltens_mobile/components/admin/messages.dart';
import 'package:goltens_mobile/pages/admin/admin_meeting_page.dart';
import 'package:goltens_mobile/pages/feedback/feedback_assigned_page.dart';
import 'package:goltens_mobile/pages/feedback/feedback_list_page.dart';
import 'package:goltens_mobile/pages/master-list/master_list_page.dart';
import 'package:goltens_mobile/pages/others/user_type_choose_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:goltens_core/theme/theme.dart';
import 'package:goltens_mobile/pages/admin/admin_app_choose_page.dart';
import 'package:goltens_mobile/pages/admin/admin_communication_page.dart';
import 'package:goltens_mobile/pages/admin/admin_feedback_page.dart';
import 'package:goltens_mobile/pages/risk_assessment/risk_assessment_detail.dart';
import 'package:goltens_mobile/pages/feedback/feedback_page.dart';
import 'package:goltens_mobile/pages/others/app_choose_page.dart';
import 'package:goltens_mobile/pages/group/group_info_page.dart';
import 'package:goltens_mobile/pages/group/manage_members_page.dart';
import 'package:goltens_mobile/pages/auth/profile_page.dart';
import 'package:goltens_mobile/pages/auth/reset_password.dart';
import 'package:goltens_mobile/provider/global_state.dart';
import 'package:goltens_mobile/pages/auth/admin_approval_page.dart';
import 'package:goltens_mobile/pages/auth/admin_rejected_page.dart';
import 'package:goltens_mobile/pages/auth/auth_page.dart';
import 'package:goltens_mobile/pages/group/group_detail_page.dart';
import 'package:goltens_mobile/pages/group/home_page.dart';
import 'package:goltens_mobile/pages/message/message_detail_page.dart';
import 'package:goltens_mobile/pages/message/read_status_page.dart';
import 'package:goltens_mobile/pages/splash_screen.dart';
import 'package:goltens_mobile/pages/others/file_viewer_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp();

  // Handle Push Notification Click
  FirebaseMessaging.onMessageOpenedApp.listen(notificationHandler);

  // If App Closed Or Terminated
  FirebaseMessaging.instance.getInitialMessage().then(notificationHandler);

  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

  await FlutterDownloader.initialize(
    debug: !kReleaseMode,
    ignoreSsl: true,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GlobalState()),
      ],
      child: const App(),
    ),
  );
}

Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void notificationHandler(event) {
  if (event?.notification != null) {
    String? route = event.data['route'];
    var user = navigatorKey.currentContext?.read<GlobalState>().user?.data;

    switch (route) {
      case 'home':
        Navigator.pushNamed(navigatorKey.currentState!.context, '/home');
        break;
      case 'risk-assessment':
        Navigator.pushNamed(navigatorKey.currentState!.context, '/home');
        break;
      case 'other-files':
        Navigator.pushNamed(navigatorKey.currentState!.context, '/home');
        break;
      case 'user-orientation':
        Navigator.pushNamed(navigatorKey.currentState!.context, '/home');
        break;
      case 'messages':
        if (user?.type == UserType.admin) {
          Navigator.push(
            navigatorKey.currentState!.context,
            MaterialPageRoute(
              builder: (context) => const Messages(),
            ),
          );
        } else {
          Navigator.pushNamed(navigatorKey.currentState!.context, '/home');
        }
        break;
      case 'admin-feedback':
        Navigator.pushNamed(
          navigatorKey.currentState!.context,
          '/admin-feedback',
        );
        break;
      case 'feedbacks':
        Navigator.push(
          navigatorKey.currentState!.context,
          MaterialPageRoute(
            builder: (context) => const FeedbackListPage(),
          ),
        );
        break;
      case 'assigned-feedbacks':
        Navigator.push(
          navigatorKey.currentState!.context,
          MaterialPageRoute(
            builder: (context) => const FeedbackAssignedPage(),
          ),
        );
        break;
      default:
        Navigator.pushNamed(navigatorKey.currentState!.context, '/home');
        break;
    }
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goltens App',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: customTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthPage(),
        '/choose-app': (context) => const AppChoosePage(),
        '/choose-user-type': (context) => const UserTypeChoosePage(),
        '/home': (context) => const HomePage(),
        '/assessment-detail': (context) => const AssessmentDetailPage(),
        '/feedback': (context) => const FeedbackPage(),
        '/master-list': (context) => const MasterListPage(),
        '/group-detail': (context) => const GroupDetailPage(),
        '/message-detail': (context) => const MessageDetailPage(),
        '/admin-approval': (context) => const AdminApprovalPage(),
        '/admin-rejected': (context) => const AdminRejectedPage(),
        '/read-status': (context) => const ReadStatusPage(),
        '/manage-members': (context) => const ManageMembersPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        '/profile': (context) => const ProfilePage(),
        '/file-viewer': (context) => const FileViewerPage(),
        '/group-info': (context) => const GroupInfoPage(),
        '/admin-choose-app': (context) => const AdminAppChoosePage(),
        '/admin-communication': (context) => const AdminCommunicationPage(),
        '/admin-feedback': (context) => const AdminFeedbackPage(),
        '/admin-meeting': (context) => const AdminMeetingPage(),
      },
    );
  }
}
