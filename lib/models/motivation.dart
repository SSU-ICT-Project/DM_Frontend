enum MotivationType {
  HABITUAL_WATCHER, // 습관적 시청형
  COMFORT_SEEKER,   // 위로 추구형
  THRILL_SEEKER,    // 자극 추구형
}

String motivationTypeLabel(MotivationType type) {
  switch (type) {
    case MotivationType.HABITUAL_WATCHER:
      return '습관적 시청형';
    case MotivationType.COMFORT_SEEKER:
      return '위로 추구형';
    case MotivationType.THRILL_SEEKER:
      return '자극 추구형';
  }
}

String motivationTypeDescription(MotivationType type) {
  switch (type) {
    case MotivationType.HABITUAL_WATCHER:
      return '지금 5분만 멈추면, 내일이 달라집니다.';
    case MotivationType.COMFORT_SEEKER:
      return '피곤할 땐 쉬어도 돼요. 하지만 진짜 회복은 목표에 다가설 때 옵니다.';
    case MotivationType.THRILL_SEEKER:
      return '쇼츠가 널 잡을까, 네가 이길까? 지금 선택해보세요.';
  }
}



