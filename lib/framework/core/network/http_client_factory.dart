import 'package:http/http.dart' as http;

import 'package:kawula_pos/framework/core/network/http_client_factory_web.dart'
    if (dart.library.io) 'package:kawula_pos/framework/core/network/http_client_factory_io.dart'
    as platform;

http.Client createPlatformHttpClient({
  Duration connectionTimeout = const Duration(seconds: 15),
}) => platform.createPlatformHttpClient(connectionTimeout: connectionTimeout);
