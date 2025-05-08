// import 'package:gplx/features/test/models/question.dart';
// import 'package:gplx/generated/assets.gen.dart';

// // Change from private (_question) to public (questions)
// final List<Question> questions = [
//   const Question(
//     questionTitle:
//         'Đường mà trên đó phương tiên tham gia giao thông được các phương tiện giao thông đến từ hướng khác nhường đường khi qua nơi đường giao nhau, được cắm biển báo hiệu đường ưu tiên là loại đường gì?',
//     options: [
//       'Đường không ưu tiên.',
//       'Đường tỉnh lộ.',
//       'Đường quốc lộ.',
//       'Đường ưu tiên',
//     ],
//     correctOptionIndex: 3,
//   ),
//   const Question(
//     questionTitle:
//         'Khi gặp hiệu lệnh của cảnh sát giao thông thì người tham gia giao thông phải làm gì?',
//     options: [
//       'Chấp hành hiệu lệnh của người điều khiển giao thông.',
//       'Chấp hành theo đèn tín hiệu giao thông.',
//       'Chấp hành theo biển báo hiệu đường bộ.',
//       'Không phải chấp hành hiệu lệnh của người điều khiển giao thông.',
//     ],
//     correctOptionIndex: 0,
//   ),
//   const Question(
//     questionTitle:
//         'Trên đường có nhiều làn đường cho xe đi cùng chiều được phân biệt bằng vạch kẻ đường, người điều khiển phương tiện phải cho xe đi như thế nào?',
//     options: [
//       'Cho xe đi trên bất kỳ làn đường nào.',
//       'Cho xe đi trên làn đường có ít phương tiện đang đi.',
//       'Cho xe đi trên làn đường bên phải.',
//       'Cho xe đi trên làn đường phù hợp với tốc độ đang đi.',
//     ],
//     correctOptionIndex: 3,
//   ),
//   const Question(
//     questionTitle:
//         'Ở phần đường dành cho người đi bộ trên đường, khi đi dọc đường người đi bộ phải đi như thế nào?',
//     options: [
//       'Đi ở lề đường và phải đi một hàng.',
//       'Đi ở lề đường và đi được hai hàng.',
//       'Đi ở lòng đường và đi một hàng.',
//       'Đi ở lòng đường và đi nhiều hàng.',
//     ],
//     correctOptionIndex: 0,
//   ),
//   const Question(
//     questionTitle:
//         'Người điều khiển phương tiện khi đi qua đường bộ giao nhau với đường sắt thì phải như thế nào?',
//     options: [
//       'Quan sát cả hai phía, khi thấy chắn tàu đóng phải nhanh chóng kịp qua đường ngang.',
//       'Khi thấy chắn tàu đang dịch chuyển, phải nhanh chóng tăng tốc kịp qua đường ngang.',
//       'Giảm tốc độ, quan sát cả hai phía, khi có chắn tàu thì chỉ vượt qua khi chắn tàu mở.',
//       'Nếu thấy đèn đỏ gần đường ngang đã bật sáng thì được qua đường.',
//     ],
//     correctOptionIndex: 2,
//   ),
//   const Question(
//     questionTitle:
//         'Tại nơi đường giao nhau, người lái xe phải làm gì khi quan sát thấy người đi bộ đang đi trên phần đường dành cho người đi bộ?',
//     options: [
//       'Giảm tốc độ và nhường đường.',
//       'Bấm còi, nháy đèn báo hiệu và đi tiếp.',
//       'Dừng lại chờ người đi bộ qua hết phần đường dành cho người đi bộ.',
//       'Tăng tốc để nhanh chóng qua đường giao nhau.',
//     ],
//     correctOptionIndex: 0,
//   ),
//   const Question(
//     questionTitle:
//         'Khi điều khiển phương tiện tham gia giao thông đường bộ, người lái xe phải sử dụng đèn như thế nào?',
//     options: [
//       'Từ 19 giờ đến 5 giờ sáng hôm sau phải bật đèn chiếu xa.',
//       'Ban ngày chỉ bật đèn trong hầm đường bộ.',
//       'Từ 19 giờ đến 5 giờ sáng hôm sau phải bật đèn chiếu sáng gần hoặc xa.',
//       'Khi đỗ xe ban đêm trên đường phố cần bật đèn chiếu sáng xa.',
//     ],
//     correctOptionIndex: 2,
//   ),
//   Question(
//     questionTitle:
//         'Hiệu lệnh nào người lái xe phải dừng lại trước vạch dừng và những nơi quy định không được vượt qua?',
//     options: [
//       'Khi người điều khiển giao thông giơ tay thẳng đứng.',
//       'Khi người điều khiển giao thông đưa tay duỗi ra giơ lên cao.',
//       'Khi người điều khiển giao thông giang hai tay ngang.',
//       'Khi người điều khiển giao thông tay giơ cao, tay kia giơ ngang.',
//     ],
//     correctOptionIndex: 0,
//     imageUrl: Assets.images.signs.a101.keyName,
//   ),
//   const Question(
//     questionTitle:
//         'Khi muốn chuyển hướng, người lái xe phải thực hiện như thế nào?',
//     options: [
//       'Phải quan sát, có tín hiệu báo hướng rẽ và đảm bảo an toàn.',
//       'Bật đèn chiếu sáng xa về hướng sẽ rẽ.',
//       'Tăng tốc độ và đánh lái thật nhanh.',
//       'Không cần bật tín hiệu xin đường khi đường vắng.',
//     ],
//     correctOptionIndex: 0,
//   ),
//   const Question(
//     questionTitle:
//         'Khi gặp xe buýt đang đón, trả khách tại nơi quy định, người điều khiển phương tiện phải làm thế nào?',
//     options: [
//       'Tăng tốc độ vượt qua xe buýt.',
//       'Giảm tốc độ và từ từ đi qua, đảm bảo an toàn cho hành khách.',
//       'Nhanh chóng lách qua các phương tiện dừng đỗ để tiếp tục di chuyển.',
//       'Bấm còi liên tục để cảnh báo hành khách.',
//     ],
//     correctOptionIndex: 1,
//   ),
//   const Question(
//     questionTitle:
//         'Tốc độ tối đa cho phép trong khu vực đông dân cư đối với xe mô tô hai bánh, xe gắn máy là bao nhiêu?',
//     options: [
//       '60 km/h.',
//       '50 km/h.',
//       '40 km/h.',
//       '30 km/h.',
//     ],
//     correctOptionIndex: 2,
//   ),
//   Question(
//     questionTitle:
//         'Biển báo nào sau đây báo hiệu nguy hiểm giao nhau với đường sắt có rào chắn?',
//     options: [
//       'Biển 1.',
//       'Biển 2.',
//       'Biển 3.',
//       'Biển 4.',
//     ],
//     correctOptionIndex: 0,
//     imageUrl: Assets.images.signs.a101.keyName,
//   ),
//   const Question(
//     questionTitle:
//         'Người điều khiển phương tiện tham gia giao thông trong hầm đường bộ ngoài việc phải tuân thủ các quy tắc giao thông còn phải thực hiện những quy định nào dưới đây?',
//     options: [
//       'Xe cơ giới phải bật đèn chiếu sáng xa.',
//       'Xe cơ giới phải bật đèn; xe thô sơ phải có báo hiệu để người khác nhìn thấy.',
//       'Xe máy phải bật đèn chiếu sáng xa, xe thô sơ phải có báo hiệu bằng ánh sáng.',
//       'Tất cả các phương tiện đều phải bật đèn cảnh báo nguy hiểm.',
//     ],
//     correctOptionIndex: 1,
//   ),
//   const Question(
//     questionTitle:
//         'Khi điều khiển xe mô tô hai bánh, xe mô tô ba bánh, xe gắn máy, những hành vi nào không được phép?',
//     options: [
//       'Sử dụng đèn chiếu xa trong đô thị, khu đông dân cư.',
//       'Sử dụng còi từ 5 giờ đến 22 giờ.',
//       'Sử dụng thiết bị âm thanh từ 22 giờ đến 5 giờ sáng.',
//       'Chở người ngồi trên xe đúng quy định.',
//     ],
//     correctOptionIndex: 2,
//   ),
//   const Question(
//     questionTitle:
//         'Trong các hành vi dưới đây, người lái xe không bị nghiêm cấm hành vi nào?',
//     options: [
//       'Lùi xe trên đường một chiều.',
//       'Sử dụng đèn tín hiệu theo đúng quy định.',
//       'Điều khiển xe lạng lách, đánh võng.',
//       'Không chấp hành hiệu lệnh của người điều khiển giao thông.',
//     ],
//     correctOptionIndex: 1,
//   ),
//   const Question(
//     questionTitle:
//         'Khi lái xe trên đường vòng, khuất tầm nhìn người lái xe phải như thế nào?',
//     options: [
//       'Đi bên phần đường bên trái để dễ quan sát.',
//       'Đi với tốc độ thấp, chú ý quan sát, không được vượt xe khác.',
//       'Bấm còi liên tục khi đến chỗ đường cong.',
//       'Tăng tốc để nhanh chóng qua đoạn đường vòng.',
//     ],
//     correctOptionIndex: 1,
//   ),
//   const Question(
//     questionTitle:
//         'Khi xảy ra tai nạn giao thông, những hành vi nào ghi ở dưới đây bị nghiêm cấm?',
//     options: [
//       'Sơ cứu người bị nạn.',
//       'Bảo vệ hiện trường vụ tai nạn.',
//       'Xô đẩy, dắt xe bỏ chạy khỏi hiện trường để trốn tránh trách nhiệm.',
//       'Gọi điện báo cho lực lượng chức năng.',
//     ],
//     correctOptionIndex: 2,
//   ),
//   const Question(
//     questionTitle:
//         'Hành vi nào sau đây bị nghiêm cấm khi điều khiển xe mô tô hai bánh, xe mô tô ba bánh, xe gắn máy?',
//     options: [
//       'Chạy đúng tốc độ quy định và đúng làn đường.',
//       'Đi đúng phần đường quy định và đội mũ bảo hiểm.',
//       'Buông cả hai tay hoặc đi xe bằng một bánh.',
//       'Chở tối đa hai người trên một xe.',
//     ],
//     correctOptionIndex: 2,
//   ),
//   const Question(
//     questionTitle:
//         'Khi muốn dừng và đỗ xe trên đường phố, người lái xe phải thực hiện như thế nào?',
//     options: [
//       'Khi dừng và đỗ xe phải cho xe nép gần lề đường phía bên phải theo chiều đi của mình.',
//       'Dừng xe, đỗ xe ở nơi đường cong hoặc gần đấy để tiện quan sát.',
//       'Dừng và đỗ xe ở nơi có biển cấm dừng và đỗ.',
//       'Dừng xe, đỗ xe trên đường hẹp gây cản trở giao thông.',
//     ],
//     correctOptionIndex: 0,
//   ),
//   const Question(
//     questionTitle:
//         'Bạn đang lái xe phía trước có một xe cứu thương đang phát tín hiệu ưu tiên bạn sẽ xử lý như thế nào?',
//     options: [
//       'Tiếp tục chạy với tốc độ không đổi vì xe của mình có quyền ưu tiên đi trước.',
//       'Tăng tốc độ để nhanh chóng thoát khỏi xe cứu thương.',
//       'Giảm tốc độ và đi sát về bên phải để nhường đường cho xe cứu thương.',
//       'Không nhường đường vì xe cứu thương phải ưu tiên cho xe bạn.',
//     ],
//     correctOptionIndex: 2,
//   ),
//   const Question(
//     questionTitle:
//         'Người lái xe sẽ bị tước quyền sử dụng giấy phép lái xe không thời hạn trong trường hợp nào?',
//     options: [
//       'Điều khiển xe tham gia giao thông mà trong cơ thể có chất ma túy.',
//       'Điều khiển xe đi ngược chiều trên đường một chiều.',
//       'Không tuân thủ các quy định về dừng xe, đỗ xe tại nơi có biển cấm.',
//       'Không thắt dây an toàn khi điều khiển xe chạy trên đường.',
//     ],
//     correctOptionIndex: 0,
//   ),
// ];
