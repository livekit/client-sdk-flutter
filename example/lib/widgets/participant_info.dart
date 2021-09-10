import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

class ParticipantInfoWidget extends StatelessWidget {
  //
  final String? title;
  final bool muted;

  const ParticipantInfoWidget({
    this.title,
    this.muted = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(
          vertical: 7,
          horizontal: 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (title != null)
              Flexible(
                child: Text(
                  title!,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Icon(
                !muted ? EvaIcons.mic : EvaIcons.micOff,
                color: !muted ? Colors.white : Colors.red,
                size: 16,
              ),
            ),
          ],
        ),
      );
}
