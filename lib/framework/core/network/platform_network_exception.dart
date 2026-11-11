import 'package:kawula_pos/framework/core/network/platform_network_exception_stub.dart'
    if (dart.library.io) 'package:kawula_pos/framework/core/network/platform_network_exception_io.dart'
    as platform;

bool isPlatformNetworkException(Object error) =>
    platform.isPlatformNetworkException(error);
