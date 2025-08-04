import 'package:flutter/material.dart';

// Liste elemanlarının sırayla animasyonlu şekilde belirmesini sağlayan widget
class AnimatedListView<T> extends StatefulWidget {
  const AnimatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.animationDuration = const Duration(milliseconds: 200),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutCubic,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Duration animationDuration;
  final Duration staggerDelay;
  final Curve curve;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  State<AnimatedListView<T>> createState() => _AnimatedListViewState<T>();
}

class _AnimatedListViewState<T> extends State<AnimatedListView<T>> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStaggeredAnimations();
  }

  // Animasyon controller'larını ve animasyonları başlat
  void _initializeAnimations() {
    _controllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: widget.curve),
      );
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: widget.curve),
      );
    }).toList();
  }

  // Sıralı animasyonları başlat
  void _startStaggeredAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(AnimatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Eğer öğe sayısı değiştiyse animasyonları yeniden başlat
    if (oldWidget.items.length != widget.items.length) {
      // Eski controller'ları dispose et
      for (final controller in _controllers) {
        controller.dispose();
      }

      // Yeni animasyonları başlat
      _initializeAnimations();
      _startStaggeredAnimations();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: widget.padding,
      physics: widget.physics,
      scrollDirection: Axis.horizontal,
      shrinkWrap: widget.shrinkWrap,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimations[index],
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: widget.itemBuilder(context, widget.items[index], index),
              ),
            );
          },
        );
      },
    );
  }
}
