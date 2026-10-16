List<String> licenseData = [
  'A',
  'A1',
  'B',
  'B1',
  'C',
  'C1',
  'D',
  'D1',
  'D2',
  'BE',
  'C1E',
  'CE',
  'D1E',
  'D2E',
  'DE',
  'all_questions'
];

int numberOfTestSetsBasedOnLicense(String licenseType) {
  switch (licenseType) {
    case 'A':
      return 17;
    case 'A1':
      return 7; // Số lượng bộ đề cho hạng A và A1
    case 'B':
      return 19;
    case 'B1':
      return 19; // Số lượng bộ đề cho hạng B và B1
    case 'C':
      return 14;
    case 'C1':
      return 17;
    case 'D':
    case 'D1':
    case 'D2':
    case 'BE':
    case 'C1E':
    case 'CE':
    case 'D1E':
    case 'D2E':
    case 'DE':
      return 25;
    default:
      return 0; // Không có bộ đề cho các loại khác
  }
}

List<int> generateTestSetNumbers(String licenseType) {
  int numberOfSets = numberOfTestSetsBasedOnLicense(licenseType);
  return List.generate(numberOfSets, (index) => index + 1);
}
