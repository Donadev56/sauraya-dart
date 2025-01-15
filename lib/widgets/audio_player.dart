import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AudioPlayerWidget extends StatelessWidget {
  final Duration totalDuration;
  final Duration currentPosition;
  final bool isPlaying;
  final bool isAudioLoading;

  const AudioPlayerWidget({
    Key? key,
    required this.isPlaying,
    required this.totalDuration,
    required this.currentPosition,
    required this.isAudioLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = totalDuration.inMilliseconds == 0
        ? 0.0
        : currentPosition.inMilliseconds / totalDuration.inMilliseconds;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: !isAudioLoading
                ? CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: const Color.fromARGB(77, 255, 255, 255),
                    color: const Color.fromARGB(255, 255, 255, 255),
                  )
                : ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 50),
                    child: loader,
                  ),
          ),
          if (!isAudioLoading)
            Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
        ],
      ),
    );
  }
}

final loader = SpinKitFadingFour(
  itemBuilder: (BuildContext context, int index) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: index.isEven
            ? const Color.fromARGB(255, 255, 255, 255)
            : Colors.grey,
      ),
    );
  },
);
