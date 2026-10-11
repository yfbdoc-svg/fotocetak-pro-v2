import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fotocetak_pro/app.dart';

void main() {
  testWidgets('workspace terbuka dengan tiga area utama', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const FotoCetakApp());
    expect(find.text('FotoCetak Pro'), findsOneWidget);
    expect(find.text('Daftar Foto (0)'), findsOneWidget);
    expect(find.text('Pengaturan Cetak'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('workspace tidak overflow pada lebar 1280', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const FotoCetakApp());
    expect(find.text('FotoCetak Pro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
