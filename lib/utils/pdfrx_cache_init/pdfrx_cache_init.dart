// Conditional export: use IO implementation except when compiling for web (html).
export 'pdfrx_cache_init_io.dart'
    if (dart.library.html) 'pdfrx_cache_init_web.dart';
