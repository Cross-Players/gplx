fvm flutter test test/ --coverage
lcov --remove coverage/lcov.info '*.g.dart' -o coverage/new_lcov.info
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html