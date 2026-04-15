import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif
#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

/// Central place to enable/disable analytics and crash reporting based on user consent.
/// Replace the print statements with actual SDK calls (e.g., Firebase Analytics/Crashlytics) when integrated.
enum TelemetryManager {
    static private(set) var isAnalyticsEnabled: Bool = false
    static private(set) var isCrashReportingEnabled: Bool = false

    static func bootstrapIfNeeded() {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("ℹ️ FirebaseApp configured.")
        }
        #endif
    }

    static func configureFromConsent() {
        bootstrapIfNeeded()
        let analytics = ConsentManager.shared.analyticsAllowed()
        let crash = ConsentManager.shared.crashReportsAllowed()
        enableAnalytics(analytics)
        enableCrashReporting(crash)
        print("ℹ️ Telemetry configured. Analytics=\(isAnalyticsEnabled), Crash=\(isCrashReportingEnabled)")
    }

    static func enableAnalytics(_ enabled: Bool) {
        isAnalyticsEnabled = enabled
        #if canImport(FirebaseAnalytics)
        Analytics.setAnalyticsCollectionEnabled(enabled)
        print(enabled ? "✅ Firebase Analytics Enabled" : "🚫 Firebase Analytics Disabled")
        #else
        print(enabled ? "✅ Analytics Enabled (no SDK)" : "🚫 Analytics Disabled (no SDK)")
        #endif
    }

    static func enableCrashReporting(_ enabled: Bool) {
        isCrashReportingEnabled = enabled
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enabled)
        print(enabled ? "✅ Firebase Crashlytics Enabled" : "🚫 Firebase Crashlytics Disabled")
        #else
        print(enabled ? "✅ Crash Reporting Enabled (no SDK)" : "🚫 Crash Reporting Disabled (no SDK)")
        #endif
    }
}

