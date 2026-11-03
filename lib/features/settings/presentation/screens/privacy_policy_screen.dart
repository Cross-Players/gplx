import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/widgets/gradient_app_bar.dart';

/// Màn hình hiển thị Chính sách bảo mật (Privacy Policy) bằng tiếng Việt,
/// đáp ứng yêu cầu của Google Play: phải có liên kết hoặc văn bản chính sách
/// bảo mật bên trong ứng dụng.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: const Text('Chính sách bảo mật'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: SelectableText(
          _policyText,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.55,
            color: AppPalette.ink,
          ),
        ),
      ),
    );
  }
}

const String _policyText = '''
CHÍNH SÁCH BẢO MẬT — ỨNG DỤNG HỌC GPLX VẠN XUÂN
Cập nhật lần cuối: 02/11/2026

Ứng dụng "Học GPLX Vạn Xuân" là công cụ ôn thi lý thuyết giấy phép lái xe hạng A1, B1. Chúng tôi cam kết bảo vệ dữ liệu của người dùng theo các nguyên tắc dưới đây.

1. DỮ LIỆU THU THẬP
- Tài khoản ẩn danh: Ứng dụng đăng nhập bằng tính năng "khách" (anonymous sign-in) của Firebase Authentication để xác thực. Ứng dụng KHÔNG yêu cầu hoặc lưu tên, email, số điện thoại hay bất kỳ thông tin định danh cá nhân nào.
- Dữ liệu học tập: Ứng dụng KHÔNG ghi dữ liệu học tập của bạn lên bất kỳ cơ sở dữ liệu nào. Toàn bộ đề thi được đọc (chỉ đọc) từ Firebase Realtime Database để hiển thị; không có dữ liệu nào của bạn được gửi lên máy chủ.
- Cài đặt và tiến độ trên thiết bị: Ứng dụng lưu cục bộ (SharedPreferences) các dữ liệu không định danh gồm thời điểm hết hạn bộ nhớ đệm, hạng xe bạn chọn, tiến độ làm bài ôn tập/thi thử, và bộ đếm thời gian sử dụng ứng dụng để điều phối tần suất hiển thị quảng cáo. Không có dữ liệu cá nhân nào được lưu.

2. MỤC ĐÍCH
Dữ liệu được sử dụng duy nhất để cung cấp dịch vụ: hiển thị đề thi, lưu lựa chọn loại xe và quản lý bộ nhớ đệm. Chúng tôi KHÔNG bán, cho thuê, hay chia sẻ dữ liệu với bên thứ ba vì mục đích tiếp thị.

3. BÊN THỨ BA
Ứng dụng sử dụng Firebase (Google) làm nền tảng backend để tải đề thi. Firebase có thể xử lý một số dữ liệu kỹ thuật theo chính sách bảo mật của Google tại https://policies.google.com/privacy. Việc sử dụng Firebase bị giới hạn ở việc đọc đề thi; không có dữ liệu cá nhân nào được truyền đi.

4. QUẢNG CÁO (GOOGLE ADMOB)
Ứng dụng hiển thị quảng cáo thông qua Google AdMob. AdMob có thể thu thập Advertising ID (mã định danh quảng cáo) và một số định danh thiết bị để chọn và đo lường quảng cáo. Quảng cáo có thể được cá nhân hoá dựa trên dữ liệu này, hoặc chỉ hiển thị ở dạng không cá nhân hoá nếu bạn không đồng ý. Bạn có thể đặt lại hoặc tắt cá nhân hoá quảng cáo trong phần Cài đặt của thiết bị (Google → Quảng cáo). Người dùng ở khu vực EEA/UK sẽ được hỏi ý kiến đồng ý theo GDPR ngay trong ứng dụng; nếu từ chối, ứng dụng vẫn hoạt động bình thường. Chúng tôi không bán dữ liệu của bạn cho bên thứ ba.

5. LƯU TRỮ VÀ XOÁ
Dữ liệu được lưu trên thiết bị của bạn. Bạn có thể xóa tất cả dữ liệu cài đặt bất kỳ lúc nào bằng cách xóa bộ nhớ đệm trong phần "Thiết lập". Khi ứng dụng bị gỡ, tất cả dữ liệu local bị xóa theo đó.

6. TRẺ EM
Ứng dụng không hướng đến trẻ em dưới 16 tuổi và không thu thập dữ liệu từ trẻ em.

7. LIÊN HỆ
Nếu có thắc mắc về chính sách bảo mật, vui lòng liên hệ qua địa chỉ email của nhà phát triển được ghi trên trang ứng dụng tại Google Play. Ứng dụng không cung cấp biểu mẫu liên hệ và không thu thập địa chỉ email nào trong ứng dụng.

Chúng tôi có thể cập nhật chính sách này. Việc tiếp tục sử dụng ứng dụng sau khi có bản cập nhật được coi là bạn đã chấp nhận chính sách mới.
''';
