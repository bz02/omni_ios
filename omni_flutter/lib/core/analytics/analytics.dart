/// Funnel instrumentation.
///
/// Without these numbers, pricing and the size of the free tier are guesses.
/// The four that decide revenue:
///
///   1. install to completed onboarding — the largest drop-off a divination
///      app has, because it asks for a birth time before it gives anything
///   2. which feature triggered the paywall — says whether the free tier is
///      too generous or too mean, and it is different per feature
///   3. paywall shown to purchased — the industry benchmark is 2 to 5%
///   4. day 1 and day 7 return
///
/// Deliberately not an SDK. PostHog's capture endpoint is one POST, and a
/// vendor SDK in an app that handles birth data is a privacy decision, not a
/// convenience one.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../billing/entitlements.dart';
import '../billing/products.dart';

abstract class Analytics {
  /// Records an event. Implementations must never throw and never block the
  /// caller: analytics failing is not worth breaking a reading over.
  void track(String event, [Map<String, Object?> properties]);

  void onboardingStarted() => track('onboarding_started');

  void onboardingCompleted({
    required bool hasBirthTime,
    required bool hasBirthPlace,
  }) =>
      track('onboarding_completed', {
        'has_birth_time': hasBirthTime,
        'has_birth_place': hasBirthPlace,
      });

  void readingViewed(String kind) => track('reading_viewed', {'kind': kind});

  void quotaExhausted(PremiumFeature feature) =>
      track('quota_exhausted', {'feature': feature.name});

  void paywallShown({PremiumFeature? trigger}) =>
      track('paywall_shown', {'trigger': trigger?.name ?? 'direct'});

  void paywallDismissed({PremiumFeature? trigger}) =>
      track('paywall_dismissed', {'trigger': trigger?.name ?? 'direct'});

  void purchaseStarted(OmniProduct product) => track('purchase_started', {
        'product_id': product.id,
        'kind': product.kind.name,
      });

  void purchaseCompleted(OmniProduct product) => track('purchase_completed', {
        'product_id': product.id,
        'kind': product.kind.name,
      });

  void purchaseFailed(OmniProduct product, String? reason) =>
      track('purchase_failed', {
        'product_id': product.id,
        'reason': reason ?? 'unknown',
      });

  void shared(String surface) => track('shared', {'surface': surface});
}

/// The default. Ships in builds with no analytics key, which includes every
/// local one.
class NoopAnalytics extends Analytics {
  @override
  void track(String event, [Map<String, Object?> properties = const {}]) {}
}

/// Prints to the log. Useful for checking the funnel fires in the right order
/// before wiring a real backend.
class DebugAnalytics extends Analytics {
  @override
  void track(String event, [Map<String, Object?> properties = const {}]) {
    debugPrint('analytics: $event ${properties.isEmpty ? '' : properties}');
  }
}

/// Posts to PostHog's capture endpoint.
///
/// Fire and forget: a failed capture is swallowed, because the alternative is
/// an analytics outage turning into an app outage.
class PostHogAnalytics extends Analytics {
  PostHogAnalytics({
    required this.projectKey,
    required this.distinctId,
    this.host = 'https://us.i.posthog.com',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String projectKey;

  /// The anonymous install id. No birth data, no name, no email is ever sent:
  /// this measures the funnel, not the person.
  final String distinctId;

  final String host;
  final http.Client _client;

  @override
  void track(String event, [Map<String, Object?> properties = const {}]) {
    unawaited(_send(event, properties));
  }

  Future<void> _send(String event, Map<String, Object?> properties) async {
    try {
      await _client
          .post(
            Uri.parse('$host/i/v0/e/'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'api_key': projectKey,
              'event': event,
              'distinct_id': distinctId,
              'properties': properties,
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Swallowed on purpose: see the class comment.
    }
  }

  void dispose() => _client.close();
}

/// Picks an implementation from the build configuration.
Analytics createAnalytics({
  required String projectKey,
  required String distinctId,
}) {
  if (projectKey.isEmpty) {
    return kDebugMode ? DebugAnalytics() : NoopAnalytics();
  }
  return PostHogAnalytics(projectKey: projectKey, distinctId: distinctId);
}
