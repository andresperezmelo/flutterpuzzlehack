import 'dart:async';

class BlocBase {}

class ResetTime extends BlocBase {}

class StartTime extends BlocBase {}

class StopTime extends BlocBase {}

class BlocTimer {
  StreamController<BlocBase> _input = StreamController.broadcast();
  StreamSink<BlocBase> get sentEvent => _input.sink;

  final StreamController<int> _timerController = StreamController<int>.broadcast();
  Stream<int> get timerStream => _timerController.stream;

  int _currentSeconds = 0;
  Timer? timer;

  BlocTimer() {
    //_runTimer();
    _input.stream.listen(_onEvent);
  }

  void _onEvent(BlocBase event) {
    if (event is ResetTime) {
      _currentSeconds = 0;
    } else if (event is StartTime) {
      _runTimer();
    } else if (event is StopTime) {
      timer?.cancel();
    }
    _timerController.sink.add(_currentSeconds);
  }

  void _runTimer() async {
    timer?.cancel();
    _currentSeconds = 0;
    timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      _currentSeconds++;
      _timerController.add(_currentSeconds);
    });
  }

  void dispose() {
    _input.close();
    _timerController.close();
    if (timer != null) {
      timer!.cancel();
    }
  }
}
