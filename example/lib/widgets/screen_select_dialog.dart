import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

// ignore: must_be_immutable
class ScreenSelectDialog extends Dialog {
  ScreenSelectDialog({Key? key}) : super(key: key) {
    Future.delayed(const Duration(milliseconds: 100), () {
      _getSources();
    });
    _subscriptions.add(desktopCapturer.onAdded.stream.listen((source) {
      _sources[source.id] = source;
      _stateSetter?.call(() {});
    }));

    _subscriptions.add(desktopCapturer.onRemoved.stream.listen((source) {
      _sources.remove(source.id);
      _stateSetter?.call(() {});
    }));

    _subscriptions.add(desktopCapturer.onNameChanged.stream.listen((source) {
      _sources[source.id] = source;
      _stateSetter?.call(() {});
    }));

    _subscriptions
        .add(desktopCapturer.onThumbnailChanged.stream.listen((source) {
      _sources[source.id] = source;
      _stateSetter?.call(() {});
    }));
  }
  final Map<String, DesktopCapturerSource> _sources = {};
  SourceType _sourceType = SourceType.Screen;
  DesktopCapturerSource? _selectedSource;
  final List<StreamSubscription<DesktopCapturerSource>> _subscriptions = [];
  StateSetter? _stateSetter;
  Timer? _timer;

  void _ok(BuildContext context) async {
    _timer?.cancel();
    for (var item in _subscriptions) {
      await item.cancel();
    }
    Navigator.pop<DesktopCapturerSource>(context, _selectedSource);
  }

  void _cancel(BuildContext context) async {
    _timer?.cancel();
    for (var item in _subscriptions) {
      await item.cancel();
    }
    Navigator.pop<DesktopCapturerSource>(context, null);
  }

  Future<void> _getSources() async {
    try {
      var sources = await desktopCapturer.getSources(types: [_sourceType]);
      for (var item in sources) {
        print('name: ${item.name}, id: ${item.id}, type: ${item.type}');
      }
      _stateSetter?.call(() {
        for (var item in sources) {
          _sources[item.id] = item;
        }
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
        desktopCapturer.updateSources(types: [_sourceType]);
      });
      return;
    } catch (e) {
      print(e.toString());
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
                                          ? SourceType.Screen
                                          : SourceType.Window;
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
                                            SourceType.Screen)
                                        .map((e) => Column(
                                              children: [
                                                Expanded(
                                                    child: Container(
                                                  decoration: (_selectedSource !=
                                                              null &&
                                                          _selectedSource!.id ==
                                                              e.value.id)
                                                      ? BoxDecoration(
                                                          border: Border.all(
                                                              width: 2,
                                                              color: Colors
                                                                  .blueAccent))
                                                      : null,
                                                  child: InkWell(
                                                    onTap: () {
                                                      print(
                                                          'Selected screen id => ${e.value.id}');
                                                      setState(() {
                                                        _selectedSource =
                                                            e.value;
                                                      });
                                                    },
                                                    child: e.value.thumbnail !=
                                                            null
                                                        ? Image.memory(
                                                            e.value.thumbnail!,
                                                            scale: 1.0,
                                                            repeat: ImageRepeat
                                                                .noRepeat,
                                                          )
                                                        : Container(),
                                                  ),
                                                )),
                                                Text(
                                                  e.value.name,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black87,
                                                      fontWeight:
                                                          (_selectedSource !=
                                                                      null &&
                                                                  _selectedSource!
                                                                          .id ==
                                                                      e.value
                                                                          .id)
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal),
                                                ),
                                              ],
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
                                            SourceType.Window)
                                        .map((e) => Column(
                                              children: [
                                                Expanded(
                                                    child: Container(
                                                  decoration: (_selectedSource !=
                                                              null &&
                                                          _selectedSource!.id ==
                                                              e.value.id)
                                                      ? BoxDecoration(
                                                          border: Border.all(
                                                              width: 2,
                                                              color: Colors
                                                                  .blueAccent))
                                                      : null,
                                                  child: InkWell(
                                                    onTap: () {
                                                      print(
                                                          'Selected window id => ${e.value.id}');
                                                      setState(() {
                                                        _selectedSource =
                                                            e.value;
                                                      });
                                                    },
                                                    child: e.value.thumbnail!
                                                            .isNotEmpty
                                                        ? Image.memory(
                                                            e.value.thumbnail!,
                                                            scale: 1.0,
                                                            repeat: ImageRepeat
                                                                .noRepeat,
                                                          )
                                                        : Container(),
                                                  ),
                                                )),
                                                Text(
                                                  e.value.name,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black87,
                                                      fontWeight:
                                                          (_selectedSource !=
                                                                      null &&
                                                                  _selectedSource!
                                                                          .id ==
                                                                      e.value
                                                                          .id)
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal),
                                                ),
                                              ],
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
