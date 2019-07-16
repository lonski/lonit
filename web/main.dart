import 'dart:collection';
import 'dart:html';
import 'dart:math';

import 'cave_generator.dart';
import 'grid.dart';
import 'player.dart';
import 'tile.dart';

double aliveChance = 0.36;
int iterations = 5;
int birthTreshold = 5;
int survivalTreshold = 4;

void main() {
  Game().start();
}

class Game {
  static final int COLS = 180;
  static final int ROWS = 120;
  static final int TILE_SIZE = 4;
  static const int BALL_COUNT = 6;
  num gameTime = 0;
  num minFrameTime = 20; //50fps
  num maxFrameTime = 200;
  num _lastAnimateTime = 0;
  num _lastdt = 0;

  CanvasRenderingContext2D _ctx;
  CanvasElement _canvas;
  Keyboard _keyboard = Keyboard();
  Grid _cave;
  Player _player;
  List<Ball> _balls;
  State _state = State.NEXT_LEVEL;
  int _level = 1;
  Wait _gameOverScreenWait = Wait(1000);
  Wait _nextLevelScreenWait = Wait(100);

  Game() {
    querySelector("#wrapper").style.width = "${TILE_SIZE * COLS}px";
    _canvas = querySelector('#canvas');
    _ctx = _canvas.getContext("2d");
    _canvas.width = TILE_SIZE * COLS;
    _canvas.height = TILE_SIZE * ROWS;
  }

  void start() {
    _newLevel();
    _state = State.RUNNING;
    run();
  }

  void run() async {
    window.requestAnimationFrame(_getAnimateTime);
  }

  num get currentFrameRate => (_lastdt == 0) ? -1 : 1000 / _lastdt;

  void _getAnimateTime(num animateCallTime) {
    _lastAnimateTime = animateCallTime; // now we have start time with right resolution
    window.requestAnimationFrame(_gameLoop); // start animating
  }

  void _gameLoop(num animateCallTime) {
    window.requestAnimationFrame(_gameLoop);

    num dt = animateCallTime - _lastAnimateTime;

    if (dt < minFrameTime) return; // frame rate too high, drop this frame.
    if (dt > maxFrameTime) dt = minFrameTime; // consider just one frame elapsed if game tabbed out.

    gameTime += dt;
    _lastdt = dt;
    _lastAnimateTime = animateCallTime;

    _draw();
    _update();
  }

  void _draw() {
    _clear();
    if (_state == State.GAME_OVER) {
      _drawText("GAME OVER", 'red');
    } else if (_state == State.NEXT_LEVEL) {
      _drawText("LEVEL $_level", 'blue');
    } else if (_state == State.RUNNING) {
      _renderCave();
    }
  }

  void _update() {
    if (_state == State.NEXT_LEVEL) {
      _nextLevelScreenWait.update(_lastdt);
      if (_nextLevelScreenWait.isDone()) {
        _nextLevelScreenWait.reset();
        _newLevel();
        _state = State.RUNNING;
      }
    }

    if (_state == State.GAME_OVER) {
      _gameOverScreenWait.update(_lastdt);
      if (_gameOverScreenWait.isDone()) {
        _gameOverScreenWait.reset();
        _level -= 1;
        _handleNextLevel();
      }
    }

    if (_state == State.RUNNING) {
      _player.handleInput(_keyboard);
      _player.update();
      _handleBallCollision();

      if (_balls.isEmpty) {
        _handleNextLevel();
      } else if (_isWallCollision()) {
        _handleGameOver();
      }
    }
  }

  void _handleGameOver() {
    _state = State.GAME_OVER;
  }

  void _handleNextLevel() {
    _state = State.NEXT_LEVEL;
    _level = min(10, _level + 1);
  }

  void _drawText(String text, String color) {
    _ctx
      ..fillStyle = color
      ..font = 'bold 20px Verdana'
      ..textAlign = 'center'
      ..fillText(text, _canvas.width / 2, _canvas.height / 2);
  }

  void _renderCave() {
    _clear();
    _cave.points.forEach((p) => _cave.at(p).draw(p * TILE_SIZE, TILE_SIZE, _ctx));
    _player.draw(_ctx);
    _balls.forEach((b) => b.draw(_ctx));
  }

  bool _isWallCollision() {
    return _player.getCoords().map((p) => _cave.at(p)).any((t) => (t as Tile).color == 'black');
  }

  void _handleBallCollision() {
    final Ball ball = _isBallCollision();
    if (ball != null) {
      _balls.remove(ball);
      _player.velocity += 0.5;
    }
  }

  Ball _isBallCollision() {
    var coords = _player.getCoords();
    var collided = _balls.where((b) => coords.any((c) => b.getCoords().contains(c)));
    if (collided.isNotEmpty) {
      return collided.first;
    }
    return null;
  }

  void _newLevel() {
    _cave =
        CaveGenerator(COLS, ROWS).generate(aliveChance + (_level / 100), iterations, birthTreshold, survivalTreshold);
    _player = Player(_cave.findFreeSpot(8) * TILE_SIZE, TILE_SIZE);
    _balls = List.generate(BALL_COUNT, (i) => Ball(_cave.findFreeSpot(8) * TILE_SIZE, TILE_SIZE));
  }

  void _clear() {
    _ctx
      ..fillStyle = 'white'
      ..fillRect(0, 0, _canvas.width, _canvas.height)
      ..strokeStyle = 'black 4px'
      ..lineWidth = 4
      ..strokeRect(0, 0, _canvas.width, _canvas.height);
  }
}

enum State { RUNNING, GAME_OVER, NEXT_LEVEL }

class Wait {
  int _time;
  int _acc;

  Wait(this._time) : _acc = 0;

  void update(double dt) => _acc += dt.floor();

  bool isDone() => _acc >= _time;

  void reset() => _acc = 0;
}

class Keyboard {
  HashMap<int, num> _keys = HashMap();

  Keyboard() {
    window.onKeyDown.listen((KeyboardEvent event) => _keys.putIfAbsent(event.keyCode, () => event.timeStamp));
    window.onKeyUp.listen((KeyboardEvent event) => _keys.remove(event.keyCode));
  }

  bool isPressed(int keyCode) => _keys.containsKey(keyCode);
}
