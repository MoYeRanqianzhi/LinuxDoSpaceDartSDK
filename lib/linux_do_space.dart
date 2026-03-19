import "dart:async";
import "dart:convert";

import "package:http/http.dart" as http;

class Suffix {
  static const String linuxdoSpace = "linuxdo.space";
}

class LinuxDoSpaceException implements Exception {
  LinuxDoSpaceException(this.message, [this.inner]);
  final String message;
  final Object? inner;

  @override
  String toString() => "LinuxDoSpaceException: $message";
}

class AuthenticationException extends LinuxDoSpaceException {
  AuthenticationException(super.message, [super.inner]);
}

class StreamException extends LinuxDoSpaceException {
  StreamException(super.message, [super.inner]);
}

class MailMessage {
  MailMessage({
    required this.address,
    required this.sender,
    required this.recipients,
    required this.receivedAt,
    required this.subject,
    this.messageId,
    this.date,
    required this.fromHeader,
    required this.toHeader,
    required this.ccHeader,
    required this.replyToHeader,
    required this.fromAddresses,
    required this.toAddresses,
    required this.ccAddresses,
    required this.replyToAddresses,
    required this.text,
    required this.html,
    required this.headers,
    required this.raw,
    required this.rawBytes,
  });

  final String address;
  final String sender;
  final List<String> recipients;
  final DateTime receivedAt;
  final String subject;
  final String? messageId;
  final DateTime? date;
  final String fromHeader;
  final String toHeader;
  final String ccHeader;
  final String replyToHeader;
  final List<String> fromAddresses;
  final List<String> toAddresses;
  final List<String> ccAddresses;
  final List<String> replyToAddresses;
  final String text;
  final String html;
  final Map<String, String> headers;
  final String raw;
  final List<int> rawBytes;
}

class MailBox {
  MailBox({
    required this.mode,
    required this.suffix,
    required this.allowOverlap,
    required this.prefix,
    required this.pattern,
    required Future<void> Function() unbind,
  }) : _unbind = unbind {
    address = prefix == null ? null : "${prefix!}@$suffix";
  }

  final String mode;
  final String suffix;
  final bool allowOverlap;
  final String? prefix;
  final String? pattern;
  late final String? address;

  final Future<void> Function() _unbind;
  StreamController<MailMessage>? _controller;
  bool _closed = false;
  bool _activated = false;
  bool _listening = false;

  bool get closed => _closed;

  Stream<MailMessage> listen() {
    if (_closed) {
      throw LinuxDoSpaceException("mailbox is already closed");
    }
    if (_listening) {
      throw LinuxDoSpaceException("mailbox already has an active listener");
    }
    final controller = StreamController<MailMessage>();
    controller.onCancel = () {
      if (identical(_controller, controller)) {
        _controller = null;
        _activated = false;
        _listening = false;
      }
    };
    _controller = controller;
    _activated = true;
    _listening = true;
    return controller.stream;
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    final controller = _controller;
    _controller = null;
    _activated = false;
    _listening = false;
    await _unbind();
    await controller?.close();
  }

  void _enqueue(MailMessage message) {
    if (_closed || !_activated) {
      return;
    }
    _controller?.add(message);
  }

  void _enqueueError(Object error) {
    if (_closed) {
      return;
    }
    _controller?.addError(error);
  }
}

class _Binding {
  _Binding({
    required this.mode,
    required this.suffix,
    required this.allowOverlap,
    required this.prefix,
    required this.pattern,
    required this.mailbox,
  });

  final String mode;
  final String suffix;
  final bool allowOverlap;
  final String? prefix;
  final RegExp? pattern;
  final MailBox mailbox;

  bool matches(String localPart) => mode == "exact" ? prefix == localPart : (pattern?.hasMatch(localPart) ?? false);
}

class Client {
  Client(
    String token, {
    String baseUrl = "https://api.linuxdo.space",
    Duration connectTimeout = const Duration(seconds: 10),
    Duration streamTimeout = const Duration(seconds: 30),
    http.Client? httpClient,
  })  : _token = token.trim(),
        _baseUrl = _normalizeBaseUrl(baseUrl),
        _connectTimeout = connectTimeout,
        _streamTimeout = streamTimeout,
        _http = httpClient ?? http.Client() {
    if (_token.isEmpty) {
      throw ArgumentError("token must not be empty");
    }
    _reader = _readLoop();
  }

  final String _token;
  final Uri _baseUrl;
  final Duration _connectTimeout;
  final Duration _streamTimeout;
  final http.Client _http;
  final StreamController<MailMessage> _fullController = StreamController<MailMessage>.broadcast();
  final Map<String, List<_Binding>> _bindingsBySuffix = <String, List<_Binding>>{};
  bool _closed = false;
  late final Future<void> _reader;

  Stream<MailMessage> listen() => _fullController.stream;

  MailBox bind({
    String? prefix,
    String? pattern,
    String suffix = Suffix.linuxdoSpace,
    bool allowOverlap = false,
  }) {
    final hasPrefix = prefix != null && prefix.trim().isNotEmpty;
    final hasPattern = pattern != null && pattern.trim().isNotEmpty;
    if (hasPrefix == hasPattern) {
      throw ArgumentError("exactly one of prefix or pattern must be provided");
    }
    final normalizedSuffix = suffix.trim().toLowerCase();
    final prefixText = prefix?.trim();
    final patternText = pattern?.trim();
    final normalizedPrefix = hasPrefix ? prefixText!.toLowerCase() : null;
    final mode = hasPrefix ? "exact" : "pattern";
    final regex = hasPattern ? RegExp("^${patternText!}\$") : null;

    late _Binding binding;
    final mailbox = MailBox(
      mode: mode,
      suffix: normalizedSuffix,
      allowOverlap: allowOverlap,
      prefix: normalizedPrefix,
      pattern: patternText,
      unbind: () async {
        final chain = _bindingsBySuffix[normalizedSuffix];
        if (chain == null) {
          return;
        }
        chain.removeWhere((item) => identical(item, binding));
        if (chain.isEmpty) {
          _bindingsBySuffix.remove(normalizedSuffix);
        }
      },
    );
    binding = _Binding(mode: mode, suffix: normalizedSuffix, allowOverlap: allowOverlap, prefix: normalizedPrefix, pattern: regex, mailbox: mailbox);
    _bindingsBySuffix.putIfAbsent(normalizedSuffix, () => <_Binding>[]).add(binding);
    return mailbox;
  }

  List<MailBox> route(MailMessage message) => _matchBindingsForAddress(message.address).map((item) => item.mailbox).toList(growable: false);

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    final mailboxes = _bindingsBySuffix.values.expand((v) => v.map((b) => b.mailbox)).toSet().toList(growable: false);
    _bindingsBySuffix.clear();
    for (final mailbox in mailboxes) {
      await mailbox.close();
    }
    await _fullController.close();
    _http.close();
    await _reader;
  }

  Future<void> _readLoop() async {
    while (!_closed) {
      try {
        await _consumeOnce();
      } catch (error) {
        if (error is AuthenticationException) {
          _broadcastError(error);
          return;
        }
        _broadcastError(error);
      }
      if (!_closed) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  Future<void> _consumeOnce() async {
    final request = http.Request("GET", _baseUrl.resolve("/v1/token/email/stream"));
    request.headers["Authorization"] = "Bearer $_token";
    request.headers["Accept"] = "application/x-ndjson";
    final response = await _http.send(request).timeout(_connectTimeout);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AuthenticationException("api token was rejected by backend");
    }
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw StreamException("unexpected stream status code: ${response.statusCode}");
    }

    var lastDataAt = DateTime.now().toUtc();
    await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (_closed) {
        return;
      }
      if (line.trim().isEmpty) {
        continue;
      }
      if (DateTime.now().toUtc().difference(lastDataAt) > _streamTimeout) {
        throw StreamException("mail stream stalled and will reconnect");
      }
      lastDataAt = DateTime.now().toUtc();
      _handleLine(line.trim());
    }
  }

  void _handleLine(String line) {
    final dynamic decoded = jsonDecode(line);
    if (decoded is! Map<String, dynamic>) {
      throw StreamException("invalid NDJSON event payload");
    }
    final type = (decoded["type"] ?? "").toString();
    if (type == "ready" || type == "heartbeat") {
      return;
    }
    if (type != "mail") {
      return;
    }
    _dispatchMail(decoded);
  }

  void _dispatchMail(Map<String, dynamic> payload) {
    final recipients = (payload["original_recipients"] as List<dynamic>? ?? <dynamic>[])
        .map((item) => item.toString().trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final sender = (payload["original_envelope_from"] ?? "").toString().trim();
    final receivedAt = DateTime.tryParse((payload["received_at"] ?? "").toString()) ?? DateTime.now().toUtc();
    final rawBase64 = (payload["raw_message_base64"] ?? "").toString().trim();
    final rawBytes = rawBase64.isEmpty ? <int>[] : base64Decode(rawBase64);
    final raw = utf8.decode(rawBytes, allowMalformed: true);

    final primary = recipients.isEmpty ? "" : recipients.first;
    final message = MailMessage(
      address: primary,
      sender: sender,
      recipients: recipients,
      receivedAt: receivedAt,
      subject: "",
      messageId: null,
      date: null,
      fromHeader: "",
      toHeader: "",
      ccHeader: "",
      replyToHeader: "",
      fromAddresses: const <String>[],
      toAddresses: const <String>[],
      ccAddresses: const <String>[],
      replyToAddresses: const <String>[],
      text: raw,
      html: "",
      headers: const <String, String>{},
      raw: raw,
      rawBytes: rawBytes,
    );
    _fullController.add(message);

    final seen = <String>{};
    for (final recipient in recipients) {
      if (!seen.add(recipient)) {
        continue;
      }
      for (final binding in _matchBindingsForAddress(recipient)) {
        binding.mailbox._enqueue(message);
      }
    }
  }

  List<_Binding> _matchBindingsForAddress(String address) {
    final normalized = address.trim().toLowerCase();
    final at = normalized.indexOf("@");
    if (at <= 0 || at >= normalized.length - 1) {
      return const <_Binding>[];
    }
    final localPart = normalized.substring(0, at);
    final suffix = normalized.substring(at + 1);
    final chain = _bindingsBySuffix[suffix] ?? const <_Binding>[];
    final matched = <_Binding>[];
    for (final binding in chain) {
      if (!binding.matches(localPart)) {
        continue;
      }
      matched.add(binding);
      if (!binding.allowOverlap) {
        break;
      }
    }
    return matched;
  }

  void _broadcastError(Object error) {
    _fullController.addError(error);
    final mailboxes = _bindingsBySuffix.values.expand((items) => items.map((item) => item.mailbox)).toSet();
    for (final mailbox in mailboxes) {
      mailbox._enqueueError(error);
    }
  }

  static Uri _normalizeBaseUrl(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r"/+$"), "");
    if (normalized.isEmpty) {
      throw ArgumentError("base_url must not be empty");
    }
    final uri = Uri.parse(normalized);
    if (!uri.hasScheme || uri.host.isEmpty) {
      throw ArgumentError("base_url must include scheme and host");
    }
    if (uri.scheme != "https" && uri.scheme != "http") {
      throw ArgumentError("base_url must use http or https");
    }
    if (uri.scheme == "http") {
      final host = uri.host.toLowerCase();
      final local = host == "localhost" || host == "127.0.0.1" || host == "::1" || host.endsWith(".localhost");
      if (!local) {
        throw ArgumentError("non-local base_url must use https");
      }
    }
    return uri;
  }
}
