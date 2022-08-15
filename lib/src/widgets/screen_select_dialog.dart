import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

class ThumbnailWidget extends StatefulWidget {
  const ThumbnailWidget(
      {Key? key,
      required this.source,
      required this.selected,
      required this.onTap})
      : super(key: key);
  final rtc.DesktopCapturerSource source;
  final bool selected;
  final Function(rtc.DesktopCapturerSource) onTap;

  @override
  ThumbnailWidgetState createState() => ThumbnailWidgetState();
}

class ThumbnailWidgetState extends State<ThumbnailWidget> {
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _subscriptions.add(widget.source.onThumbnailChanged.stream.listen((event) {
      setState(() {});
    }));
    _subscriptions.add(widget.source.onNameChanged.stream.listen((event) {
      setState(() {});
    }));
  }

  @override
  void deactivate() {
    for (var element in _subscriptions) {
      element.cancel();
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
            child: Container(
          decoration: widget.selected
              ? BoxDecoration(
                  border: Border.all(width: 2, color: Colors.blueAccent))
              : null,
          child: InkWell(
            onTap: () {
              if (kDebugMode) {
                print('Selected source id => ${widget.source.id}');
              }
              widget.onTap(widget.source);
            },
            child: widget.source.thumbnail != null
                ? Image.memory(
                    widget.source.thumbnail!,
                    gaplessPlayback: true,
                    alignment: Alignment.center,
                  )
                : Container(),
          ),
        )),
        Text(
          widget.source.name,
          style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight:
                  widget.selected ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }
}

// ignore: must_be_immutable
class ScreenSelectDialog extends Dialog {
  ScreenSelectDialog({Key? key}) : super(key: key) {
    Future.delayed(const Duration(milliseconds: 100), () {
      _getSources();
    });
    _subscriptions.add(rtc.desktopCapturer.onAdded.stream.listen((source) {
      _sources[source.id] = source;
      _stateSetter?.call(() {});
    }));

    _subscriptions.add(rtc.desktopCapturer.onRemoved.stream.listen((source) {
      _sources.remove(source.id);
      _stateSetter?.call(() {});
    }));

    _subscriptions
        .add(rtc.desktopCapturer.onThumbnailChanged.stream.listen((source) {
      _stateSetter?.call(() {});
    }));
  }
  final Map<String, rtc.DesktopCapturerSource> _sources = {};
  rtc.SourceType _sourceType = rtc.SourceType.Screen;
  rtc.DesktopCapturerSource? _selectedSource;
  final List<StreamSubscription<rtc.DesktopCapturerSource>> _subscriptions = [];
  StateSetter? _stateSetter;
  Timer? _timer;

  void _ok(BuildContext context) {
    _timer?.cancel();
    for (var element in _subscriptions) {
      element.cancel();
    }
    Navigator.pop<rtc.DesktopCapturerSource>(context, _selectedSource);
  }

  void _cancel(BuildContext context) {
    _timer?.cancel();
    for (var element in _subscriptions) {
      element.cancel();
    }
    Navigator.pop<rtc.DesktopCapturerSource>(context, null);
  }

  Future<void> _getSources() async {
    try {
      var sources = await rtc.desktopCapturer.getSources(types: [_sourceType]);
      for (var element in sources) {
        if (kDebugMode) {
          print(
              'name: ${element.name}, id: ${element.id}, type: ${element.type}');
        }
      }
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        rtc.desktopCapturer.updateSources(types: [_sourceType]);
      });
      _sources.clear();
      for (var element in sources) {
        _sources[element.id] = element;
      }
      _stateSetter?.call(() {});
      return;
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
          child: Container(
        width: 640,
        height: 560,
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10),
              child: Stack(
                children: <Widget>[
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Choose what to share',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      child: const Icon(Icons.close),
                      onTap: () => _cancel(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    _stateSetter = setState;
                    return DefaultTabController(
                      length: 2,
                      child: Column(
                        children: <Widget>[
                          Container(
                            constraints:
                                const BoxConstraints.expand(height: 24),
                            child: TabBar(
                                onTap: (value) => Future.delayed(
                                        const Duration(milliseconds: 300), () {
                                      _sourceType = value == 0
                                          ? rtc.SourceType.Screen
                                          : rtc.SourceType.Window;
                                      _getSources();
                                    }),
                                tabs: const [
                                  Tab(
                                      child: Text(
                                    'Entire Screen',
                                    style: TextStyle(color: Colors.black54),
                                  )),
                                  Tab(
                                      child: Text(
                                    'Window',
                                    style: TextStyle(color: Colors.black54),
                                  )),
                                ]),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Expanded(
                            child: TabBarView(children: [
                              Align(
                                  alignment: Alignment.center,
                                  child: GridView.count(
                                    crossAxisSpacing: 8,
                                    crossAxisCount: 2,
                                    children: _sources.entries
                                        .where((element) =>
                                            element.value.type ==
                                            rtc.SourceType.Screen)
                                        .map((e) => ThumbnailWidget(
                                              onTap: (source) {
                                                setState(() {
                                                  _selectedSource = source;
                                                });
                                              },
                                              source: e.value,
                                              selected: _selectedSource?.id ==
                                                  e.value.id,
                                            ))
                                        .toList(),
                                  )),
                              Align(
                                  alignment: Alignment.center,
                                  child: GridView.count(
                                    crossAxisSpacing: 8,
                                    crossAxisCount: 3,
                                    children: _sources.entries
                                        .where((element) =>
                                            element.value.type ==
                                            rtc.SourceType.Window)
                                        .map((e) => ThumbnailWidget(
                                              onTap: (source) {
                                                setState(() {
                                                  _selectedSource = source;
                                                });
                                              },
                                              source: e.value,
                                              selected: _selectedSource?.id ==
                                                  e.value.id,
                                            ))
                                        .toList(),
                                  )),
                            ]),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ButtonBar(
                children: <Widget>[
                  MaterialButton(
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black54),
                    ),
                    onPressed: () {
                      _cancel(context);
                    },
                  ),
                  MaterialButton(
                    color: Theme.of(context).primaryColor,
                    child: const Text(
                      'Share',
                    ),
                    onPressed: () {
                      _ok(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}
