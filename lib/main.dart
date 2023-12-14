import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(MyCanvas(offsetModel: OffsetModel()));
}

class OffsetModel with ChangeNotifier {
  double _dx = 0.0;
  double _dy = 0.0;

  double get dx => _dx;

  double get dy => _dy;

  void correctOffset({required double newDx, required double newDy}) {
    _dx = newDx;
    _dy = newDy;
  }

  void incrementX() {
    _dx += 5;
    notifyListeners();
  }

  void decrementX() {
    _dx -= 5;
    notifyListeners();
  }

  void incrementY() {
    _dy += 5;
    notifyListeners();
  }

  void decrementY() {
    _dy -= 5;
    notifyListeners();
  }
}

class MyCanvas extends StatefulWidget {
  const MyCanvas({super.key, required this.offsetModel});

  final OffsetModel offsetModel;

  @override
  State<MyCanvas> createState() => _MyCanvasState();
}

class _MyCanvasState extends State<MyCanvas> {
  late final OffsetModel _offsetModel;

  bool _hasTouchedEdge = false;

  @override
  void initState() {
    super.initState();
    _offsetModel = widget.offsetModel;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor:
              _hasTouchedEdge ? const Color(0xFFFF4D29) :
              const Color(0xFFE3E2E2),
          title: const Text('커스텀페인트'),
        ),
        backgroundColor:
            _hasTouchedEdge ? const Color(0xFFFF4D29) :
            const Color(0xFFE3E2E2),
        body: ListenableBuilder(
            listenable: _offsetModel,
            builder: (_, __) {
              return Column(
                children: [
                  IconButton(
                    onPressed: () => _offsetModel.decrementY(),
                    icon: const Icon(
                      Icons.exposure_minus_1_rounded,
                      semanticLabel: "dy",
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () => _offsetModel.decrementX(),
                        icon: const Icon(
                          Icons.exposure_minus_1_rounded,
                          semanticLabel: "dx",
                        ),
                      ),
                      IconButton(
                        onPressed: () => _offsetModel.incrementX(),
                        icon: const Icon(
                          Icons.plus_one_rounded,
                          semanticLabel: "dx",
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _offsetModel.incrementY(),
                    icon: const Icon(
                      Icons.plus_one_rounded,
                      semanticLabel: "dy",
                    ),
                  ),
                  Expanded(
                    child: CustomPaint(
                      painter: MyPainter(
                        dx: _offsetModel.dx,
                        dy: _offsetModel.dy,
                        toggleBackgroundColor: toggleBackgroundColor,
                        updateOffset: updateOffset,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }

  toggleBackgroundColor({required bool hasTouchedEdge}) {
    if (_hasTouchedEdge != hasTouchedEdge) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _hasTouchedEdge = hasTouchedEdge;
        });
      });
    }
  }

  updateOffset({required double newDx, required double newDy}) {
    _offsetModel.correctOffset(newDx: newDx, newDy: newDy);
  }
}

class MyPainter extends CustomPainter {
  final void Function({required bool hasTouchedEdge}) toggleBackgroundColor;
  final void Function({required double newDx, required double newDy})
      updateOffset;

  // x,y 벡터 값
  final double dx;
  final double dy;

  MyPainter({
    required this.toggleBackgroundColor,
    required this.updateOffset,
    required this.dx,
    required this.dy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 타겟 원 벡터
    Offset targetCircleOffset = Offset(dx, dy);

    // 타겟 원 최종 x,y 벡터 값
    late final double correctedDx;
    late final double correctedDy;

    // 캔버스 중점 픽셀 좌표
    final double centerPixelX = size.width / 2; // 화면 넓이의 절반
    final double centerPixelY = size.height / 2; // 화면 높이의 절반

    // 큰 원의 반지름 (화면 넓이 또는 높이의 절반의 80%)
    final double bigCircleRadius = min(centerPixelX, centerPixelY) * 0.80;

    // 타겟 원의 반지름 (큰 원의 13%)
    final double targetCircleRadius = bigCircleRadius * 0.13;

    if (targetCircleOffset.distance >= bigCircleRadius - targetCircleRadius) {
      // 타겟 원의 벡터 값이 큰원에 접하거나 외부로 넘어갈 경우 (한계 거리 이상일 경우)
      // 벡터 값 * (한계 거리/현재 거리) 하여 큰 원에 접하는 같은 방향을 가지는 벡터 값으로 보정
      correctedDx = dx *
          (bigCircleRadius - targetCircleRadius) /
          targetCircleOffset.distance;
      correctedDy = dy *
          (bigCircleRadius - targetCircleRadius) /
          targetCircleOffset.distance;
      toggleBackgroundColor(hasTouchedEdge: true);
      updateOffset(newDx: correctedDx, newDy: correctedDy);
    } else {
      // 타겟 원이 큰원에 접하지 않거나 내부에 있을 경우 무보정
      correctedDx = dx;
      correctedDy = dy;
      toggleBackgroundColor(hasTouchedEdge: false);
    }

    // 그릴 타겟 원 픽셀 좌표
    double targetCirclePixelX = centerPixelX + correctedDx;
    double targetCirclePixelY = centerPixelY + correctedDy;

    // 큰 원을 그릴 Paint 객체 생성
    Paint bigCirclePaint = Paint()
      ..color = const Color(0xFF24332C)
      ..style = PaintingStyle.fill;

    // 표적 라인 Paint 객체 생성
    Paint aimLinePaint = Paint()
      ..color = const Color(0xFF8FAFAD)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 타겟 원에 그릴 명암 생성
    final Rect rect = Rect.fromCircle(
      center: Offset(targetCirclePixelX - targetCircleRadius * 0.63,
          targetCirclePixelY - targetCircleRadius * 0.31),
      radius: targetCircleRadius * 1.471,
    );

    // 타겟 원을 그릴 Paint 객체 생성
    Paint targetCirclePaint = Paint()
      ..color = const Color(0xFFE76565)
      ..style = PaintingStyle.fill
      ..shader = const RadialGradient(colors: [
        Color(0xFFE66464),
        Color(0xFFC64D4D),
      ], stops: [
        0.68,
        1.0,
      ]).createShader(rect);



    // 큰 원
    canvas.drawCircle(
        Offset(centerPixelX, centerPixelY), bigCircleRadius, bigCirclePaint);
    // 표적 세로선
    canvas.drawLine(Offset(centerPixelX, centerPixelY - bigCircleRadius),
        Offset(centerPixelX, centerPixelY + bigCircleRadius), aimLinePaint);
    // 표적 가로선
    canvas.drawLine(Offset(centerPixelX - bigCircleRadius, centerPixelY),
        Offset(centerPixelX + bigCircleRadius, centerPixelY), aimLinePaint);
    // 타겟 원
    canvas.drawCircle(Offset(targetCirclePixelX, targetCirclePixelY),
        targetCircleRadius, targetCirclePaint);
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) => false;
}
