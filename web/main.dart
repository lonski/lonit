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
  num _lastTimeStamp = 0;

  CanvasRenderingContext2D _ctx;
  CanvasElement _canvas;
  Keyboard _keyboard = Keyboard();
  Grid _cave;
  Player _player;
  List<Ball> _balls;
  State _state = State.NEW_GAME;
  int _level = 1;
  int _gameSpeed = 40;
  Wait _gameOverScreenWait = Wait(1000);

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
    update(await window.animationFrame);
  }

  void update(num delta) {
    final num diff = delta - _lastTimeStamp;

    if (diff > _gameSpeed) {
      _lastTimeStamp = delta;

      if (_state == State.NEXT_LEVEL) {
        _newLevel();
        _state = State.RUNNING;
      }

      if (_state == State.GAME_OVER) {
        _gameOverScreenWait.update(diff);
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
          _player.dir = null;
        } else if (_isWallCollision()) {
          _handleGameOver();
        } else {
          _render();
        }
      }
    }

    run();
  }

  void _handleGameOver() {
    _state = State.GAME_OVER;
    _clear();
    _drawText("GAME OVER", 'red');
  }

  void _handleNextLevel() {
    _state = State.NEXT_LEVEL;
    _clear();
    _level = min(10, _level + 1);
    _drawText("LEVEL $_level", 'blue');
  }

  void _drawText(String text, String color) {
    _ctx
      ..fillStyle = color
      ..font = 'bold 20px Verdana'
      ..textAlign = 'center'
      ..fillText(text, _canvas.width / 2, _canvas.height / 2);
  }

  void _render() {
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

enum State { NEW_GAME, RUNNING, GAME_OVER, NEXT_LEVEL }

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
