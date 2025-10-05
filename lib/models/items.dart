mixin Items {
  double? score;

  double minScore=0.0;
  double maxScore=10.0;

  void setScore(double newScore) {
  final clamped = newScore.clamp(minScore, maxScore).toDouble();
  score = clamped;  
  }
}