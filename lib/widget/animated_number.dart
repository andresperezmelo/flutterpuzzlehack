import 'package:flutter/material.dart';

class AnimatedNumber extends StatefulWidget {
  late final double number;
  final Duration duration;
  final TextStyle style;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry marging;
  final BoxDecoration decoration;
  final bool animateInit;
  AnimatedNumber({
    required this.number,
    this.duration = const Duration(milliseconds: 500),
    this.style = const TextStyle(),
    this.padding = const EdgeInsets.all(0),
    this.marging = const EdgeInsets.all(0),
    this.decoration = const BoxDecoration(),
    this.animateInit = false,
  });

  @override
  _AnimatedNumberState createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber> with SingleTickerProviderStateMixin {
  late Duration _duration;
  late AnimationController controller;
  late Animation<double> animation;

  double numberBefore = 0;
  double numberAfter = 0;

  @override
  void initState() {
    if (this.widget.animateInit == false) {
      numberAfter = this.widget.number;
    }
    _duration = this.widget.duration;
    controller = AnimationController(vsync: this, duration: _duration)
      ..addListener(() {
        // Marca el árbol de widgets como sucio
        setState(() {});
      });
    animation = Tween(begin: numberAfter, end: this.widget.number).animate(controller);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //print("---> recargando: $numberBefore ${this.widget.number}");
    if (numberBefore != this.widget.number) {
      numberBefore = this.widget.number;
      this.showAnimation();
    }
    return Container(
      padding: widget.padding,
      margin: widget.marging,
      decoration: widget.decoration,
      child: Text('${animation.value.toStringAsFixed(0)}', style: this.widget.style),
    );
  }

  showAnimation() async {
    await Future.delayed(Duration(milliseconds: 500));
    animation = Tween(begin: numberAfter, end: this.widget.number).animate(controller);

    if (this.mounted) {
      controller
        ..reset()
        ..forward();
      numberAfter = this.widget.number;
    }
  }
}
