/// يمثل خلية في الشبكة المكانية
class GridCell {
  final int x;
  final int y;

  GridCell(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridCell &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'GridCell[x=$x, y=$y]';
}
