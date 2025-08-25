// lib/models/motivation.dart

enum MotivationType {
  emotional, // 감성 자극형
  futureVision, // 미래/비전 제시형
  action, // 구체적 행동 제시형
  competition, // 비교/경쟁 자극형
}

String motivationTypeLabel(MotivationType type) {
  switch (type) {
    case MotivationType.emotional:
      return '감성 자극형';
    case MotivationType.futureVision:
      return '미래/비전 제시형';
    case MotivationType.action:
      return '구체적 행동 제시형';
    case MotivationType.competition:
      return '비교/경쟁 자극형';
  }
}

MotivationType motivationTypeFromString(String? type) {
  switch (type) {
    case 'EMOTIONAL':
      return MotivationType.emotional;
    case 'VISION':
      return MotivationType.futureVision;
    case 'ACTION':
      return MotivationType.action;
    case 'COMPETITION':
      return MotivationType.competition;
    default:
      return MotivationType.emotional;
  }
}