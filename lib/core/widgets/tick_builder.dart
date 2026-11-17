import 'dart:async';

import 'package:flutter/material.dart';

class TickBuilder extends StatefulWidget {
  final Duration interval;
  final Widget Function(BuildContext context, DateTime now) builder;

  const TickBuilder({
    super.key,
    this.interval = const Duration(seconds: 15),
    required this.builder,
  });

  @override
  State<TickBuilder> createState() => _TickBuilderState();
}

class _TickBuilderState extends State<TickBuilder> {
  late DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}
