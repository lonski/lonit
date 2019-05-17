import 'dart:math';

import 'grid.dart';
import 'tile.dart';

class CaveGenerator {
  static final String DEAD_COLOR = 'white';
  static final String ALIVE_COLOR = 'black';
  final int _width;
  final int _height;
  final Random _rng;
  Grid _grid;

  CaveGenerator(this._width, this._height) : _rng = Random();

  Grid generate(double aliveChance, int iterations, int birthTreshold, int survivalTreshold) {
    print("Generating cave: aliveCHance=$aliveChance, iterations=$iterations," +
        " birthTreshold=$birthTreshold, survivalTreshold=$survivalTreshold");
    int t1 = DateTime.now().millisecondsSinceEpoch;
    _grid = Grid<Tile>(_width, _height);

    _generateCells(aliveChance);
    _cellularAutomata(iterations, birthTreshold, survivalTreshold);
    _removeSmallObjects(6);

    print("Generation took: ${(DateTime.now().millisecondsSinceEpoch - t1) / 1000.0}s");
    return _grid;
  }

  void _removeSmallObjects(int rectDiag) {
    int t1 = DateTime.now().millisecondsSinceEpoch;
    _grid.points.forEach((p) {
      Tile tile = _grid.at(p);
      if (isAlive(tile)) {
        if (_grid.neighbours(p).where(isAlive).isEmpty) {
          setDead(tile);
        } else {
          if (_grid.getPointsInRectBorder(rectDiag, p).map(_grid.at).where(isAlive).isEmpty)
            _grid.getPointsInRect(rectDiag, p).map(_grid.at).forEach(setDead);
        }
      }
    });
    print("Removing small objects took: ${(DateTime.now().millisecondsSinceEpoch - t1) / 1000.0}s");
  }

  void _cellularAutomata(int iterations, int birthTreshold, int survivalTreshold) {
    int t1 = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < iterations; i++) {
      _grid.points.forEach((p) {
        Tile tile = _grid.at(p);
        List<Tile> neigbours = _grid.neighbours(p);
        int aliveCount = neigbours.where(isAlive).length;
        if (!isAlive(tile) && aliveCount >= birthTreshold) {
          setAlive(tile);
        } else if (isAlive(tile) && aliveCount < survivalTreshold) {
          setDead(tile);
        }
      });
    }
    print("Celular automata took: ${(DateTime.now().millisecondsSinceEpoch - t1) / 1000.0}s");
  }

  bool isAlive(dynamic tile) {
    return tile?.color == ALIVE_COLOR;
  }

  void setDead(dynamic tile) {
    tile?.color = DEAD_COLOR;
  }

  void setAlive(dynamic tile) {
    tile?.color = ALIVE_COLOR;
  }

  void _generateCells(double aliveChance) {
    final int border = 2;
    _grid.points.forEach((p) {
      String color = _rng.nextDouble() > aliveChance ? DEAD_COLOR : ALIVE_COLOR;
      if (p.x <= border || p.x >= _grid.width - border || p.y <= border || p.y >= _grid.height - border) {
        color = ALIVE_COLOR;
      }
      _grid.set(p, Tile.withColor(color));
    });
  }
}
