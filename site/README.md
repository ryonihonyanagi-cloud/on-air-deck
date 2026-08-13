# ON AIR Deck landing page

公式配布LPのソースです。macOSアプリ本体のリポジトリ内に置き、公開30日で500 GitHub Starsを初期目標に設計しています。

## 主な構成

- LIVEとRECを同格で説明するプロダクトストーリー
- 実際のアプリ画面を使ったヒーロー
- 日本語、英語、簡体字中国語、韓国語の切り替え
- GitHub Starを主CTAに統一
- 1200 × 630 pxのOG画像
- デスクトップ／モバイル対応

## ローカル起動

Node.js 22.13以降が必要です。

```bash
npm install
npm run dev
```

`http://localhost:3000/` を開きます。

## 検証

```bash
npm run lint
npm test
npm audit --omit=dev
```

`npm test` は本番ビルド後、SSRされたHTML、GitHub CTA、OGメタデータ、4言語コピー、公開アセットを検証します。

## 公開前に確認するもの

- GitHubリポジトリ `ryonihonyanagi-cloud/on-air-deck` を公開してCTAを有効にする
- 正式なLP URLが決まったらOG URLとcanonicalを実環境で確認する
- アプリの署名、公証、素材権利、クリーンMac検証が完了するまでダウンロードCTAを追加しない
- ログアウト状態と実機モバイルでリンク・言語切り替えを最終確認する

外部公開はリポジトリ公開と同じタイミングで行います。
