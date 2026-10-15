import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:gplx/core/constants/app_styles.dart';
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
        return Icons.block_rounded;
      case SignType.warning:
        return Icons.warning_amber_rounded;
      case SignType.mandatory:
        return Icons.arrow_circle_right_rounded;
      case SignType.information:
        return Icons.info_rounded;
      case SignType.direction:
        return Icons.signpost_rounded;
    }
  }

  Color _getColor(SignType type) {
    switch (type) {
      case SignType.prohibitory:
        return const Color(0xFFDC2626);
      case SignType.warning:
        return const Color(0xFFD97706);
      case SignType.mandatory:
        return const Color(0xFF2563EB);
      case SignType.information:
        return const Color(0xFF059669);
      case SignType.direction:
        return const Color(0xFF7C3AED);
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
      appBar: const GradientAppBar(
        title: Text('Biển báo giao thông'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
              itemCount: SignType.values.length,
              itemBuilder: (context, index) {
                final type = SignType.values[index];
                final color = _getColor(type);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: AppPalette.surface,
                    borderRadius: BorderRadius.circular(AppPalette.radiusL),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppPalette.radiusL),
                      onTap: () => _openPdfViewer(type),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppPalette.radiusL),
                          border: Border.all(color: AppPalette.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color.withValues(alpha: 0.85),
                                    color,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: AppPalette.softShadow(color),
                              ),
                              child: Icon(
                                _getIcon(type),
                                color: Colors.white,
                                size: 28,
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppPalette.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _getDescription(type),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppPalette.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppPalette.background,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppPalette.inkMuted,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
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
