import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  late final double percent;
  final Widget child;
  final double heigth;
  final Color? progressColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BoxDecoration decoration;
  final Duration durationAnimation;
  ProgressBar({
    required this.percent,
    this.child = const Text(""),
    this.heigth = 5,
    this.decoration = const BoxDecoration(),
    this.progressColor,
    this.padding = const EdgeInsets.all(0),
    this.margin = const EdgeInsets.all(0),
    this.durationAnimation = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double widgth = constraints.maxWidth;
        double porcentaje = percent.clamp(0, 100);

        if (porcentaje < 0) {
          porcentaje = 0;
        }

        if (widgth.toString() == "Infinity") {
          widgth = MediaQuery.of(context).size.width;
        }
        double paint = (widgth / 100) * porcentaje;
        if (paint.toString() == "Infinity" || paint.toString() == "NaN") {
          paint = 0;
        }
        //print("widgth: $widgth percent: $porcentaje paint: $paint");
        return Container(
          width: widgth,
          height: heigth,
          alignment: Alignment.centerLeft,
          decoration: decoration,
          child: Stack(
            children: [
              AnimatedContainer(
                width: paint,
                decoration: BoxDecoration(
                  color: progressColor ?? Theme.of(context).colorScheme.secondary,
                  borderRadius: decoration.borderRadius,
                ),
                duration: this.durationAnimation,
              ),
              Center(
                child: FittedBox(child: child),
              ),
            ],
          ),
        );
      },
    );
  }
}
