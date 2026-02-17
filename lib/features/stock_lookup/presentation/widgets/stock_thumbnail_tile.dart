import 'package:flutter/material.dart';
import 'package:rmstock_scanner/constants/images.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';

class StockThumbnailTile extends StatefulWidget {
  final StockVO stock;

  const StockThumbnailTile({super.key, required this.stock});

  @override
  State<StockThumbnailTile> createState() => _StockThumbnailTileState();
}

class _ThumbnailRequestConfig {
  final int port;
  final String apiKey;

  const _ThumbnailRequestConfig({required this.port, required this.apiKey});
}

class _StockThumbnailTileState extends State<StockThumbnailTile> {
  static Future<_ThumbnailRequestConfig>? _configFuture;

  Future<_ThumbnailRequestConfig> _loadConfig() async {
    final int port =
        int.tryParse((await LocalDbDAO.instance.getHostPort() ?? "").trim()) ??
        5000;
    final String apiKey = (await LocalDbDAO.instance.getApiKey() ?? "").trim();
    return _ThumbnailRequestConfig(port: port, apiKey: apiKey);
  }

  String? _buildThumbnailUrl(int port) {
    final String? rawPath = widget.stock.imageUrl;
    if (rawPath == null || rawPath.trim().isEmpty) {
      return null;
    }

    String normalizedPath = rawPath;
    if (!normalizedPath.endsWith("/thumbnail")) {
      normalizedPath = "$normalizedPath/thumbnail";
    }

    if (normalizedPath.startsWith("http://") ||
        normalizedPath.startsWith("https://")) {
      return normalizedPath;
    }

    final host = (AppGlobals.instance.currentHostIp ?? "")
        .trim()
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/$'), '');
    if (host.isEmpty) {
      return null;
    }

    final absolutePath = normalizedPath.startsWith("/")
        ? normalizedPath
        : "/$normalizedPath";
    return "http://$host:$port$absolutePath";
  }

  @override
  Widget build(BuildContext context) {
    _configFuture ??= _loadConfig();

    return FutureBuilder<_ThumbnailRequestConfig>(
      future: _configFuture,
      builder: (context, snapshot) {
        final config = snapshot.data;
        final String? imageUrl = _buildThumbnailUrl(config?.port ?? 5000);

        if (imageUrl == null || imageUrl.isEmpty) {
          return Image.asset(overviewPlaceholder, fit: BoxFit.fill);
        }

        final headers = <String, String>{};
        final apiKey = config?.apiKey ?? "";
        if (apiKey.isNotEmpty) {
          headers["x-api-key"] = apiKey;
        }

        return Image.network(
          imageUrl,
          fit: BoxFit.fill,
          headers: headers.isEmpty ? null : headers,
          errorBuilder: (_, _, _) =>
              Image.asset(overviewPlaceholder, fit: BoxFit.fill),
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Image.asset(overviewPlaceholder, fit: BoxFit.fill);
          },
        );
      },
    );
  }
}
