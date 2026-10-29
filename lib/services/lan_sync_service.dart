import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/pos_models.dart';

class DiscoveredServer {
  final String name;
  final String ip;
  final int port;

  const DiscoveredServer({
    required this.name,
    required this.ip,
    required this.port,
  });

  @override
  bool operator ==(Object other) =>
      other is DiscoveredServer && other.ip == ip && other.port == port;

  @override
  int get hashCode => Object.hash(ip, port);
}

class LanSyncService {
  static const int defaultHttpPort = 8080;
  static const int udpDiscoveryPort = 45454;

  HttpServer? _httpServer;
  RawDatagramSocket? _udpSocket;
  Timer? _udpBroadcastTimer;
  final List<WebSocket> _clientSockets = [];
  final Map<WebSocket, String> _clientAddresses = {};

  WebSocket? _serverSocket;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  String? _connectedServerIp;
  int _connectedServerPort = defaultHttpPort;
  bool _isClientConnected = false;
  bool _intentionalDisconnect = false;

  // Callbacks for Server & Client state synchronization
  List<PosOrder> Function()? onGetOrdersSnapshot;
  List<Product> Function()? onGetProductsSnapshot;
  void Function(List<PosOrder> orders)? onFullSyncReceived;
  void Function(PosOrder order, {required bool isNew})? onOrderReceivedOrUpdated;
  void Function()? onStatusChanged;

  bool get isServerRunning => _httpServer != null;
  int get serverPort => _httpServer?.port ?? defaultHttpPort;
  int get connectedClientsCount => _clientSockets.length;
  List<String> get connectedClientIps =>
      _clientAddresses.values.toList(growable: false);

  bool get isClientConnected => _isClientConnected;
  String? get connectedServerIp => _connectedServerIp;
  int get connectedServerPort => _connectedServerPort;

  /// Returns all local IPv4 addresses on LAN interfaces
  Future<List<String>> getLocalIps() async {
    final ips = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && !ips.contains(addr.address)) {
            ips.add(addr.address);
          }
        }
      }
    } catch (e) {
      debugPrint('Error listing network interfaces: $e');
    }
    if (ips.isEmpty) {
      ips.add('127.0.0.1');
    }
    return ips;
  }

  // ==================== SERVER MODE ====================

  Future<bool> startServer({
    int port = defaultHttpPort,
    String serverName = 'FLASHPOS · DOGOS EL PA',
  }) async {
    await stopServer();
    try {
      try {
        _httpServer = await HttpServer.bind(
          InternetAddress.anyIPv4,
          port,
          shared: true,
        );
      } catch (_) {
        // Fallback port if 8080 is taken
        _httpServer = await HttpServer.bind(
          InternetAddress.anyIPv4,
          port + 1,
          shared: true,
        );
      }

      _httpServer!.listen((HttpRequest request) async {
        // Enable CORS headers
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers
            .add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        request.response.headers
            .add('Access-Control-Allow-Headers', 'Content-Type');

        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        final path = request.uri.path;

        if (path == '/ping') {
          final orders = onGetOrdersSnapshot?.call() ?? [];
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({
            'status': 'ok',
            'name': serverName,
            'port': _httpServer!.port,
            'ordersCount': orders.length,
          }));
          await request.response.close();
          return;
        }

        if (path == '/orders' && request.method == 'GET') {
          final orders = onGetOrdersSnapshot?.call() ?? [];
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({
            'orders': orders.map((o) => o.toJson(includeBase64: false)).toList(),
          }));
          await request.response.close();
          return;
        }

        if (path == '/order-update' && request.method == 'POST') {
          try {
            final body = await utf8.decoder.bind(request).join();
            final data = jsonDecode(body) as Map<String, dynamic>;
            if (data['order'] != null) {
              final updatedOrder = PosOrder.fromJson(
                Map<String, dynamic>.from(data['order'] as Map),
              );
              onOrderReceivedOrUpdated?.call(updatedOrder, isNew: false);
              broadcastOrderUpdate(updatedOrder);
            }
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'status': 'ok'}));
          } catch (e) {
            request.response.statusCode = HttpStatus.badRequest;
            request.response.write(jsonEncode({'error': e.toString()}));
          }
          await request.response.close();
          return;
        }

        if (path == '/ws' && WebSocketTransformer.isUpgradeRequest(request)) {
          final remoteIp =
              request.connectionInfo?.remoteAddress.address ?? 'Cliente LAN';
          final socket = await WebSocketTransformer.upgrade(request);
          _handleNewClientSocket(socket, remoteIp);
          return;
        }

        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      await _startUdpDiscoveryResponder(serverName);
      onStatusChanged?.call();
      return true;
    } catch (e) {
      debugPrint('Failed to start LAN server: $e');
      onStatusChanged?.call();
      return false;
    }
  }

  void _handleNewClientSocket(WebSocket socket, String remoteIp) {
    _clientSockets.add(socket);
    _clientAddresses[socket] = remoteIp;
    onStatusChanged?.call();

    // Send initial full sync of active orders
    final orders = onGetOrdersSnapshot?.call() ?? [];
    _safeSend(socket, {
      'type': 'FULL_SYNC',
      'orders': orders.map((o) => o.toJson()).toList(),
    });

    socket.listen(
      (dynamic rawMessage) {
        try {
          final data =
              jsonDecode(rawMessage.toString()) as Map<String, dynamic>;
          final type = data['type']?.toString();

          if (type == 'PING') {
            _safeSend(socket, {'type': 'PONG'});
          } else if (type == 'REQUEST_SYNC') {
            final currentOrders = onGetOrdersSnapshot?.call() ?? [];
            _safeSend(socket, {
              'type': 'FULL_SYNC',
              'orders': currentOrders.map((o) => o.toJson()).toList(),
            });
          } else if (type == 'UPDATE_ORDER' && data['order'] != null) {
            final updatedOrder = PosOrder.fromJson(
              Map<String, dynamic>.from(data['order'] as Map),
            );
            onOrderReceivedOrUpdated?.call(updatedOrder, isNew: false);
            // Broadcast to all other connected clients
            for (final client in List<WebSocket>.from(_clientSockets)) {
              if (client != socket) {
                _safeSend(client, {
                  'type': 'ORDER_UPDATED',
                  'order': updatedOrder.toJson(),
                });
              }
            }
          }
        } catch (e) {
          debugPrint('Error handling message from client: $e');
        }
      },
      onDone: () {
        _clientSockets.remove(socket);
        _clientAddresses.remove(socket);
        onStatusChanged?.call();
      },
      onError: (_) {
        _clientSockets.remove(socket);
        _clientAddresses.remove(socket);
        onStatusChanged?.call();
      },
    );
  }

  Future<void> _startUdpDiscoveryResponder(String serverName) async {
    try {
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        udpDiscoveryPort,
        reuseAddress: true,
      );
      _udpSocket!.broadcastEnabled = true;

      _udpSocket!.listen((RawSocketEvent event) async {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket!.receive();
          if (datagram == null) return;
          final msg = utf8.decode(datagram.data, allowMalformed: true);
          if (msg.startsWith('DOGOS_POS_DISCOVER')) {
            final localIps = await getLocalIps();
            final reply = jsonEncode({
              'type': 'SERVER_OFFER',
              'name': serverName,
              'port': serverPort,
              'ips': localIps,
            });
            _udpSocket!.send(
              utf8.encode(reply),
              datagram.address,
              datagram.port,
            );
          }
        }
      });
    } catch (e) {
      debugPrint('UDP discovery responder bind notice: $e');
    }
  }

  void broadcastNewOrder(PosOrder order) {
    final payload = {
      'type': 'NEW_ORDER',
      'order': order.toJson(),
    };
    for (final client in List<WebSocket>.from(_clientSockets)) {
      _safeSend(client, payload);
    }
  }

  void broadcastOrderUpdate(PosOrder order) {
    final payload = {
      'type': 'ORDER_UPDATED',
      'order': order.toJson(),
    };
    for (final client in List<WebSocket>.from(_clientSockets)) {
      _safeSend(client, payload);
    }
  }

  void broadcastFullSync(List<PosOrder> orders) {
    final payload = {
      'type': 'FULL_SYNC',
      'orders': orders.map((o) => o.toJson()).toList(),
    };
    for (final client in List<WebSocket>.from(_clientSockets)) {
      _safeSend(client, payload);
    }
  }

  Future<void> stopServer() async {
    _udpBroadcastTimer?.cancel();
    _udpBroadcastTimer = null;
    _udpSocket?.close();
    _udpSocket = null;

    for (final s in List<WebSocket>.from(_clientSockets)) {
      try {
        await s.close();
      } catch (_) {}
    }
    _clientSockets.clear();
    _clientAddresses.clear();

    try {
      await _httpServer?.close(force: true);
    } catch (_) {}
    _httpServer = null;
    onStatusChanged?.call();
  }

  // ==================== CLIENT MODE ====================

  /// Discovers servers on the local network using UDP Broadcast + HTTP Subnet Scan
  Future<List<DiscoveredServer>> discoverServers({
    int port = defaultHttpPort,
  }) async {
    final found = <DiscoveredServer>{};

    // 1. Check localhost first (for same-machine testing)
    final localHit = await _probeServerHttp('127.0.0.1', port);
    if (localHit != null) {
      found.add(localHit);
    }

    // 2. Send UDP Broadcast
    RawDatagramSocket? tempUdp;
    try {
      tempUdp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      tempUdp.broadcastEnabled = true;
      tempUdp.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = tempUdp?.receive();
          if (dg == null) return;
          try {
            final map =
                jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
            if (map['type'] == 'SERVER_OFFER') {
              final sPort = (map['port'] as num?)?.toInt() ?? port;
              final sName =
                  map['name']?.toString() ?? 'FLASHPOS · DOGOS EL PA';
              found.add(DiscoveredServer(
                name: sName,
                ip: dg.address.address,
                port: sPort,
              ));
            }
          } catch (_) {}
        }
      });

      final discoverBytes = utf8.encode('DOGOS_POS_DISCOVER');
      tempUdp.send(
        discoverBytes,
        InternetAddress('255.255.255.255'),
        udpDiscoveryPort,
      );

      final myIps = await getLocalIps();
      for (final ip in myIps) {
        final parts = ip.split('.');
        if (parts.length == 4) {
          final subnetBroadcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
          try {
            tempUdp.send(
              discoverBytes,
              InternetAddress(subnetBroadcast),
              udpDiscoveryPort,
            );
          } catch (_) {}
        }
      }
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (_) {
    } finally {
      tempUdp?.close();
    }

    if (found.isNotEmpty) {
      return found.toList();
    }

    // 3. Fast parallel HTTP Subnet Scan fallback if UDP was blocked by router/firewall
    final myIps = await getLocalIps();
    for (final myIp in myIps) {
      final parts = myIp.split('.');
      if (parts.length != 4 || myIp == '127.0.0.1') continue;
      final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';

      // Scan in batches of 50 IPs
      for (int start = 1; start <= 254; start += 50) {
        final futures = <Future<DiscoveredServer?>>[];
        for (int i = start; i < start + 50 && i <= 254; i++) {
          final candidateIp = '$prefix.$i';
          futures.add(_probeServerHttp(candidateIp, port));
        }
        final results = await Future.wait(futures);
        for (final r in results) {
          if (r != null) found.add(r);
        }
        if (found.isNotEmpty) break;
      }
    }

    return found.toList();
  }

  Future<DiscoveredServer?> _probeServerHttp(String ip, int port) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(milliseconds: 350);
    try {
      final req = await client
          .getUrl(Uri.parse('http://$ip:$port/ping'))
          .timeout(const Duration(milliseconds: 400));
      final resp =
          await req.close().timeout(const Duration(milliseconds: 400));
      if (resp.statusCode == 200) {
        final body = await utf8.decoder.bind(resp).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        if (data['status'] == 'ok') {
          return DiscoveredServer(
            name: data['name']?.toString() ?? 'FLASHPOS · DOGOS EL PA',
            ip: ip,
            port: (data['port'] as num?)?.toInt() ?? port,
          );
        }
      }
    } catch (_) {
    } finally {
      client.close(force: true);
    }
    return null;
  }

  Future<bool> connectToServer(
    String ip, {
    int port = defaultHttpPort,
  }) async {
    _intentionalDisconnect = false;
    _connectedServerIp = ip.trim();
    _connectedServerPort = port;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();

    try {
      await _serverSocket?.close();
    } catch (_) {}
    _serverSocket = null;

    try {
      final wsUrl = 'ws://$_connectedServerIp:$_connectedServerPort/ws';
      final socket = await WebSocket.connect(wsUrl)
          .timeout(const Duration(seconds: 4));

      _serverSocket = socket;
      _isClientConnected = true;
      onStatusChanged?.call();

      _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_serverSocket != null) {
          _safeSend(_serverSocket!, {'type': 'PING'});
        }
      });

      socket.listen(
        (dynamic rawMessage) {
          try {
            final data =
                jsonDecode(rawMessage.toString()) as Map<String, dynamic>;
            final type = data['type']?.toString();

            if (type == 'FULL_SYNC' && data['orders'] is List) {
              final rawList = data['orders'] as List;
              final orders = rawList
                  .map((e) =>
                      PosOrder.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList();
              onFullSyncReceived?.call(orders);
            } else if (type == 'NEW_ORDER' && data['order'] != null) {
              final order = PosOrder.fromJson(
                Map<String, dynamic>.from(data['order'] as Map),
              );
              onOrderReceivedOrUpdated?.call(order, isNew: true);
            } else if (type == 'ORDER_UPDATED' && data['order'] != null) {
              final order = PosOrder.fromJson(
                Map<String, dynamic>.from(data['order'] as Map),
              );
              onOrderReceivedOrUpdated?.call(order, isNew: false);
            }
          } catch (e) {
            debugPrint('Client WebSocket parse error: $e');
          }
        },
        onDone: () {
          _handleClientSocketClosed();
        },
        onError: (_) {
          _handleClientSocketClosed();
        },
      );

      return true;
    } catch (e) {
      debugPrint('Failed to connect to server $ip:$port -> $e');
      _isClientConnected = false;
      onStatusChanged?.call();
      _scheduleReconnect();
      return false;
    }
  }

  void _handleClientSocketClosed() {
    _isClientConnected = false;
    _heartbeatTimer?.cancel();
    _serverSocket = null;
    onStatusChanged?.call();
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_intentionalDisconnect || _connectedServerIp == null) return;
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_isClientConnected &&
          !_intentionalDisconnect &&
          _connectedServerIp != null) {
        connectToServer(_connectedServerIp!, port: _connectedServerPort);
      }
    });
  }

  Future<void> sendOrderUpdateFromClient(PosOrder updatedOrder) async {
    if (_serverSocket != null && _isClientConnected) {
      _safeSend(_serverSocket!, {
        'type': 'UPDATE_ORDER',
        'order': updatedOrder.toJson(),
      });
      return;
    }
    // Fallback via HTTP POST if WebSocket is reconnecting
    if (_connectedServerIp != null) {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 2);
      try {
        final req = await client.postUrl(
          Uri.parse(
              'http://$_connectedServerIp:$_connectedServerPort/order-update'),
        );
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({'order': updatedOrder.toJson()}));
        await req.close();
      } catch (_) {
      } finally {
        client.close(force: true);
      }
    }
  }

  void requestSyncFromServer() {
    if (_serverSocket != null && _isClientConnected) {
      _safeSend(_serverSocket!, {'type': 'REQUEST_SYNC'});
    }
  }

  Future<void> disconnectClient() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _isClientConnected = false;
    try {
      await _serverSocket?.close();
    } catch (_) {}
    _serverSocket = null;
    onStatusChanged?.call();
  }

  void _safeSend(WebSocket socket, Map<String, dynamic> payload) {
    try {
      socket.add(jsonEncode(payload));
    } catch (e) {
      debugPrint('Socket send error: $e');
    }
  }

  Future<void> dispose() async {
    await stopServer();
    await disconnectClient();
  }
}

