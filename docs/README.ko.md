# ON AIR Deck

**팟캐스트, 라디오 스타일 녹음, 라이브 스트리밍을 위한 macOS 네이티브 방송 콘솔입니다.**

[English](../README.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

ON AIR Deck은 마이크, BGM, 징글, 효과음을 하나의 48 kHz 오디오 그래프에서 믹스합니다.
`LIVE`는 동봉된 가상 마이크를 통해 Zoom, Google Meet, OBS로 믹스를 보냅니다.
`REC`는 같은 퍼포먼스를 48 kHz, 24-bit, stereo WAV로 직접 녹음합니다.

외장 오디오 인터페이스, BlackHole 라우팅, OBS 오디오 구성, Zoom 컴퓨터 오디오 공유가 필요하지 않습니다.

## 주요 기능

- 동등한 비중의 `LIVE`와 `REC` 작업 흐름.
- 원클릭 WAV 녹음과 LIVE 백업 녹음.
- 드래그 앤 드롭, 파형, 단축키를 지원하는 12개 샘플 패드.
- 검색, 반복, 2초 페이드를 지원하는 영구 BGM 라이브러리.
- 목소리에만 적용되는 `SLAP`, `ECHO`, `BIG TITLE` 효과.
- 기본으로 켜지고 언제든 끌 수 있는 76 스타일 보이스 컴프레서.
- BGM 더킹, 피크 리미터, 독립 모니터링, 실시간 레벨 미터.
- 일본어, 영어, 중국어 간체, 한국어 UI.
- Apple Silicon과 Intel Mac을 지원하는 Universal Binary.

## 빠른 시작

녹음하려면 앱을 열고 `REC`를 선택한 뒤 마이크를 고르고 녹음 버튼을 누르세요.
기본 저장 폴더는 `~/Music/ON AIR Deck Recordings`입니다.

방송하려면 서명된 배포 패키지의 오디오 드라이버를 먼저 설치하고 앱에서 `LIVE`를 선택한 뒤 Zoom, Meet, OBS의 마이크를 `ON AIR Deck`으로 설정하세요.

## 빌드

[XcodeGen](https://github.com/yonaskolb/XcodeGen)을 설치한 뒤 다음을 실행하세요.

```bash
xcodegen generate
./scripts/test.sh
```

공개 배포 전에는 최종 라이선스 선택, 번들 오디오 권리 확인, Developer ID 서명, Apple 공증, 깨끗한 Mac 검증이 필요합니다.
현재 상태는 [릴리스 체크리스트](OSS_RELEASE_CHECKLIST.md)를 확인하세요.
