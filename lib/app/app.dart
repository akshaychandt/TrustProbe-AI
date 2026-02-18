import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:trustprobe_ai/ui/views/home/home_view.dart';
import 'package:trustprobe_ai/services/phishing_service.dart';
import 'package:trustprobe_ai/services/firestore_service.dart';
import 'package:trustprobe_ai/services/ai_service.dart';

/// Stacked App Configuration
///
/// This file configures the app's routes and dependency injection.
/// After modifying this file, run:
/// flutter pub run build_runner build --delete-conflicting-outputs
@StackedApp(
  routes: [MaterialRoute(page: HomeView, initial: true)],
  dependencies: [
    LazySingleton(classType: AiService),
    LazySingleton(classType: PhishingService),
    LazySingleton(classType: FirestoreService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: SnackbarService),
  ],
)
class App {}
