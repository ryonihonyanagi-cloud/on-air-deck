# ON AIR Deck

**面向播客、广播式录音和直播的原生 macOS 播出控制台。**

[English](../README.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

ON AIR Deck 在一个 48 kHz 音频图中混合麦克风、BGM、片头音和音效。
`LIVE` 模式通过随附的虚拟麦克风将混音发送到 Zoom、Google Meet 或 OBS。
`REC` 模式将同一场演出直接录制为 48 kHz、24-bit、立体声 WAV。

无需外置音频接口、BlackHole 路由、OBS 音频工程或 Zoom 的电脑声音共享。

## 主要功能

- 同等重要的 `LIVE` 与 `REC` 工作流。
- 一键 WAV 录音和 LIVE 备份录音。
- 十二个支持拖放、波形和快捷键的采样垫。
- 支持搜索、循环和两秒淡化的持久 BGM 曲库。
- 仅作用于人声的 `SLAP`、`ECHO` 和 `BIG TITLE` 效果。
- 默认开启且可随时关闭的 76 风格人声压缩器。
- BGM 闪避、峰值限制器、独立监听和实时电平表。
- 日语、英语、简体中文和韩语界面。
- 支持 Apple Silicon 与 Intel Mac 的通用二进制文件。

## 快速开始

录音时，打开应用、选择 `REC`、选择麦克风并按下录音键。
默认文件夹为 `~/Music/ON AIR Deck Recordings`。

直播时，先安装签名发行包中的音频驱动，在应用中选择 `LIVE`，然后在 Zoom、Meet 或 OBS 中把麦克风设为 `ON AIR Deck`。

## 构建

安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen)，然后运行：

```bash
xcodegen generate
./scripts/test.sh
```

公开发布仍需完成许可证选择、内置音频素材权利确认、Developer ID 签名、Apple 公证和干净 Mac 验证。
详情请参阅[发布检查表](OSS_RELEASE_CHECKLIST.md)。
