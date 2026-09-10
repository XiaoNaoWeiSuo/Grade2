// 内核开发期验证脚本（不入内核）：AES 向量 + 解析器 golden 比对。
// 运行: /Users/lin/develop/flutter/bin/dart run tool/kernel_check.dart [golden|domain]
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:grade2/core/crawler/crypto/aes_cbc.dart';
import 'package:grade2/core/crawler/parsers/table_miner.dart';
import 'package:grade2/core/crawler/parsers/timetable_parser.dart';
import 'package:grade2/core/crawler/parsers/grade_parser.dart';
import 'package:grade2/core/crawler/parsers/exam_parser.dart';
import 'package:grade2/core/crawler/parsers/plan_parser.dart';
import 'package:grade2/core/crawler/parsers/elective_parser.dart';
import 'package:grade2/core/crawler/parsers/misc_parser.dart';

String hex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
Uint8List unhex(String s) => Uint8List.fromList([
      for (var i = 0; i < s.length; i += 2)
        int.parse(s.substring(i, i + 2), radix: 16)
    ]);

void expectEq(Object actual, Object expected, String name) {
  if (actual != expected) {
    stderr.writeln('FAIL $name\n  expect: $expected\n  actual: $actual');
    exitCode = 1;
  } else {
    stdout.writeln('PASS $name');
  }
}

const goldenSamples = [
  'grades_349.html', 'examTable_1523.html', 'otherExamSignUp.html',
  'myPlanCompl.html', 'myPlanByMajor.html', 'stdDetail.html',
  'systemMessages.html', 'welcome.html', 'stdMajorPlan.html',
  'stdEvaluate.html', 'stdApply.html', 'courseTable_std_369.html',
  'electiveProfiles.html', 'examBatches.html', 'midterm.html',
  'courseTable_class_349.html', 'courseTable_std_409.html',
  'courseTable_std_1.html', 'electiveDefaultPage_1.html',
  'electiveDefaultPage_6254.html',
];

/// 递归排序 key 的规范化编码（对标 Python json sort_keys=True）。
String canonicalJson(Object? v) {
  if (v is Map) {
    final keys = v.keys.map((k) => k.toString()).toList()..sort();
    return '{${keys.map((k) => '${jsonEncode(k)}:${canonicalJson(v[k])}').join(',')}}';
  }
  if (v is List) return '[${v.map(canonicalJson).join(',')}]';
  return jsonEncode(v);
}

Future<void> goldenCheck() async {
  const outDir = '/Users/lin/Desktop/x/Grade2/grabber/output';
  final result = <String, Object?>{};
  for (final name in goldenSamples) {
    final f = File('$outDir/$name');
    if (!await f.exists()) continue;
    final html = await f.readAsString();
    final tables = parseTables(html);
    result[name] = {
      'tables': [
        for (final t in tables)
          {
            'id': t['id'],
            'class': t['class'],
            'title': t['title'],
            'caption': t['caption'],
            'headers': t['headers'],
            'n_rows': t['n_rows'],
            'n_cols': t['n_cols'],
            'rows': t['rows'],
            'header_rows': t['header_rows'],
            'records': tableRecords(t),
            'records_hr0': tableRecords(t, headerRow: 0),
          }
      ],
      'kv': kvTables(html),
    };
  }
  await File('/tmp/golden_dart.json').writeAsString(canonicalJson(result));
  stdout.writeln('golden_dart.json written (${result.length} samples)');

  // 与 Python 输出规范化比对（逐字符）
  final py = File('/tmp/golden_py.json').readAsStringSync();
  final pyCanon = canonicalJson(jsonDecode(py));
  final dartCanon = canonicalJson(result);
  if (pyCanon == dartCanon) {
    stdout.writeln('PASS golden 表格解析与 Python 完全一致');
  } else {
    // 定位首个差异
    final n = pyCanon.length < dartCanon.length ? pyCanon.length : dartCanon.length;
    var i = 0;
    while (i < n && pyCanon[i] == dartCanon[i]) {
      i++;
    }
    stderr.writeln('FAIL golden 不一致 @pos $i\n'
        '  py:   ...${pyCanon.substring(i - 80 < 0 ? 0 : i - 80, (i + 120 > pyCanon.length ? pyCanon.length : i + 120))}...\n'
        '  dart: ...${dartCanon.substring(i - 80 < 0 ? 0 : i - 80, (i + 120 > dartCanon.length ? dartCanon.length : i + 120))}...');
    exitCode = 1;
  }
}

/// 域解析器 golden：与 /tmp/gen_domain_golden.py 产出逐字段比对。
Future<void> domainCheck() async {
  const outDir = '/Users/lin/Desktop/x/Grade2/grabber/output';
  String rd(String name) => File('$outDir/$name').readAsStringSync();
  final result = <String, Object?>{};

  // ---- 课表 ----
  for (final name in [
    'courseTable_std_369.html',
    'courseTable_class_349.html',
    'courseTable_std_409.html',
    'courseTable_std_1.html',
  ]) {
    result['course:$name'] = parseCourseHtml(rd(name));
  }

  // ---- 成绩 ----
  result['grades'] = parseGradesHtml(rd('grades_349.html'));

  // ---- 考试 ----
  result['examTable'] = parseExamHtml(rd('examTable_1523.html'));
  result['otherExams'] = parseOtherExamsHtml(rd('otherExamSignUp.html'));
  result['examBatches'] = parseExamBatchesHtml(rd('examBatches.html'));
  result['midterm'] = parseMidtermHtml(rd('midterm.html'));

  // ---- 培养计划 ----
  result['planCompletion'] = parsePlanCompletionHtml(rd('myPlanCompl.html'));
  result['planByMajor'] = parsePlanTablesHtml(rd('myPlanByMajor.html'));
  // major_plan：红色错误提示优先
  final majorHtml = rd('stdMajorPlan.html');
  final errM = RegExp(r'color:\s*red[^>]*>([^<]+)<').firstMatch(majorHtml);
  result['majorPlan'] = errM != null
      ? {'error': errM.group(1)!.trim()}
      : {'tables': parsePlanTablesHtml(majorHtml)};
  result['stdApply'] = parseStdApplyHtml(rd('stdApply.html'));

  // ---- 杂项 ----
  result['stdDetail'] = parseStdDetailHtml(rd('stdDetail.html'));
  result['messages'] = parseMessagesHtml(rd('systemMessages.html'));
  result['welcome'] = parseWelcomeHtml(rd('welcome.html'));
  result['semesters'] = parseSemestersHtml(rd('semesters_raw.txt'));
  result['evaluate'] = parseEvaluateHtml(rd('stdEvaluate.html'));

  // ---- 选课 ----
  result['electiveProfiles'] = parseProfilesHtml(rd('electiveProfiles.html'));
  result['electiveContext_1'] =
      parseElectiveContextHtml(rd('electiveDefaultPage_1.html'), 1);
  result['electiveContext_6254'] =
      parseElectiveContextHtml(rd('electiveDefaultPage_6254.html'), 6254);
  // lessons：保存的是解析结果，包回页面再走一遍解析链（验证 extract/js 字面量）
  result['electiveLessons'] =
      parseLessonsHtml('var lessonJSONs = ${rd('electiveLessons_6254.json')}');

  await File('/tmp/golden_domain_dart.json')
      .writeAsString(canonicalJson(result));
  stdout.writeln('golden_domain_dart.json written (${result.length} keys)');

  // 与 Python 输出规范化比对（逐字符）
  final py = File('/tmp/golden_domain_py.json').readAsStringSync();
  final pyCanon = canonicalJson(jsonDecode(py));
  final dartCanon = canonicalJson(result);
  if (pyCanon == dartCanon) {
    stdout.writeln('PASS domain 域解析与 Python 完全一致');
  } else {
    final n =
        pyCanon.length < dartCanon.length ? pyCanon.length : dartCanon.length;
    var i = 0;
    while (i < n && pyCanon[i] == dartCanon[i]) {
      i++;
    }
    stderr.writeln('FAIL domain 不一致 @pos $i\n'
        '  py:   ...${pyCanon.substring(i - 80 < 0 ? 0 : i - 80, (i + 120 > pyCanon.length ? pyCanon.length : i + 120))}...\n'
        '  dart: ...${dartCanon.substring(i - 80 < 0 ? 0 : i - 80, (i + 120 > dartCanon.length ? dartCanon.length : i + 120))}...');
    exitCode = 1;
  }
}

Future<void> main(List<String> args) async {
  if (args.contains('golden')) {
    await goldenCheck();
    return;
  }
  if (args.contains('domain')) {
    await domainCheck();
    return;
  }
  // FIPS-197 附录 C.1: AES-128 单块
  final key = unhex('000102030405060708090a0b0c0d0e0f');
  final pt = unhex('00112233445566778899aabbccddeeff');
  expectEq(hex(Aes128(key).encryptBlock(pt)),
      '69c4e0d86a7b0430d8cdb78070b4c55a', 'FIPS-197 C.1');

  // NIST SP 800-38A F.2.1 CBC-AES128 (4 块)
  final ckey = unhex('2b7e151628aed2a6abf7158809cf4f3c');
  final civ = unhex('000102030405060708090a0b0c0d0e0f');
  final cpt = unhex(
      '6bc1bee22e409f96e93d7e117393172a'
      'ae2d8a571e03ac9c9eb76fac45af8e51'
      '30c81c46a35ce411e5fbc1191a0a52ef'
      'f69f2445df4f9b17ad2b417be66c3710');
  final cct = aes128CbcEncrypt(ckey, civ, cpt);
  expectEq(
      hex(cct).substring(0, 128),
      '7649abac8119b246cee98e9b12e9197d'
      '5086cb9b507219ee95db113a917678b2'
      '73bed6b8e3c1743b7116e69e22229516'
      '3ff1caa1681fac09120eca307586e1a7',
      'SP800-38A F.2.1');
  // 明文恰为整块时 PKCS7 追加一整块填充
  expectEq(cct.length, 80, 'PKCS7 整块追加');

  // 与 Python pycryptodome 交叉验证（固定 key/iv/明文, golden=8W3uxYxszYs8L1y/U1uNGQ==）
  final enc = aes128CbcEncryptToBase64(
      'abcdefghijklmnop', '0123456789abcdef', 'hello中文');
  expectEq(enc, '8W3uxYxszYs8L1y/U1uNGQ==', 'pycryptodome 交叉一致');
}
