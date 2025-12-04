import 'package:local_notifier/local_notifier.dart';

class NotificationService {
	NotificationService._privateConstructor();
	static final NotificationService _instance = NotificationService._privateConstructor();
	factory NotificationService() => _instance;

	bool _initialized = false;

	/// Initialize the local notifier plugin. Call this early (e.g. in main)
	Future<void> init() async {
		if (_initialized) return;
		await localNotifier.setup(
			appName: 'aquarium_controller_app',
			// On Windows this helps create a shortcut for toast activation
			shortcutPolicy: ShortcutPolicy.requireCreate,
		);
		_initialized = true;
	}

	/// Show a simple notification. Safe to call before [init].
	Future<void> showNotification({
		required String title,
		required String body,
		String? imagePath,
	}) async {
		if (!_initialized) await init();

		final notification = LocalNotification(
			title: title,
			body: body,
			// imagePath and other fields can be set if supported on the platform
		);

		// Optional callbacks
		notification.onShow = () {
			// put telemetry or logging here if you want
		};
		notification.onClick = () {
			// e.g. bring app to foreground or open a page
		};

		notification.show();
	}
}

/// Convenience top-level instance
final notificationService = NotificationService();
