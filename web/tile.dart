import 'dart:html';
import 'dart:math';

class Tile {
  String color;

  Tile() : color = 'black';

  Tile.withColor(this.color);

  void draw(Point p, int size, CanvasRenderingContext2D ctx) {
    ctx
      ..fillStyle = color
      ..fillRect(p.x, p.y, size, size);
  }
}
