import 'dart:core';
import 'dart:html';

import 'main.dart';
import 'tile.dart';

class Player {
  static const Point LEFT = const Point(-1, 0);
  static const Point RIGHT = const Point(1, 0);
  static const Point UP = const Point(0, -1);
  static const Point DOWN = const Point(0, 1);
  static const int START_LENGTH = 6;

  int tileSize;
  Point pos;
  Tile tile;
  List<Point> points;
  Point dir;
  double velocity = 2;

  Player(this.pos, this.tileSize) {
    tile = Tile.withColor('red');
    points = [Point(1, 1)];
  }

  Set<Point> getCoords() {
    Point coordPos = Point(pos.x ~/ tileSize, pos.y ~/ tileSize);
    Set<Point> coords = Set();
    coords.addAll(points.map((p) => p + coordPos));
    if (pos.x % tileSize > 0) {
      coords.addAll(points.map((p) => p + coordPos + Point(1, 0)));
    }
    if (pos.y % tileSize > 0) {
      coords.addAll(points.map((p) => p + coordPos + Point(0, 1)));
    }
    if (pos.y % tileSize > 0 && pos.x % tileSize > 0) {
      coords.addAll(points.map((p) => p + coordPos + Point(1, 1)));
    }
    return coords;
  }

  void draw(CanvasRenderingContext2D ctx) {
    points.forEach((p) {
      tile.draw((p * tileSize + pos), tileSize, ctx);
    });
  }

  void handleInput(Keyboard keyboard) {
    if (keyboard.isPressed(KeyCode.LEFT) && keyboard.isPressed(KeyCode.DOWN)) {
      dir = LEFT + DOWN;
    } else if (keyboard.isPressed(KeyCode.LEFT) && keyboard.isPressed(KeyCode.UP)) {
      dir = LEFT + UP;
    } else if (keyboard.isPressed(KeyCode.RIGHT) && keyboard.isPressed(KeyCode.UP)) {
      dir = RIGHT + UP;
    } else if (keyboard.isPressed(KeyCode.RIGHT) && keyboard.isPressed(KeyCode.DOWN)) {
      dir = RIGHT + DOWN;
    } else if (keyboard.isPressed(KeyCode.LEFT)) {
      dir = LEFT;
    } else if (keyboard.isPressed(KeyCode.RIGHT)) {
      dir = RIGHT;
    } else if (keyboard.isPressed(KeyCode.UP)) {
      dir = UP;
    } else if (keyboard.isPressed(KeyCode.DOWN)) {
      dir = DOWN;
    } else if (keyboard.isPressed(KeyCode.SPACE)) {
      dir = null;
    }
  }

  void update() {
    if (dir != null) pos += dir * velocity;
  }
}

class Ball {
  List<Point> points;
  Tile tile;
  int tileSize;
  Point pos;

  Ball(this.pos, this.tileSize) {
    points = [
      Point(1, 0),
      Point(0, 1),
      Point(1, 1),
      Point(2, 1),
      Point(1, 2),
    ];
    tile = Tile.withColor('lime');
  }

  Set<Point> getCoords() {
    Point coordPos = Point(pos.x ~/ tileSize, pos.y ~/ tileSize);
    return points.map((p) => p + coordPos).toSet();
  }

  void draw(CanvasRenderingContext2D ctx) {
    points.forEach((p) {
      tile.draw((p * tileSize + pos), tileSize, ctx);
    });
  }
}
