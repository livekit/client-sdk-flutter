/*
 * Copyright 2024 LiveKit, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * [SoundWaveformWidget] Originally adapted from: https://github.com/SushanShakya/sound_waveform
 *
 * MIT License
 *
 * Copyright (c) 2022 Sushan Shakya
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class SoundWaveformWidget extends StatefulWidget {
  final int barCount;
  final double width;
  final double minHeight;
  final double maxHeight;
  final int durationInMilliseconds;
  const SoundWaveformWidget({
    super.key,
    required this.audioTrack,
    this.barCount = 5,
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
  late List<double> samples;
  AudioVisualizer? _visualizer;
  EventsListener<AudioVisualizerEvent>? _listener;

  void _startVisualizer(AudioTrack track) async {
    samples = List.filled(widget.barCount, 0);
    _visualizer ??= createVisualizer(track,
        options: AudioVisualizerOptions(barCount: widget.barCount));
    _listener ??= _visualizer?.createListener();
    _listener?.on<AudioVisualizerEvent>((e) {
      if (mounted) {
        setState(() {
          samples = e.event.map((e) => ((e as num) * 100).toDouble()).toList();
        });
      }
    });

    await _visualizer!.start();
  }

  void _stopVisualizer(AudioTrack track) async {
    await _visualizer?.stop();
    await _visualizer?.dispose();
    _visualizer = null;
    await _listener?.dispose();
    _listener = null;
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
    final count = widget.barCount;
    final minHeight = widget.minHeight;
    final maxHeight = widget.maxHeight;
    return AnimatedBuilder(
      animation: controller,
      builder: (c, child) {
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
