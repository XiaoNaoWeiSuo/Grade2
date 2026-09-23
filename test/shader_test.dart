import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bank_card.frag can be compiled and loaded as FragmentProgram', () async {
    final program = await ui.FragmentProgram.fromAsset('shaders/bank_card.frag');
    expect(program, isNotNull);
    final shader = program.fragmentShader();
    expect(shader, isNotNull);

    // Set uniforms
    shader.setFloat(0, 100.0); // u_size.x
    shader.setFloat(1, 150.0); // u_size.y
    shader.setFloat(2, 0.2);   // baseColor.r
    shader.setFloat(3, 0.4);   // baseColor.g
    shader.setFloat(4, 0.8);   // baseColor.b
    shader.setFloat(5, 1.0);   // baseColor.a
    shader.setFloat(6, 0.1);   // accentColor.r
    shader.setFloat(7, 0.6);   // accentColor.g
    shader.setFloat(8, 0.9);   // accentColor.b
    shader.setFloat(9, 1.0);   // accentColor.a
    shader.setFloat(10, 0.0);  // isDark
    shader.setFloat(11, 42.0); // seed
    shader.setFloat(12, 10.0); // radius
  });
}
