/// Public interface that Dashboard can use without referencing the private State class
abstract class HistoryPageBackHandler {
  /// Return false if the back press was handled inside HistoryPage
  /// (i.e., don't pop Dashboard).
  Future<bool> handleWillPop();
}
