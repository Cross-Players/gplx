import 'package:flutter/material.dart';

class MemorizationTips extends StatelessWidget {
  const MemorizationTips({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mẹo cần ghi nhớ',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.blue[500],
      ),
      body: ListView(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 16),
        children: const [
          Text(
            'Mẹo 600 câu hỏi ôn thi GPLX',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          SectionWidget(
            title: 'Cấp phép',
            content: [
              Text('• Đường cấm dừng, cấm đỗ, cấm đi do UBND cấp tỉnh cấp'),
              Text(
                  '• Xe quá khổ, quá tải do: cơ quan quản lý đường bộ có thẩm quyền cấp phép'),
            ],
          ),
          SectionWidget(
            title: 'Nồng độ cồn',
            content: [
              Text(
                  'Người điều khiển xe mô tô, ô tô, máy kéo trên đường mà trong máu hoặc hơi thở có nồng độ cồn:'),
              Text(
                'Bị nghiêm cấm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SectionWidget(
            title: 'Khoảng cách an toàn tối thiểu',
            content: [
              Text('• 35m nếu vận tốc lưu hành(V) = 60 (km/h)'),
              Text('• 55m nếu 60<V≤80'),
              Text('• 70m nếu 80<V≤100'),
              Text('• 100m nếu 100<V≤120'),
              Text('• Dưới 60km/h: Chủ động và đảm bảo khoảng cách.'),
            ],
          ),
          SectionWidget(
            title: 'Hỏi về tuổi (T)',
            content: [
              Text('• Tuổi tối đa hạng E: nam 55, nữ 50'),
              Text('• Tuổi lấy bằng lái xe (cách nhau 3 tuổi)'),
              Text('   o Gắn máy: 16T (dưới 50cm3)'),
              Text('   o Mô tô + B1 + B2: 18T'),
              Text('   o C, FB: 21T'),
              Text('   o D, FC: 24T'),
              Text('   o E, FD: 27T'),
            ],
          ),
          SectionWidget(
            title:
                'Trên đường cao tốc, trong đường hầm, đường vòng, đầu dốc, nơi tầm nhìn hạn chế',
            content: [
              Text('• Không được quay đầu xe, không lùi, không vượt.'),
              Text('• Không được vượt trên cầu hẹp có một làn xe.'),
              Text(
                  '• Không được phép quay đầu xe ở phần đường dành cho người đi bộ qua đường.'),
              Text(
                  '• Cấm lùi xe ở khu vực cấm dừng và nơi đường bộ giao nhau.'),
            ],
          ),
          SectionWidget(
            title: 'Tại nơi giao nhau không có tín hiệu',
            content: [
              Text('• Có vòng xuyến: Nhường đường bên trái'),
              Text('• Không có vòng xuyến: Nhường bên phải'),
            ],
          ),
          SectionWidget(
            title: 'Niên hạn sử dụng (tính từ năm sx)',
            content: [
              Text('• 25 năm: ô tô tải'),
              Text('• 20 năm: ô tô chở người trên 9 chỗ'),
            ],
          ),
          SectionWidget(
            title: 'Biển báo cấm',
            content: [
              Text('Cấm ô tô (Gồm: mô tô 3 bánh, xe lam, xe khách) ->'),
              Text('Cấm xe tải —> Cấm Máy kéo —> Cấm rơ moóc, sơ mi rơ moóc'),
            ],
          ),
          SectionWidget(
            title: 'Nhất chớm, nhì ưu, tam đường, tứ hướng',
            content: [
              Text(
                  '1. Nhất chớm: Xe nào chớm tới vạch trước thì được đi trước.'),
              Text(
                  '2. Nhì ưu: Xe ưu tiên được đi trước. Thứ tự xe ưu tiên: Hỏa-Sự-An-Thương (Cứu hỏa - Quân sự - Công an - Cứu thương - Hộ đê - Đoàn xe tang).'),
              Text('3. Tam đường: Xe ở đường chính, đường ưu tiên.'),
              Text(
                  '4. Tứ hướng: Thứ tự hướng: Bên phải trống - Rẽ phải - Đi thẳng - Rẽ trái.'),
            ],
          ),
          SectionWidget(
            title: 'Thứ tự ưu tiên với xe ưu tiên: Hỏa-Sự-An-Thương',
            content: [
              Text('• Hỏa: Xe Cứu hỏa'),
              Text('• Sự: Xe Quân sự'),
              Text('• An: Xe Công an'),
              Text('• Thương: Xe cứu thương'),
              Text('• Xe hộ đê, xe đi làm nhiệm vụ khẩn cấp'),
              Text('• Đoàn xe tang'),
            ],
          ),
          SectionWidget(
            title: 'Các hạng GPLX',
            content: [
              Text('• A1 mô tô dưới 175 cm3 và xe 3 bánh của người khuyết tật'),
              Text('• A2 mô tô 175 cm3 trở lên'),
              Text('• A3 xe mô tô 3 bánh'),
              Text('• B1 không hành nghề lái xe'),
              Text('• B1, B2 đến 9 chỗ ngồi, xe tải dưới 3.500Kg'),
              Text('• C đến 9 chỗ ngồi, xe trên 3.500Kg'),
              Text('• D chở đến 30 người'),
              Text('• E chở trên 30 người.'),
              Text('• FC: C + kéo (ô tô đầu kéo, kéo sơ mi rơ moóc)'),
              Text('• FE: E + kéo (ô tô chở khách nối toa)'),
            ],
          ),
          SectionWidget(
            title: 'Phân nhóm biển báo hiệu: bao gồm',
            content: [
              Text('• Biển nguy hiểm (hình tam giác vàng)'),
              Text('• Biển cấm (vòng tròn đỏ)'),
              Text('• Biển hiệu lệnh (vòng tròn xanh)'),
              Text('• Biển chỉ dẫn (vuông hoặc hình chữ nhật xanh)'),
              Text(
                  '• Biển phụ (vuông, chữ nhật trắng đen): Hiệu lực năm ở biển phụ, khi có đặt biển phụ'),
            ],
          ),
          SectionWidget(
            title: 'Tốc độ tối đa TRONG khu vực đông dân cư',
            content: [
              Text(
                  '• 60km/h: Đối với đường đôi hoặc đường 1 chiều có từ 2 làn xe cơ giới trở lên'),
              Text(
                  '• 50km/h: Đối với đường 2 chiều hoặc đường 1 chiều có 1 làn xe cơ giới'),
            ],
          ),
          SectionWidget(
            title:
                'Tốc độ tối đa NGOÀI khu vực đông dân cư (trừ đường cao tốc)',
            content: [
              Text(
                  '1. Đổi với đường đôi hoặc đường 1 chiều có từ 2 làn xe cơ giới trở lên',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  '• 90km/h: Xe ô tô con, xe ô tô chở người đến 30 chỗ (trừ xe buýt), ô tô tải có trọng tải ≤3.5 tấn.'),
              Text(
                  '• 80km/h: Xe ô tô chở người trên 30 chỗ (trừ xe buýt), ô tô tải có trọng tải >3.5 tấn (trừ ô tô xitec).'),
              Text(
                  '• 70km/h: Ô tô buýt, ô tô đầu kéo kéo sơ mi rơ mooc, xe mô tô, ô tô chuyên dùng (trừ ô tô trộn vữa, trộn bê tông).'),
              Text(
                  '• 60km/h: Ô tô kéo rơ mooc, ô tô kéo xe khác, ô tô trộn vữa, ô tô trộn bê tông, ô tô xitec.'),
              Text(
                '2. Đối với đường 2 chiều hoặc đường 1 chiều có 1 làn xe cơ giới',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  '• 80km/h: Xe ô tô con, xe ô tô chở người đến 30 chỗ (trừ xe buýt), ô tô tải có trọng tải ≤3.5 tấn.'),
              Text(
                  '• 70km/h: Xe ô tô chở người trên 30 chỗ (trừ xe buýt), ô tô tải có trọng tải >3.5 tấn (trừ ô tô xitec).'),
              Text(
                  '• 60km/h: Ô tô buýt, ô tô đầu kéo kéo sơ mi rơ mooc, xe mô tô, ô tô chuyên dùng (trừ ô tô trộn vữa, trộn bê tông).'),
              Text(
                  '• 50km/h: Ô tô kéo rơ mooc, ô tô kéo xe khác, ô tô trộn vữa, ô tô trộn bê tông, ô tô xitec.'),
            ],
          ),
          SectionWidget(
            title: 'Tốc độ tối đa cho phép đối với',
            content: [
              Text(
                  '• Xe máy chuyên dùng, xe gắn máy (kể cả xe máy điện) và các loại xe tương tự trên đường bộ (trừ đường cao tốc): 40km/h'),
              Text(
                  '• Tốc độ tối đa cho phép của các loại xe cơ giới, xe máy chuyên dùng trên đường cao tốc phải tuân thủ tốc độ tối đa, tốc độ tối thiểu và không vượt quá: 120km/h'),
            ],
          ),
          SectionWidget(
            title: 'Tăng số, giảm số',
            content: [
              Text('• Tăng 1 Giảm 2 (giảm số chọn ý có từ "vù ga")'),
            ],
          ),
          SectionWidget(
            title: 'Phương tiện giao thông đường bộ',
            content: [
              Text(
                  'Bao gồm phương tiện giao thông cơ giới đường bộ và phương tiện giao thông thô sơ đường bộ'),
            ],
          ),
          SectionWidget(
            title: 'Phương tiện tham gia giao thông đường bộ',
            content: [
              Text('Gồm phương tiện giao thông đường bộ và xe máy chuyên dùng'),
            ],
          ),
          SectionWidget(
            title: 'Xe máy chuyên dùng',
            content: [
              Text(
                  'Gồm xe máy thi công, xe máy nông nghiệp, lâm nghiệp và các loại xe đặc chủng khác sử dụng vào mục đích quốc phòng, an ninh có tham gia giao thông đường bộ.'),
            ],
          ),
          SectionWidget(
            title: 'Hiệu lệnh người điều khiển giao thông',
            content: [
              Text(
                  '• Giơ tay thẳng đứng: Tất cả dừng, trừ xe đã ở trong ngã tư được phép đi'),
              Text('• Giang ngang tay: Tay phải đi, Trước sau dừng'),
              Text(
                  '• Tay phải giơ trước: Sau, phải dừng, trước rẽ phải, trái đi các hướng, người đi bộ qua đường đi sau người điều khiển.'),
            ],
          ),
          SectionWidget(
            title: 'Khái niệm và quy tắc',
            content: [
              Text(
                  '• Tất cả các câu có đáp án bị nghiêm cấm, không cho phép hoặc không được phép thì chọn đáp án đó.'),
              Text('• Tốc độ chậm đi về bên phải.'),
              Text('• Chỉ sử dụng còi từ 5 giờ sáng đến 22 giờ tối.'),
              Text('• Trong đô thị sử dụng đèn chiếu gần.'),
              Text(
                  '• Không được phép lắp đặt còi đến không đúng thiết kế, trừ phi được chấp thuận của cơ quan có thẩm quyền.'),
              Text('• Xe mô tô không được kéo xe khác.'),
              Text(
                  '• 05 năm không cấp lại nếu sử dụng bằng lái đã khai báo mất.'),
              Text('• Chuyển làn đường phải có tín hiệu báo trước.'),
              Text('• Xe thô sơ phải đi làn đường bên phải trong cùng.'),
              Text(
                  '• Tránh xe ngược chiều thì nhường đường qua đường hẹp và nhường xe lên dốc.'),
              Text('• Đừng cách ray đường sắt 5m.'),
              Text(
                  '• Vào cao tốc phải nhường đường cho xe đang chạy trên đường.'),
              Text('• Xe thiết kế nhỏ hơn 70km/h không được vào cao tốc.'),
              Text('• Trên cao tốc chỉ được dừng xe, đỗ xe ở nơi quy định.'),
              Text('• Trong hầm chỉ được dừng xe, đỗ xe ở nơi quy định.'),
              Text(
                  '• Xe quá tải trọng phải do cơ quan quản lý đường bộ cấp phép.'),
              Text('• Trong lượng xe kéo rơ moóc phải lớn hơn rơ moóc.'),
              Text('• Kéo xe trong hệ thống hãm phải dùng thanh nối cứng.'),
              Text('• Xe gắn máy tối đa 40km/h.'),
              Text('• Xe có giới không bao gồm xe gắn máy.'),
              Text('• Đường có giải phân cách được xem là đường đôi.'),
              Text('• Giảm tốc độ, chú ý quan sát khi gặp biển báo nguy hiểm.'),
              Text('• Giảm tốc độ, đi sát về bên phải khi xe sau xin vượt.'),
              Text('• Điểm giao cắt đường sắt thì ưu tiên đường sắt.'),
              Text('• Nhường đường cho xe ưu tiên có tín hiệu còi, cờ, đèn.'),
              Text('• Không vượt xe khác trên đường vòng, khuất tầm nhìn.'),
              Text(
                  '• Nơi có vạch kẻ đường dành cho người đi bộ thì nhường đường.'),
              Text(
                  '• Dừng xe, đổ xe cách lề đường, hè phố không quá 0,25 mét.'),
              Text('• Dừng xe, đổ xe trên đường hẹp cách xe khác 20 mét.'),
              Text('• Giảm tốc độ trên đường ướt, đường hẹp và đèo dốc.'),
              Text(
                  '• Xe buýt đang dừng đón trả khách thì giảm tốc độ và từ từ vượt qua xe buýt.'),
            ],
          ),
          SectionWidget(
            title: 'Nghiệp vụ vận tải',
            content: [
              Text('• Không lái xe liên tục quá 4 giờ.'),
              Text('• Không làm việc 1 ngày của lái xe quá 10 giờ.'),
              Text(
                  '• Người kinh doanh vận tải không được tự ý thay đổi vị trí đón trả khách.'),
              Text('• Vận chuyển hàng nguy hiểm phải có giấy phép.'),
            ],
          ),
          SectionWidget(
            title: 'Kỹ thuật lái xe',
            content: [
              Text(
                  '• Xe mô tô xuống dốc dài cần sử dụng cả phanh trước và phanh sau để giảm tốc độ.'),
              Text(
                  '• Khởi hành xe ô tô số tự động cần đạp phanh chân hết hành trình.'),
              Text(
                  '• Thực hiện phanh tay cần phải bóp khóa hãm đẩy cần phanh tay về phía trước.'),
              Text('• Khởi hành ô tô sử dụng hộp số đạp côn hết hành trình.'),
              Text('• Thực hiện quay đầu xe với tốc độ thấp.'),
              Text(
                  '• Lái xe ô tô qua đường sắt không rào chắn thì cách 5 mét hạ kính cửa, tắt âm thanh, quan sát.'),
              Text('• Mở cửa xe thì quan sát rồi mới mở hé cánh cửa.'),
            ],
          ),
          SectionWidget(
            title: 'Cấu tạo và sửa chữa',
            content: [
              Text('• Yêu cầu cửa kính chắn gió, chọn “Loại kính an toàn”.'),
              Text('• Âm lượng của còi là từ 90dB đến 115 dB.'),
              Text('• Động cơ diesel không nổ do nhiên liệu lẫn tạp chất.'),
              Text(
                  '• Dây đai an toàn có cơ cấu hãm giữ chặt dây khi giật dây đột ngột.'),
              Text('• Động cơ 4 kỳ thì pít tông thực hiện 4 hành trình.'),
              Text('• Hệ thống bôi trơn giảm ma sát.'),
              Text('• Niền hạn ô tô trên 9 chỗ ngồi là 20 năm.'),
              Text('• Niên hạn ô tô tải là 25 năm.'),
              Text('• Động cơ ô tô biến nhiệt năng thành cơ năng.'),
              Text(
                  '• Hệ thống truyền lực truyền mô men quay từ động cơ tới bánh xe.'),
              Text(
                  '• Ly hợp (côn) truyền hoặc ngắt truyền động từ động cơ đến hộp số.'),
              Text('• Hộp số ô tô đảm bảo chuyển động lùi.'),
              Text('• Hệ thống lái dùng để thay đổi hướng.'),
              Text('• Hệ thống phanh giúp giảm tốc độ.'),
              Text('• Ắc quy để tích trữ điện năng.'),
              Text('• Khởi động xe tự động phải đạp phanh.'),
            ],
          ),
          SectionWidget(
            title: 'Các quy tắc sa hình khác',
            content: [
              Text(
                  '• Thứ tự ưu tiên không vòng xuyến: Xe vào ngã ba, ngã tư trước - Xe ưu tiên - Đường ưu tiên - Đường cùng cấp theo thứ tự bên phải trống - rẽ phải - đi thẳng - rẽ trái.'),
              Text(
                  '• Giao nhau cùng cấp có vòng xuyến: Chưa vào vòng xuyến thì ưu tiên xe bên phải, đã vào vòng xuyến ưu tiên xe từ bên trái tới.'),
              Text('• Xe xuống dốc phải nhường đường cho xe đang lên dốc'),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionWidget extends StatelessWidget {
  final String title;
  final List<Widget> content;

  const SectionWidget({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 8.0),
          ...content.map((line) => Padding(
                padding: const EdgeInsets.only(left: 15, bottom: 5),
                child: line is Text
                    ? Text(
                        (line).data!,
                        textAlign: TextAlign.justify,
                        style: (line).style?.copyWith(
                                  height: 1.5,
                                  fontSize: 14,
                                ) ??
                            const TextStyle(
                              height: 1.5,
                              fontSize: 14,
                            ),
                      )
                    : line,
              )),
        ],
      ),
    );
  }
}
