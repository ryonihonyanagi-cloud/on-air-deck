# ON AIR Deck OSS launch kit

このファイルは、GitHub公開時にそのまま使える文面と設定値をまとめます。

署名、公証、素材権利の検収が終わるまで、公開投稿には使用しません。

## Repository settings

Repository name:

```text
on-air-deck
```

About description:

```text
Native macOS broadcast desk that mixes mic, BGM, jingles and SFX for Zoom, Meet and OBS, or records the same performance to 48 kHz / 24-bit WAV.
```

Suggested topics:

```text
macos swift swiftui podcast radio audio sampler coreaudio virtual-audio-device zoom obs
```

Website fieldは、公開リポジトリ以外の正式な製品サイトができるまで空欄にします。

Social Previewには`docs/assets/social-preview.png`を使用します。

## GitHub release draft

Title:

```text
ON AIR Deck 2.1.0 — Radio-style podcast production for macOS
```

Body:

```markdown
ON AIR Deck turns one Mac into a radio-style production desk.

Choose LIVE to mix your microphone, BGM, jingles, and sound effects into one virtual microphone for Zoom, Google Meet, or OBS.
Choose REC to capture the same performance directly as a 48 kHz, 24-bit stereo WAV file.

Highlights:

- Equal-first LIVE and REC workflows.
- Twelve drag-and-drop sample pads.
- Persistent multi-track BGM library.
- Voice-only SLAP, ECHO, and BIG TITLE effects.
- A restrained 76-style voice compressor enabled by default.
- English, Japanese, Simplified Chinese, and Korean UI.
- Universal Binary for Apple Silicon and Intel Macs.

Read the installation notes before installing the optional virtual audio driver.
Verify the SHA-256 checksum after downloading.
```

公開時は、最後に署名、公証、対応macOS、既知の問題、SHA-256を追記します。

## 日本語告知案

長文:

```text
ポッドキャストを、本物のラジオ収録へ。

マイク、BGM、ジングル、効果音を、一つのMacで演奏しながら収録・配信できる「ON AIR Deck」をOSSで公開します。

RECなら、RECボタンを押すだけで48 kHz／24-bit／stereo WAVへ保存できます。
LIVEなら、同じミックスを仮想マイクとしてZoom、Google Meet、OBSへ送れます。

BlackHoleの複雑な配線も、OBSの音声構築も、外部オーディオインターフェースも必須ではありません。

ただ喋るだけのポッドキャストから、BGM、ジングル、効果音、声の演出があるラジオへ。
```

短文:

```text
ポッドキャストを、本物のラジオ収録へ。
マイク、BGM、ジングル、効果音、声のFXを一つのMacで演奏し、そのままWAV収録またはZoom／Meet／OBSへ送れる「ON AIR Deck」をOSS公開します。
```

## English announcement

```text
Turn your podcast into a real radio performance.

ON AIR Deck mixes your microphone, BGM, jingles, sound effects, and voice effects on one Mac, then records the complete performance to WAV or sends it to Zoom, Meet, and OBS through one virtual microphone.

Open source for podcasters and streamers who want the sound of a broadcast desk without building a complicated audio-routing setup.
```

## 简体中文简介

```text
让播客真正拥有广播节目的演出感。
ON AIR Deck 可在一台 Mac 上混合麦克风、BGM、片头音、音效和人声效果，并直接录制为 WAV，或通过一个虚拟麦克风发送到 Zoom、Meet 和 OBS。
```

## 한국어 소개

```text
팟캐스트를 실제 라디오 퍼포먼스로 바꾸세요.
ON AIR Deck은 한 대의 Mac에서 마이크, BGM, 징글, 효과음, 보이스 효과를 믹스하고, 완성된 퍼포먼스를 WAV로 녹음하거나 하나의 가상 마이크로 Zoom, Meet, OBS에 보냅니다.
```

## Media checklist

- [x] GitHub Social Previewを1280 × 640 pxで用意した。
- [x] README用の実画面を用意した。
- [x] 画像の用途とalt textを`BRAND_ASSETS.md`へ記録した。
- [ ] 署名、公証、素材権利の完了後に、文面の「公開します」を「公開しました」へ変更する。
- [ ] 公開URLを追加する。
- [ ] ログアウト状態で画像とリンクカードを確認する。
