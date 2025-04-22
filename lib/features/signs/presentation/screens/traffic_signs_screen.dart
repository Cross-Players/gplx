import 'package:flutter/material.dart';
import 'package:gplx/features/signs/domain/models/traffic_sign.dart';

class TrafficSignsScreen extends StatefulWidget {
  const TrafficSignsScreen({super.key});

  @override
  State<TrafficSignsScreen> createState() => _TrafficSignsScreenState();
}

class _TrafficSignsScreenState extends State<TrafficSignsScreen> {
  final SignType _selectedType = SignType.prohibitory;

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

  List<TrafficSign> get _filteredSigns {
    return _signs.where((sign) => sign.type == _selectedType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Biển báo giao thông'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: const Text(
              'BIỂN BÁO CẤM',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredSigns.length,
              itemBuilder: (context, index) {
                final sign = _filteredSigns[index];
                return _SignListItem(sign: sign);
              },
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
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
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
                color: Colors.blue,
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
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          sign.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
