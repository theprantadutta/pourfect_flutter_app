import 'package:flutter_test/flutter_test.dart';
import 'package:pourfect_flutter_app/ui/widgets/win_profile.dart';

void main() {
  for (final (name, p) in const [
    ('full', WinProfile.full),
    ('brief', WinProfile.brief),
  ]) {
    test('the $name moves count-up lands on the real number in time', () {
      // A count still climbing when the sequence settles freezes short:
      // "9 moves" beside "you took 10".
      expect(p.chips.at + p.movesCountUp, lessThanOrEqualTo(p.total));
    });
  }

  test('the full count-up keeps its original pace', () {
    expect(WinProfile.full.movesCountUp, WinProfile.full.chips.length + 200);
  });
}
