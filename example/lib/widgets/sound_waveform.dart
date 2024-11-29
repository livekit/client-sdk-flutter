import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class SoundWaveformWidget extends StatefulWidget {
  final int count;
  final double width;
  final double minHeight;
  final double maxHeight;
  final int durationInMilliseconds;
  const SoundWaveformWidget({
    super.key,
    required this.audioTrack,
    this.count = 7,
    this.width = 5,
    this.minHeight = 8,
    this.maxHeight = 100,
    this.durationInMilliseconds = 500,
  });
  final AudioTrack audioTrack;
  @override
  State<SoundWaveformWidget> createState() => _SoundWaveformWidgetState();
}

class _SoundWaveformWidgetState extends State<SoundWaveformWidget>
    with TickerProviderStateMixin {
  late AnimationController controller;
  List<double> samples = [0, 0, 0, 0, 0, 0, 0];
  EventsListener<TrackEvent>? _listener;

  void _startVisualizer(AudioTrack track) async {
    await _listener?.dispose();
    _listener = track.createListener();
    _listener?.on<AudioVisualizerEvent>((e) {
      if (mounted) {
        setState(() {
          samples = e.event.map((e) => ((e as num) * 100).toDouble()).toList();
        });
      }
    });
  }

  void _stopVisualizer(AudioTrack track) async {
    await _listener?.dispose();
  }

  @override
  void initState() {
    super.initState();

    _startVisualizer(widget.audioTrack);

    controller = AnimationController(
        vsync: this,
        duration: Duration(
          milliseconds: widget.durationInMilliseconds,
        ))
      ..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    _stopVisualizer(widget.audioTrack);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.count;
    final minHeight = widget.minHeight;
    final maxHeight = widget.maxHeight;
    return AnimatedBuilder(
      animation: controller,
      builder: (c, child) {
        //double t = controller.value;
        //int current = (samples.length * t).floor();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            count,
            (i) => AnimatedContainer(
              duration: Duration(
                  milliseconds: widget.durationInMilliseconds ~/ count),
              margin: i == (samples.length - 1)
                  ? EdgeInsets.zero
                  : const EdgeInsets.only(right: 5),
              height: samples[i] < minHeight
                  ? minHeight
                  : samples[i] > maxHeight
                      ? maxHeight
                      : samples[i],
              width: widget.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        );
      },
    );
  }
}
