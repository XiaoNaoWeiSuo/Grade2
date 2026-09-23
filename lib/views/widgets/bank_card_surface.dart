import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 银行卡物理材质片段着色器服务管理器。
class BankCardShaderService {
  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram?>? _loadingFuture;

  /// 预加载片段着色器资产。
  static Future<ui.FragmentProgram?> init() {
    if (_program != null) return SynchronousFuture(_program);
    _loadingFuture ??= () async {
      try {
        _program = await ui.FragmentProgram.fromAsset('shaders/bank_card.frag');
      } catch (e) {
        debugPrint('BankCardShader: load fallback - $e');
      }
      return _program;
    }();
    return _loadingFuture!;
  }

  static ui.FragmentProgram? get program => _program;
  static bool get isReady => _program != null;
}

/// 类似实体银行卡物理材质的课程卡片基底组件。
///
/// 特性：
/// 1. GPU 片段着色器实时计算：
///    - 体积倒角高光与微阴影（Top-left 镜面反光，Bottom-right 闭塞暗边）。
///    - 实体银行卡细晶拉丝纹理与聚碳酸酯微磨砂触感。
///    - 全息防伪虹彩光泽（带有各向异性色相流动）。
///    - 左侧专属防伪色带/芯片槽结构。
/// 2. 大节连课虚线分割线绘制（精确位于连课大节交界处）。
/// 3. 内外同心圆角与无缝防溢出裁剪。
class BankCardSurface extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color accentColor;
  final bool isDark;
  final double seed;
  final double borderRadius;
  final List<double> dashedSeparatorYs;
  final EdgeInsetsGeometry margin;

  const BankCardSurface({
    super.key,
    required this.child,
    required this.baseColor,
    required this.accentColor,
    required this.isDark,
    required this.seed,
    this.borderRadius = 10.0,
    this.dashedSeparatorYs = const [],
    this.margin = const EdgeInsets.symmetric(vertical: 1.5),
  });

  @override
  State<BankCardSurface> createState() => _BankCardSurfaceState();
}

class _BankCardSurfaceState extends State<BankCardSurface> {
  @override
  void initState() {
    super.initState();
    if (!BankCardShaderService.isReady) {
      BankCardShaderService.init().then((prog) {
        if (mounted && prog != null) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = BankCardShaderService.program;
    final shader = program?.fragmentShader();

    return Padding(
      padding: widget.margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            // 实体卡片多层物理投影（环境泛光 + 接触微阴影）
            BoxShadow(
              color: widget.accentColor.withValues(
                alpha: widget.isDark ? 0.12 : 0.08,
              ),
              blurRadius: 5.0,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: const Color(0x0A000000),
              blurRadius: 1.5,
              offset: const Offset(0, 0.5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: CustomPaint(
            painter: _BankCardSurfacePainter(
              shader: shader,
              baseColor: widget.baseColor,
              accentColor: widget.accentColor,
              isDark: widget.isDark,
              seed: widget.seed,
              borderRadius: widget.borderRadius,
              dashedSeparatorYs: widget.dashedSeparatorYs,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _BankCardSurfacePainter extends CustomPainter {
  final ui.FragmentShader? shader;
  final Color baseColor;
  final Color accentColor;
  final bool isDark;
  final double seed;
  final double borderRadius;
  final List<double> dashedSeparatorYs;

  _BankCardSurfacePainter({
    required this.shader,
    required this.baseColor,
    required this.accentColor,
    required this.isDark,
    required this.seed,
    required this.borderRadius,
    required this.dashedSeparatorYs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final cardRect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      cardRect,
      Radius.circular(borderRadius),
    );

    if (shader != null) {
      // 1. 设置 GLSL 片段着色器 Uniforms:
      // Index 0, 1: u_size (width, height)
      shader!.setFloat(0, size.width);
      shader!.setFloat(1, size.height);
      // Index 2..5: u_base_color (r, g, b, a)
      shader!.setFloat(2, baseColor.r);
      shader!.setFloat(3, baseColor.g);
      shader!.setFloat(4, baseColor.b);
      shader!.setFloat(5, baseColor.a);
      // Index 6..9: u_accent_color (r, g, b, a)
      shader!.setFloat(6, accentColor.r);
      shader!.setFloat(7, accentColor.g);
      shader!.setFloat(8, accentColor.b);
      shader!.setFloat(9, accentColor.a);
      // Index 10: u_is_dark
      shader!.setFloat(10, isDark ? 1.0 : 0.0);
      // Index 11: u_seed
      shader!.setFloat(11, seed);
      // Index 12: u_radius
      shader!.setFloat(12, borderRadius);

      final paint = Paint()..shader = shader;
      canvas.drawRect(cardRect, paint);
    } else {
      // 降级回退 Canvas 渲染（保证冷启动或无着色器平台丝滑呈现）
      _paintFallback(canvas, size, rrect);
    }

    // 2. 绘制大节连课中间的虚线标识（Dashed Separators for merged sessions）
    _paintDashedLines(canvas, size);

    // 3. 绘制实体卡片微倒角外包边框（极细微金属/哑光边缘）
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.28 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawRRect(rrect.deflate(0.3), borderPaint);
  }

  void _paintFallback(Canvas canvas, Size size, RRect rrect) {
    // 基础渐变卡面
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.2, 0),
        Offset(size.width * 0.8, size.height),
        [
          baseColor,
          Color.lerp(baseColor, accentColor, 0.06)!,
        ],
      );
    canvas.drawRRect(rrect, bgPaint);

    // 左侧色条
    final stripePaint = Paint()..color = accentColor;
    final stripeRRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, 3.5, size.height),
      topLeft: Radius.circular(borderRadius),
      bottomLeft: Radius.circular(borderRadius),
    );
    canvas.drawRRect(stripeRRect, stripePaint);

    // 顶部微高光
    final topHighlightPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, 1.5),
        [
          Color(0x33FFFFFF),
          Color(0x00FFFFFF),
        ],
      );
    canvas.drawRRect(rrect, topHighlightPaint);
  }

  void _paintDashedLines(Canvas canvas, Size size) {
    if (dashedSeparatorYs.isEmpty) return;

    final dashPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.42 : 0.32)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final y in dashedSeparatorYs) {
      if (y <= 6.0 || y >= size.height - 6.0) continue;

      // 虚线从左侧边条后（x=6.0）起始，横向贯通至右侧内边距（x=width - 6.0）
      double curX = 6.5;
      final maxX = size.width - 6.0;
      const dashWidth = 3.5;
      const dashSpace = 2.5;

      while (curX < maxX) {
        final nextX = (curX + dashWidth).clamp(curX, maxX);
        canvas.drawLine(Offset(curX, y), Offset(nextX, y), dashPaint);
        curX += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BankCardSurfacePainter oldDelegate) {
    return oldDelegate.shader != shader ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.seed != seed ||
        oldDelegate.borderRadius != borderRadius ||
        !listEquals(oldDelegate.dashedSeparatorYs, dashedSeparatorYs);
  }
}
