import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/framework/core/network/api_url_builder.dart';

void main() {
  test(
    'builds a URI while preserving the API prefix without a trailing slash',
    () {
      expect(
        buildApiUri('http://localhost:3001/api', 'products'),
        Uri.parse('http://localhost:3001/api/products'),
      );
    },
  );

  test('removes one trailing slash and preserves the API prefix', () {
    expect(
      buildApiUri('http://localhost:3001/api/', 'products'),
      Uri.parse('http://localhost:3001/api/products'),
    );
  });

  test('leaves path and query text to Uri.parse without extra encoding', () {
    expect(
      buildApiUri('http://localhost:3001/api/', 'members?search=0812%203456'),
      Uri.parse('http://localhost:3001/api/members?search=0812%203456'),
    );
  });
}
