import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:gplx/core/widgets/gradient_app_bar.dart';
import 'package:gplx/features/signs/domain/models/traffic_sign.dart';
import 'package:path_provider/path_provider.dart';

class TrafficSignsScreen extends StatefulWidget {
  const TrafficSignsScreen({super.key});

  @override
  State<TrafficSignsScreen> createState() => _TrafficSignsScreenState();
}

class _TrafficSignsScreenState extends State<TrafficSignsScreen> {
  final Map<SignType, String?> _pdfPaths = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfFiles();
  }

  Future<void> _loadPdfFiles() async {
    final pdfMap = {
      SignType.prohibitory: 'bien_bao_cam.pdf',
      SignType.mandatory: 'bien_bao_hieu_lenh.pdf',
      SignType.warning: 'bien_bao_nguy_hiem_va_canh_bao.pdf',
      SignType.information: 'bien_bao_chi_dan.pdf',
      SignType.direction: 'bien_bao_phu.pdf',
    };

    for (var entry in pdfMap.entries) {
      try {
        final path = await _loadPdfFromAssets('assets/pdf/${entry.value}');
        _pdfPaths[entry.key] = path;
      } catch (e) {
        debugPrint('Error loading ${entry.value}: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _loadPdfFromAssets(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }

  String _getTitle(SignType type) {
    switch (type) {
      case SignType.prohibitory:
        return 'Biển Báo Cấm';
      case SignType.warning:
        return 'Biển Báo Nguy Hiểm';
      case SignType.mandatory:
        return 'Biển Báo Hiệu Lệnh';
      case SignType.information:
        return 'Biển Báo Chỉ Dẫn';
      case SignType.direction:
        return 'Biển Báo Phụ';
    }
  }

  String _getDescription(SignType type) {
    switch (type) {
      case SignType.prohibitory:
        return 'Các biển báo cấm và hạn chế';
      case SignType.warning:
        return 'Các biển báo nguy hiểm và cảnh báo';
      case SignType.mandatory:
        return 'Các biển báo hiệu lệnh';
      case SignType.information:
        return 'Các biển báo chỉ dẫn';
      case SignType.direction:
        return 'Các biển báo phụ';
    }
  }

  IconData _getIcon(SignType type) {
    switch (type) {
      case SignType.prohibitory:
        return Icons.block;
      case SignType.warning:
        return Icons.warning_amber_rounded;
      case SignType.mandatory:
        return Icons.arrow_circle_right;
      case SignType.information:
        return Icons.info_outline;
      case SignType.direction:
        return Icons.signpost;
    }
  }

  Color _getColor(SignType type) {
    switch (type) {
      case SignType.prohibitory:
        return Colors.red;
      case SignType.warning:
        return Colors.orange;
      case SignType.mandatory:
        return Colors.blue;
      case SignType.information:
        return Colors.green;
      case SignType.direction:
        return Colors.purple;
    }
  }

  void _openPdfViewer(SignType type) {
    final pdfPath = _pdfPaths[type];
    if (pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy file PDF')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PdfViewerScreen(
          title: _getTitle(type),
          pdfPath: pdfPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Biển báo giao thông'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: SignType.values.length,
              itemBuilder: (context, index) {
                final type = SignType.values[index];
                final color = _getColor(type);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openPdfViewer(type),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIcon(type),
                              color: color,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTitle(type),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getDescription(type),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Separate PDF Viewer Screen
class _PdfViewerScreen extends StatelessWidget {
  final String title;
  final String pdfPath;

  const _PdfViewerScreen({
    required this.title,
    required this.pdfPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title),
      ),
      body: PDFView(
        filePath: pdfPath,
        enableSwipe: true,
        swipeHorizontal: false,
        pageFling: false,
        pageSnap: false,
        autoSpacing: Platform.isAndroid ? false : true,
        defaultPage: 0,
        fitPolicy: FitPolicy.WIDTH,
        fitEachPage: true,
        preventLinkNavigation: false,
        onError: (error) {
          debugPrint('PDF Error: $error');
        },
        onPageError: (page, error) {
          debugPrint('Page $page Error: $error');
        },
        onPageChanged: (page, total) {
          debugPrint('Page $page of $total');
        },
      ),
    );
  }
}
