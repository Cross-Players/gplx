import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gplx/core/widgets/gradient_app_bar.dart';
import 'package:gplx/features/signs/domain/models/traffic_sign.dart';
import 'package:microsoft_viewer/microsoft_viewer.dart';
import 'package:path_provider/path_provider.dart';

class TrafficSignsScreen extends StatefulWidget {
  const TrafficSignsScreen({super.key});

  @override
  State<TrafficSignsScreen> createState() => _TrafficSignsScreenState();
}

class _TrafficSignsScreenState extends State<TrafficSignsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<SignType, File?> _docxFiles = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: SignType.values.length, vsync: this);
    _loadDocxFiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocxFiles() async {
    final docxMap = {
      SignType.prohibitory: 'bien_bao_cam.docx',
      SignType.mandatory: 'bien_bao_hieu_lenh.docx',
      SignType.warning: 'bien_bao_nguy_hiem_va_canh_bao.docx',
      SignType.information: 'bien_bao_chi_dan.docx',
      SignType.direction: 'bien_bao_phu.docx',
    };

    for (var entry in docxMap.entries) {
      try {
        final file = await _loadAssetFile('assets/docs/${entry.value}');
        _docxFiles[entry.key] = file;
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

  Future<File> _loadAssetFile(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  String _getTabTitle(SignType type) {
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
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorWeight: 3,
            tabs: SignType.values
                .map((type) => Tab(
                      text: _getTabTitle(type),
                    ))
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: SignType.values.map((type) {
                final docxFile = _docxFiles[type];

                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (docxFile == null) {
                  return const Center(
                    child: Text(
                        'Không tìm thấy file tài liệu cho loại biển báo này'),
                  );
                }

                return FutureBuilder<Uint8List>(
                  future: docxFile.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(
                        child: Text('Lỗi khi tải tài liệu: ${snapshot.error}'),
                      );
                    }

                    return MicrosoftViewer(snapshot.data!);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
