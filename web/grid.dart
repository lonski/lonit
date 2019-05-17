import 'dart:html';

import 'tile.dart';

class Grid<T> {
  final int width;
  final int height;
  final List<Point> points;
  List<T> tiles;

  Grid(this.width, this.height)
      : points = _initPoints(width, height),
        tiles = List(width * height);

  static List<Point> _initPoints(int w, int h) {
    final List<Point> points = List();
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        points.add(Point(x, y));
      }
    }
    points.shuffle();
    return points;
  }

  T at(Point p) {
    int coord = p.y * width + p.x;
    if (coord >= 0 && coord < tiles.length) return tiles[p.y * width + p.x];
    return null;
  }

  List<T> neighbours(Point p) {
    return [
      at(Point(p.x - 1, p.y)),
      at(Point(p.x + 1, p.y)),
      at(Point(p.x, p.y - 1)),
      at(Point(p.x, p.y + 1)),
      at(Point(p.x - 1, p.y - 1)),
      at(Point(p.x - 1, p.y + 1)),
      at(Point(p.x + 1, p.y - 1)),
      at(Point(p.x + 1, p.y + 1)),
    ].where((t) => t != null).toList();
  }

  void set(Point p, T tile) {
    if (p.x >= width) throw "x=$p.x is too high (grid width=$width)";
    if (p.y >= height) throw "y=$p.y is too high (grid height=$height";

    tiles[p.y * width + p.x] = tile;
  }

  void fill(T tile) {
    points.forEach((p) => set(p, tile));
  }

  Point<num> findFreeSpot(int rectDiag) {
    points.shuffle();
    Point start = Point(0, 0);
    for (Point p in points) {
      var rect = getPointsInRect(rectDiag, p).map(at);
      if (rect.every((t) => (t as Tile)?.color == 'white')) {
        start = p;
        break;
      }
    }
    return start;
  }

  Set<Point> getPointsInRect(int rectDiagonal, Point center) {
    final Point start = center - Point(rectDiagonal / 2, rectDiagonal / 2);
    final Point end = center + Point(rectDiagonal / 2, rectDiagonal / 2);

    final Set<Point> r = Set();
    for (int y = start.y; y <= end.y; y++) {
      for (int x = start.x; x <= end.x; x++) {
        r.add(Point(x, y));
      }
    }

    return r;
  }

  Set<Point> getPointsInRectBorder(int rectDiagonal, Point center) {
    final Point start = center - Point(rectDiagonal ~/ 2, rectDiagonal ~/ 2);
    final Point end = center + Point(rectDiagonal ~/ 2, rectDiagonal ~/ 2);

    final Set<Point> r = Set();
    for (int x = start.x; x <= end.x; x++) {
      r.add(Point(x, start.y));
      r.add(Point(x, end.y));
    }
    for (int y = start.y; y <= end.y; y++) {
      r.add(Point(start.x, y));
      r.add(Point(end.x, y));
    }

    return r;
  }
}
