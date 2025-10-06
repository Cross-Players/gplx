import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/widgets/primary_button.dart';
import 'package:gplx/features/signs/domain/models/traffic_sign.dart';

class TrafficSignsScreen extends StatefulWidget {
  const TrafficSignsScreen({super.key});

  @override
  State<TrafficSignsScreen> createState() => _TrafficSignsScreenState();
}

class _TrafficSignsScreenState extends State<TrafficSignsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<TrafficSign> _signs = [
    const TrafficSign(
      code: '101',
      name: 'Đường cấm',
      description: 'Cấm tất cả các loại phương tiện đi lại cả hai hướng',
      imageUrl: 'assets/images/signs/101.png',
      type: SignType.prohibitory,
    ),
    const TrafficSign(
      code: '106c',
      name: 'Cấm ô tô tải chở hàng nguy hiểm',
      description: 'Cấm ô tô tải chở hàng nguy hiểm',
      imageUrl: 'assets/images/signs/101.png',
      type: SignType.prohibitory,
    ),
    const TrafficSign(
      code: '107',
      name: 'Cấm ô tô khách và ô tô tải',
      description: 'Cấm ô tô khách và ô tô tải',
      imageUrl: 'assets/images/signs/101.png',
      type: SignType.prohibitory,
    ),
    const TrafficSign(
      code: '107a',
      name: 'Cấm ô tô khách',
      description: 'Cấm ô tô khách',
      imageUrl: 'assets/images/signs/101.png',
      type: SignType.prohibitory,
    ),
    const TrafficSign(
      code: '107b',
      name: 'Cấm xe taxi',
      description: 'Cấm xe taxi',
      imageUrl: 'assets/images/signs/101.png',
      type: SignType.prohibitory,
    ),
    const TrafficSign(
      code: '108',
      name: 'Cấm ôtô kéo rơ móc',
      description: 'Cấm ôtô kéo rơ móc',
      imageUrl: 'assets/images/signs/101.png',
      type: SignType.prohibitory,
    ),
  ];

  List<TrafficSign> _getFilteredSigns(SignType type) {
    return _signs.where((sign) => sign.type == type).toList();
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
      case SignType.temporary:
        return 'Vạch Kẻ Đường';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                final signs = _getFilteredSigns(type);
                return Column(
                  children: [
                    Expanded(
                      child: signs.isEmpty
                          ? const Center(
                              child: Text(
                                  'Không có biển báo nào trong danh mục này'))
                          : ListView.builder(
                              itemCount: signs.length,
                              itemBuilder: (context, index) {
                                final sign = signs[index];
                                return _SignListItem(sign: sign);
                              },
                            ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignListItem extends StatelessWidget {
  final TrafficSign sign;

  const _SignListItem({required this.sign});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.all(AppStyles.horizontalSpace),
          leading: Image.asset(
            sign.imageUrl,
            width: 48,
            height: 48,
          ),
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${sign.code}\n',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(46, 93, 137, 1),
                  ),
                ),
                TextSpan(
                  text: sign.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          onTap: () => showCustomModalBottomSheet(context, sign),
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppStyles.horizontalSpace),
          child: Divider(
            height: 1,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}

void showCustomModalBottomSheet(
  BuildContext context,
  TrafficSign sign,
) {
  showModalBottomSheet(
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppStyles.buttonRadiusM)),
    ),
    backgroundColor: Colors.white,
    context: context,
    enableDrag: true,
    showDragHandle: true,
    isScrollControlled: true, // Allows the modal to be larger
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sign code and close button
            Text(
              'Biển báo ${sign.code}',
              style: AppStyles.textBold.copyWith(
                fontSize: 18,
              ),
            ),
            // Sign name
            Text(
              sign.name,
              style: const TextStyle(
                  fontSize: 18, color: AppStyles.fontSecondaryColor),
            ),
            // Sign image
            Center(
              child: Container(
                width: 150,
                height: 150,
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Image.asset(
                  sign.imageUrl,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              sign.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            // Close button
            PrimaryButton(
              content: "Đóng",
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      );
    },
  );
}
