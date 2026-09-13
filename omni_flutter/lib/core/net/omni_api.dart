/// Client for the Omni backend.
///
/// The backend exists for three reasons, all of which are launch blockers:
///
///   1. **The model key.** A key compiled into a client is extractable by
///      anyone who downloads the app. Readings go through the server so the
///      key never ships.
///   2. **Proof of payment.** A purchase recorded on the device is a number in
///      shared preferences, and a jailbroken phone can write whatever it likes
///      there. The server asks Stripe (or Apple) and is believed instead.
///   3. **Taking money on the web at all.** There is no `in_app_purchase` on
///      web, so the web build needs Stripe Checkout, which needs a server to
///      create the session with a secret key.
///
/// Every method degrades rather than throwing: with no backend configured the
/// app still computes charts locally, which is most of what it does.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../billing/products.dart';

/// What the server says a user is entitled to. This is the authoritative
/// answer; the local copy is a cache of it.
class ServerEntitlement {
  const ServerEntitlement({
    required this.tier,
    this.expiresAt,
    this.jadeCoins = 0,
    this.restoreCode,
    this.managementUrl,
  });

  final Tier tier;
  final DateTime? expiresAt;
  final int jadeCoins;

  /// Opaque token that proves this purchase, shown to the user so they can
  /// move a subscription to another device. Anonymous checkout means there is
  /// no account to log into, so the receipt itself is the credential.
  final String? restoreCode;

  /// Stripe billing portal link, so "cancel my subscription" is one tap and
  /// not a support email.
  final String? managementUrl;

  static const none = ServerEntitlement(tier: Tier.free);

  factory ServerEntitlement.fromJson(Map<String, dynamic> json) =>
      ServerEntitlement(
        tier: Tier.values.firstWhere(
          (t) => t.name == json['tier'],
          orElse: () => Tier.free,
        ),
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.tryParse(json['expiresAt'] as String),
        jadeCoins: (json['jadeCoins'] as num?)?.toInt() ?? 0,
        restoreCode: json['restoreCode'] as String?,
        managementUrl: json['managementUrl'] as String?,
      );
}

class OmniApiException implements Exception {
  const OmniApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'OmniApiException($statusCode): $message';
}

class OmniApi {
  OmniApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// False when no backend is configured, which is the default for a local
  /// build. Callers fall back to on-device behaviour.
  bool get isConfigured => _baseUrl.isNotEmpty;

  static const _timeout = Duration(seconds: 20);

  /// Starts a Stripe Checkout session and returns the URL to send the browser
  /// to. [installId] ties the resulting subscription to this device.
  Future<String> createCheckout({
    required String productId,
    required String installId,
    required String returnUrl,
  }) async {
    final body = await _post('/v1/checkout', {
      'productId': productId,
      'installId': installId,
      'returnUrl': returnUrl,
    });
    final url = body['url'] as String?;
    if (url == null || url.isEmpty) {
      throw const OmniApiException('Checkout session came back without a URL.');
    }
    return url;
  }

  /// Asks the server what this install is entitled to.
  ///
  /// [restoreCode] carries a receipt from another device; without it the
  /// server answers for [installId] alone.
  Future<ServerEntitlement> fetchEntitlement({
    required String installId,
    String? restoreCode,
  }) async {
    final query = {
      'installId': installId,
      if (restoreCode != null && restoreCode.isNotEmpty) 'code': restoreCode,
    };
    final body = await _get('/v1/entitlement', query);
    return ServerEntitlement.fromJson(body);
  }

  /// Generates a reading. The prompt is assembled server-side from the chart
  /// so the client cannot turn this into a general-purpose model endpoint.
  Future<String> reading({
    required String installId,
    required String kind,
    required Map<String, dynamic> chart,
    String? question,
  }) async {
    final body = await _post('/v1/reading', {
      'installId': installId,
      'kind': kind,
      'chart': chart,
      if (question != null) 'question': question,
    });
    return body['text'] as String? ?? '';
  }

  Future<Map<String, dynamic>> _get(
      String path, Map<String, String> query) async {
    _requireConfigured();
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    try {
      final response = await _client.get(uri).timeout(_timeout);
      return _decode(response);
    } on OmniApiException {
      rethrow;
    } catch (error) {
      throw OmniApiException('Could not reach the server: $error');
    }
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> payload) async {
    _requireConfigured();
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
      return _decode(response);
    } on OmniApiException {
      rethrow;
    } catch (error) {
      throw OmniApiException('Could not reach the server: $error');
    }
  }

  void _requireConfigured() {
    if (!isConfigured) {
      throw const OmniApiException('No backend is configured for this build.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw OmniApiException(
        'The server replied with something that was not JSON.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 400) {
      throw OmniApiException(
        body['error'] as String? ?? 'Request failed.',
        statusCode: response.statusCode,
      );
    }
    return body;
  }

  void dispose() => _client.close();
}
