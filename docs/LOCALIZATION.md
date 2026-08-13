# ローカライズ運用

ON AIR Deckは、英語、日本語、簡体字中国語、韓国語に対応します。

## 対応ロケール

| 言語 | ロケール | リソース |
| --- | --- | --- |
| English | `en` | `OnAirDeck/Resources/en.lproj` |
| 日本語 | `ja` | `OnAirDeck/Resources/ja.lproj` |
| 简体中文 | `zh-Hans` | `OnAirDeck/Resources/zh-Hans.lproj` |
| 한국어 | `ko` | `OnAirDeck/Resources/ko.lproj` |

各ロケールには、UI用の`Localizable.strings`と、マイク権限説明用の`InfoPlist.strings`があります。

## 文字列を追加する

1. 英語の意味が分かる安定したキーを決めます。
2. 四つの`Localizable.strings`へ、同じキーを追加します。
3. SwiftUIの文字列リテラルでない動的表示は、`L10n.text`または`L10n.format`を使います。
4. `./scripts/validate-localizations.sh`を実行します。
5. 四言語で起動し、切れ、重なり、意味のずれ、VoiceOverラベルを確認します。

`Text("key")`や`Button("key")`のようなSwiftUIの文字列リテラルは、自動的にローカライズされます。

変数から渡す文字列や、文字列補間したアクセシビリティラベルは、自動ローカライズを前提にしません。

## 自動検証

次のコマンドは、四言語のplist構文とキー集合の一致を検証します。

```bash
./scripts/validate-localizations.sh
```

CIでも同じ検証を実行します。

## 手動表示確認

開発版を特定言語で起動する例です。

```bash
open -n /path/to/OnAirDeck.app --args -AppleLanguages '(ja)' -AppleLocale ja_JP
open -n /path/to/OnAirDeck.app --args -AppleLanguages '(en)' -AppleLocale en_US
open -n /path/to/OnAirDeck.app --args -AppleLanguages '(zh-Hans)' -AppleLocale zh_CN
open -n /path/to/OnAirDeck.app --args -AppleLanguages '(ko)' -AppleLocale ko_KR
```

最低限、モード選択、LIVE、REC、Zoomガイド、録音完了、エラー表示、マイク権限説明を確認します。

## 用語方針

`LIVE`、`REC`、`BGM`、`WAV`、`SLAP`、`ECHO`、`BIG TITLE`、`76 COMP`は、放送卓上の短いラベルとして原則維持します。

説明文、状態、アクセシビリティラベルは、各言語の自然な表現へ翻訳します。

音源ファイル名とユーザーが付けたタイトルは翻訳しません。
