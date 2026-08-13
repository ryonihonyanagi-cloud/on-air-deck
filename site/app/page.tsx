"use client";

import { useState } from "react";
import Image from "next/image";

const GITHUB_URL = "https://github.com/ryonihonyanagi-cloud/on-air-deck";

type Language = "ja" | "en" | "zh" | "ko";

const copy = {
  ja: {
    navFeatures: "機能",
    navWorkflow: "使い方",
    navOpenSource: "OSS",
    star: "GitHubでスター",
    eyebrow: "NATIVE macOS BROADCAST DESK · OPEN SOURCE",
    titleA: "ポッドキャストを、",
    titleB: "本物のラジオへ。",
    lead: "マイク、BGM、ジングル、効果音、声のFXを一つのMacで演奏。そのままWAVに録るか、Zoom・Meet・OBSへ届けられます。",
    viewWorkflow: "仕組みを見る",
    targetLabel: "LAUNCH GOAL",
    target: "公開30日で 500 STARS",
    status: "macOS 14+ · MIT LICENSE · 4 LANGUAGES",
    proof: "複雑なオーディオ配線を、ひとつのデスクに。",
    proofBody: "BlackHoleのルーティングも、OBSの音声構築も、外部オーディオインターフェースも必須ではありません。ON AIR Deckが、あなたのマイクと音源を一つの48 kHzミックスにします。",
    before: "BEFORE",
    after: "WITH ON AIR DECK",
    beforeItems: ["仮想デバイスの配線図", "OBSの複雑な音声設定", "外部機材とケーブル", "録音後にすべて後編集"],
    afterItems: ["マイクを選ぶ", "BGMやパッドを鳴らす", "RECまたはLIVEを押す"],
    workflowEyebrow: "TWO MODES. ONE PERFORMANCE.",
    workflowTitle: "録音も、配信も。主役はあなたの演奏。",
    workflowBody: "同じミックスを、目的に合わせてWAVにも仮想マイクにも出力できます。",
    liveLabel: "LIVE MODE",
    liveTitle: "配信アプリへ、そのまま。",
    liveBody: "Zoom、Google Meet、OBSのマイクに「ON AIR Deck」を選ぶだけ。声と音源を同時に届けます。",
    liveSteps: ["入力マイクを選択", "ON AIR Deckを配信先のマイクに設定", "声とBGMのメーターを確認"],
    recLabel: "REC MODE",
    recTitle: "RECを押せば、番組になる。",
    recBody: "演奏した完成ミックスを48 kHz／24-bit／stereo WAVへ。録音後は好きなDAWで編集できます。",
    recSteps: ["保存先を確認", "赤いRECボタンを押す", "停止後、WAVをFinderで開く"],
    featuresEyebrow: "BUILT FOR RADIO-STYLE PERFORMANCE",
    featuresTitle: "喋るだけ、から演奏するポッドキャストへ。",
    features: [
      ["01", "12 SAMPLE PADS", "音源をドラッグ＆ドロップ。波形とショートカット付きで、ジングルもSEも一発再生。"],
      ["02", "BGM DECK", "曲をキューに追加し、ループ、フェード、ダッキングまでひとつのデックで操作。"],
      ["03", "VOICE FX", "SLAP、ECHO、BIG TITLE。タイトルコールをその場でラジオらしく演出。"],
      ["04", "76-STYLE COMP", "声のダイナミクスを自然に整えるコンプを標準搭載。いつでもON／OFF可能。"],
      ["05", "VOICE MONITOR", "自分の声と完成ミックスをヘッドホンで確認。届いている音を耳でも判断。"],
      ["06", "SAFE MASTER", "最終段のピークリミッターで、声・BGM・SEをまとめた出力を安全に管理。"],
    ],
    verifiedEyebrow: "ENGINEERED, NOT MOCKED",
    verifiedTitle: "見た目だけじゃない。音が通るところまで作った。",
    stats: [["9", "AUTOMATED TESTS"], ["48 / 24", "kHz / BIT WAV"], ["2", "APPLE + INTEL"], ["4", "UI LANGUAGES"]],
    verifiedBody: "アプリと仮想オーディオドライバはローカル環境でビルド・動作検証済み。公開版はDeveloper ID署名、公証、クリーンMac検証を完了してから配布します。",
    ossEyebrow: "OPEN SOURCE · MIT",
    ossTitle: "ラジオを作る楽しさを、もっと多くの人へ。",
    ossBody: "ON AIR Deckは、音声配信の難しいセットアップをなくすためのオープンソースプロジェクトです。スターは、このプロジェクトを次の人へ届ける一番シンプルな応援になります。",
    ossPoints: ["ロードマップを追う", "Issueで改善を提案", "コードや翻訳に参加"],
    goalSmall: "30-DAY LAUNCH MISSION",
    goalTitle: "500",
    goalUnit: "GITHUB STARS",
    goalBody: "最初の500人と、本格的なラジオ収録をもっと身近にする。",
    faqTitle: "よくある質問",
    faqs: [
      ["録音だけでも使えますか？", "はい。RECモードは仮想ドライバなしで使えます。マイク、BGM、パッド、声のFXをまとめてWAVへ録音します。"],
      ["ZoomやMeetでは何を設定しますか？", "ON AIR DeckのLIVEモードを起動し、配信アプリ側のマイクとして「ON AIR Deck」を選びます。"],
      ["外部オーディオインターフェースは必要ですか？", "必須ではありません。Mac内蔵マイクやUSBマイクでも使えます。もちろん既存のオーディオインターフェースも選択できます。"],
      ["Windows版はありますか？", "現在はmacOS 14以降向けです。まずmacOS版を安定させ、今後の展開はGitHubで共有します。"],
    ],
    finalEyebrow: "READY TO GO ON AIR?",
    finalTitle: "次の収録を、番組にしよう。",
    finalBody: "GitHubでスターして、公開とアップデートを追ってください。",
    footerNote: "Built for podcasters, streamers, and radio lovers.",
  },
  en: {
    navFeatures: "Features", navWorkflow: "How it works", navOpenSource: "Open source", star: "Star on GitHub",
    eyebrow: "NATIVE macOS BROADCAST DESK · OPEN SOURCE", titleA: "Turn your podcast into", titleB: "a real radio performance.",
    lead: "Perform with your mic, BGM, jingles, SFX, and voice effects on one Mac. Record it to WAV or send the complete mix to Zoom, Meet, and OBS.",
    viewWorkflow: "See how it works", targetLabel: "LAUNCH GOAL", target: "500 STARS IN 30 DAYS", status: "macOS 14+ · MIT LICENSE · 4 LANGUAGES",
    proof: "One broadcast desk. No routing maze.", proofBody: "No mandatory BlackHole routing, OBS audio build, or external interface. ON AIR Deck turns your microphone and sounds into one 48 kHz mix.",
    before: "BEFORE", after: "WITH ON AIR DECK", beforeItems: ["Virtual-device diagrams", "Complex OBS audio setup", "Extra hardware and cables", "Rebuild everything in post"], afterItems: ["Choose your mic", "Play music and pads", "Press REC or LIVE"],
    workflowEyebrow: "TWO MODES. ONE PERFORMANCE.", workflowTitle: "Record or go live. Your performance stays central.", workflowBody: "Send the same finished mix to a WAV file or a virtual microphone.",
    liveLabel: "LIVE MODE", liveTitle: "Straight into your streaming app.", liveBody: "Select ON AIR Deck as the microphone in Zoom, Google Meet, or OBS. Your voice and sounds arrive together.", liveSteps: ["Choose an input mic", "Select ON AIR Deck at the destination", "Confirm voice and BGM meters"],
    recLabel: "REC MODE", recTitle: "Press REC. Make a show.", recBody: "Capture your performance as 48 kHz / 24-bit stereo WAV, ready for any DAW.", recSteps: ["Confirm the save folder", "Press the red REC button", "Reveal the WAV in Finder"],
    featuresEyebrow: "BUILT FOR RADIO-STYLE PERFORMANCE", featuresTitle: "Go beyond talking. Perform your podcast.",
    features: [["01","12 SAMPLE PADS","Drop in audio files, see their waveforms, and fire jingles or SFX with keyboard shortcuts."],["02","BGM DECK","Queue tracks and control loops, fades, and ducking from one focused deck."],["03","VOICE FX","SLAP, ECHO, and BIG TITLE bring instant broadcast character to your voice."],["04","76-STYLE COMP","A restrained, switchable voice compressor keeps speech present and controlled."],["05","VOICE MONITOR","Hear your voice and finished mix in headphones, so you know exactly what is going out."],["06","SAFE MASTER","A final peak limiter keeps the combined mic, music, and SFX output under control."]],
    verifiedEyebrow: "ENGINEERED, NOT MOCKED", verifiedTitle: "Designed to look right. Engineered to pass audio.", stats: [["9","AUTOMATED TESTS"],["48 / 24","kHz / BIT WAV"],["2","APPLE + INTEL"],["4","UI LANGUAGES"]], verifiedBody: "The app and virtual audio driver build and run locally. Public binaries will ship after Developer ID signing, notarization, and clean-Mac verification.",
    ossEyebrow: "OPEN SOURCE · MIT", ossTitle: "Make radio-style production accessible to everyone.", ossBody: "ON AIR Deck is an open-source project built to remove the setup barrier from expressive audio. A star is the simplest way to help more creators find it.", ossPoints: ["Follow the roadmap", "Shape it through Issues", "Contribute code or translation"],
    goalSmall: "30-DAY LAUNCH MISSION", goalTitle: "500", goalUnit: "GITHUB STARS", goalBody: "Find the first 500 people who want real radio production without the routing headache.",
    faqTitle: "Frequently asked questions", faqs: [["Can I use it only for recording?","Yes. REC mode works without the virtual driver and records mic, BGM, pads, and voice FX to WAV."],["What do I select in Zoom or Meet?","Start LIVE mode, then choose ON AIR Deck as the microphone in your destination app."],["Do I need an audio interface?","No. Use a built-in or USB mic, or select your existing interface if you have one."],["Is there a Windows version?","Today, ON AIR Deck targets macOS 14 and later. Future plans will be shared on GitHub."]],
    finalEyebrow: "READY TO GO ON AIR?", finalTitle: "Turn your next recording into a show.", finalBody: "Star the project on GitHub and follow the launch.", footerNote: "Built for podcasters, streamers, and radio lovers.",
  },
  zh: {
    navFeatures:"功能",navWorkflow:"使用方式",navOpenSource:"开源",star:"在 GitHub 点星",eyebrow:"原生 macOS 广播工作台 · 开源",titleA:"让你的播客，",titleB:"真正拥有广播感。",lead:"在一台 Mac 上混合麦克风、BGM、片头音、音效和人声效果。可直接录制为 WAV，或发送到 Zoom、Meet 和 OBS。",viewWorkflow:"了解工作方式",targetLabel:"发布目标",target:"30 天获得 500 颗星",status:"macOS 14+ · MIT LICENSE · 4 LANGUAGES",proof:"告别复杂路由，一张工作台就够。",proofBody:"无需强制使用 BlackHole、复杂 OBS 音频配置或外置声卡。ON AIR Deck 会把麦克风和音源混合为一个 48 kHz 信号。",before:"以前",after:"使用 ON AIR DECK",beforeItems:["虚拟设备连接图","复杂的 OBS 音频设置","额外硬件与线材","全部依赖后期编辑"],afterItems:["选择麦克风","播放音乐和音效","按下 REC 或 LIVE"],workflowEyebrow:"两种模式，同一场演出。",workflowTitle:"录音或直播，表演始终是核心。",workflowBody:"同一份完成混音，可输出为 WAV 或虚拟麦克风。",liveLabel:"LIVE 模式",liveTitle:"直接进入直播应用。",liveBody:"在 Zoom、Google Meet 或 OBS 中选择“ON AIR Deck”作为麦克风，声音与音源会同时送达。",liveSteps:["选择输入麦克风","在目标应用选择 ON AIR Deck","确认人声和 BGM 电平"],recLabel:"REC 模式",recTitle:"按下 REC，就成为节目。",recBody:"以 48 kHz／24-bit 立体声 WAV 捕捉整场演出，之后可在任意 DAW 中编辑。",recSteps:["确认保存位置","按下红色 REC 按钮","停止后在 Finder 打开 WAV"],featuresEyebrow:"为广播式表演而生",featuresTitle:"不只是说话，更是在表演播客。",features:[["01","12 个采样垫","拖入音频、查看波形，并用快捷键一键播放片头音和音效。"],["02","BGM DECK","在一个专注的播放器中管理队列、循环、淡出和自动压低。"],["03","人声效果","SLAP、ECHO、BIG TITLE，让标题口播立即拥有广播质感。"],["04","76 风格压缩器","默认开启且可切换，让人声更稳定、更靠前。"],["05","人声监听","用耳机监听自己与最终混音，确认真正送出的声音。"],["06","安全母线","最终峰值限制器控制麦克风、音乐和音效的总输出。"]],verifiedEyebrow:"真实工程，而非概念图",verifiedTitle:"不仅好看，声音也真正跑通。",stats:[["9","自动化测试"],["48 / 24","kHz / BIT WAV"],["2","APPLE + INTEL"],["4","界面语言"]],verifiedBody:"应用与虚拟音频驱动已在本地完成构建和运行验证。公开版本将在 Developer ID 签名、公证和全新 Mac 验证后发布。",ossEyebrow:"开源 · MIT",ossTitle:"让更多人轻松享受广播制作。",ossBody:"ON AIR Deck 是一个开源项目，目标是消除富表现力音频制作的设置门槛。一颗星，就是帮助更多创作者发现它的最简单方式。",ossPoints:["关注路线图","通过 Issue 提出建议","贡献代码或翻译"],goalSmall:"30 天发布任务",goalTitle:"500",goalUnit:"GITHUB STARS",goalBody:"找到最初的 500 位广播式内容创作者。",faqTitle:"常见问题",faqs:[["只用于录音也可以吗？","可以。REC 模式无需虚拟驱动，即可把麦克风、BGM、采样垫和人声效果录制为 WAV。"],["Zoom 或 Meet 要设置什么？","启动 LIVE 模式，然后在目标应用中选择 ON AIR Deck 作为麦克风。"],["需要外置声卡吗？","不需要。Mac 内置麦克风、USB 麦克风或现有声卡均可选择。"],["有 Windows 版吗？","目前面向 macOS 14 及以上版本，后续计划会在 GitHub 分享。"]],finalEyebrow:"准备开播了吗？",finalTitle:"让下一次录制，成为真正的节目。",finalBody:"在 GitHub 点星并关注发布进展。",footerNote:"为播客、直播与广播爱好者打造。",
  },
  ko: {
    navFeatures:"기능",navWorkflow:"사용 방법",navOpenSource:"오픈 소스",star:"GitHub 스타",eyebrow:"네이티브 macOS 방송 데스크 · 오픈 소스",titleA:"팟캐스트를",titleB:"진짜 라디오 퍼포먼스로.",lead:"한 대의 Mac에서 마이크, BGM, 징글, 효과음, 보이스 FX를 연주하세요. WAV로 녹음하거나 Zoom, Meet, OBS로 완성된 믹스를 보낼 수 있습니다.",viewWorkflow:"작동 방식 보기",targetLabel:"출시 목표",target:"30일 안에 500 STARS",status:"macOS 14+ · MIT LICENSE · 4 LANGUAGES",proof:"복잡한 라우팅 대신, 하나의 방송 데스크.",proofBody:"BlackHole 라우팅, 복잡한 OBS 오디오 설정, 외장 오디오 인터페이스가 필수는 아닙니다. ON AIR Deck이 마이크와 음원을 하나의 48 kHz 믹스로 만듭니다.",before:"이전",after:"ON AIR DECK 사용",beforeItems:["가상 장치 연결도","복잡한 OBS 오디오 설정","추가 장비와 케이블","모든 작업을 후반 편집"],afterItems:["마이크 선택","음악과 패드 재생","REC 또는 LIVE 누르기"],workflowEyebrow:"두 가지 모드, 하나의 퍼포먼스.",workflowTitle:"녹음도 라이브도, 퍼포먼스가 중심입니다.",workflowBody:"같은 완성 믹스를 WAV 또는 가상 마이크로 출력합니다.",liveLabel:"LIVE 모드",liveTitle:"스트리밍 앱으로 바로.",liveBody:"Zoom, Google Meet, OBS에서 마이크로 ON AIR Deck을 선택하면 목소리와 음원이 함께 전달됩니다.",liveSteps:["입력 마이크 선택","대상 앱에서 ON AIR Deck 선택","음성과 BGM 미터 확인"],recLabel:"REC 모드",recTitle:"REC를 누르면 프로그램이 됩니다.",recBody:"48 kHz／24-bit 스테레오 WAV로 퍼포먼스를 녹음하고 원하는 DAW에서 편집하세요.",recSteps:["저장 위치 확인","빨간 REC 버튼 누르기","정지 후 Finder에서 WAV 열기"],featuresEyebrow:"라디오 스타일 퍼포먼스를 위해",featuresTitle:"말하기를 넘어, 팟캐스트를 연주하세요.",features:[["01","12 SAMPLE PADS","오디오를 드롭하고 파형을 확인한 뒤 단축키로 징글과 효과음을 즉시 재생합니다."],["02","BGM DECK","대기열, 반복, 페이드, 더킹을 하나의 집중된 덱에서 제어합니다."],["03","VOICE FX","SLAP, ECHO, BIG TITLE로 타이틀 콜에 즉시 방송 분위기를 더합니다."],["04","76-STYLE COMP","절제된 음성 컴프레서가 말소리를 안정적으로 정리하며 언제든 끌 수 있습니다."],["05","VOICE MONITOR","헤드폰으로 목소리와 최종 믹스를 들어 실제 출력을 확인합니다."],["06","SAFE MASTER","최종 피크 리미터가 마이크, 음악, 효과음의 합산 출력을 안전하게 관리합니다."]],verifiedEyebrow:"컨셉이 아닌 실제 엔지니어링",verifiedTitle:"보기 좋게 설계하고, 소리가 통하도록 만들었습니다.",stats:[["9","자동화 테스트"],["48 / 24","kHz / BIT WAV"],["2","APPLE + INTEL"],["4","UI 언어"]],verifiedBody:"앱과 가상 오디오 드라이버는 로컬에서 빌드 및 동작을 검증했습니다. 공개 바이너리는 Developer ID 서명, 공증, 클린 Mac 검증 후 배포합니다.",ossEyebrow:"오픈 소스 · MIT",ossTitle:"라디오 제작의 즐거움을 더 많은 사람에게.",ossBody:"ON AIR Deck은 표현력 있는 오디오 제작의 설정 장벽을 없애기 위한 오픈 소스 프로젝트입니다. 스타는 더 많은 창작자가 프로젝트를 발견하게 하는 가장 간단한 응원입니다.",ossPoints:["로드맵 팔로우","Issue로 개선 제안","코드와 번역에 기여"],goalSmall:"30일 출시 미션",goalTitle:"500",goalUnit:"GITHUB STARS",goalBody:"복잡한 라우팅 없이 진짜 라디오를 만들 첫 500명을 찾습니다.",faqTitle:"자주 묻는 질문",faqs:[["녹음만 해도 되나요?","네. REC 모드는 가상 드라이버 없이 마이크, BGM, 패드, 보이스 FX를 WAV로 녹음합니다."],["Zoom이나 Meet에서는 무엇을 설정하나요?","LIVE 모드를 시작한 뒤 대상 앱의 마이크로 ON AIR Deck을 선택합니다."],["오디오 인터페이스가 필요한가요?","아니요. 내장 또는 USB 마이크를 사용하거나 기존 인터페이스를 선택할 수 있습니다."],["Windows 버전이 있나요?","현재는 macOS 14 이상을 대상으로 하며 향후 계획은 GitHub에서 공유합니다."]],finalEyebrow:"방송 준비가 됐나요?",finalTitle:"다음 녹음을 진짜 프로그램으로.",finalBody:"GitHub에서 스타하고 출시 소식을 받아보세요.",footerNote:"팟캐스터, 스트리머, 라디오 팬을 위해 만들었습니다.",
  },
} satisfies Record<Language, Record<string, string | string[] | string[][]>>;

function GitHubIcon() {
  return <svg aria-hidden="true" viewBox="0 0 24 24"><path fill="currentColor" d="M12 .7a11.5 11.5 0 0 0-3.64 22.4c.58.1.79-.25.79-.56v-2.24c-3.22.7-3.9-1.36-3.9-1.36-.53-1.34-1.29-1.7-1.29-1.7-1.05-.72.08-.71.08-.71 1.17.08 1.78 1.2 1.78 1.2 1.04 1.78 2.73 1.27 3.4.97.1-.75.4-1.27.74-1.56-2.57-.3-5.27-1.29-5.27-5.69 0-1.26.45-2.28 1.2-3.09-.12-.3-.52-1.47.11-3.05 0 0 .98-.31 3.16 1.18a10.97 10.97 0 0 1 5.75 0c2.19-1.49 3.16-1.18 3.16-1.18.63 1.58.23 2.76.11 3.05.75.81 1.2 1.83 1.2 3.09 0 4.42-2.7 5.39-5.28 5.68.42.36.78 1.06.78 2.14v3.17c0 .31.21.67.8.56A11.5 11.5 0 0 0 12 .7Z"/></svg>;
}

function ArrowIcon() {
  return <svg aria-hidden="true" viewBox="0 0 24 24"><path d="M5 12h13M13 6l6 6-6 6" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/></svg>;
}

export default function Home() {
  const [language, setLanguage] = useState<Language>("ja");
  const t = copy[language];

  return (
    <main>
      <nav className="nav-shell" aria-label="Main navigation">
        <a href="#top" className="brand" aria-label="ON AIR Deck home"><span className="on-air-dot"/>ON AIR DECK<small>STUDIO RECORDING</small></a>
        <div className="nav-links">
          <a href="#features">{t.navFeatures}</a><a href="#workflow">{t.navWorkflow}</a><a href="#open-source">{t.navOpenSource}</a>
        </div>
        <div className="nav-actions">
          <label className="language-select"><span className="sr-only">Language</span><select value={language} onChange={(e)=>setLanguage(e.target.value as Language)} aria-label="Language"><option value="ja">JA</option><option value="en">EN</option><option value="zh">ZH</option><option value="ko">KO</option></select></label>
          <a className="button button-small" href={GITHUB_URL} target="_blank" rel="noreferrer"><GitHubIcon/>{t.star}</a>
        </div>
      </nav>

      <section className="hero" id="top">
        <div className="hero-glow"/>
        <div className="hero-copy">
          <p className="eyebrow"><span/>{t.eyebrow}</p>
          <h1>{t.titleA}<br/><em>{t.titleB}</em></h1>
          <p className="hero-lead">{t.lead}</p>
          <div className="hero-actions">
            <a className="button button-primary" href={GITHUB_URL} target="_blank" rel="noreferrer"><GitHubIcon/>{t.star}<ArrowIcon/></a>
            <a className="text-link" href="#workflow">{t.viewWorkflow}<ArrowIcon/></a>
          </div>
          <div className="launch-goal"><div><span>{t.targetLabel}</span><strong>{t.target}</strong></div><div className="goal-track"><span/></div></div>
          <p className="status-line">{t.status}</p>
        </div>
        <div className="console-wrap" aria-label="ON AIR Deck application screenshot">
          <div className="console-bar"><span/><span/><span/><small>ON AIR DECK · REC SESSION</small><b>● ON AIR</b></div>
          <Image src="/on-air-deck-console.jpg" width={1152} height={768} priority sizes="(max-width: 1050px) 100vw, 58vw" alt="ON AIR Deck showing sample pads, BGM deck, recording controls, voice effects, and audio meters"/>
          <div className="console-badge badge-live"><span/>LIVE MIX</div><div className="console-badge badge-wav">48 kHz · 24-bit WAV</div>
        </div>
      </section>

      <section className="problem section-shell">
        <div className="section-heading"><p className="eyebrow"><span/>ZERO ROUTING HEADACHE</p><h2>{t.proof}</h2><p>{t.proofBody}</p></div>
        <div className="comparison">
          <div className="comparison-card muted"><p>{t.before}</p><ul>{(t.beforeItems as string[]).map((item)=><li key={item}><span>×</span>{item}</li>)}</ul></div>
          <div className="signal-arrow" aria-hidden="true"><i/><ArrowIcon/></div>
          <div className="comparison-card active"><p>{t.after}</p><ul>{(t.afterItems as string[]).map((item,index)=><li key={item}><span>0{index+1}</span>{item}</li>)}</ul></div>
        </div>
      </section>

      <section className="workflow section-shell" id="workflow">
        <div className="section-heading centered"><p className="eyebrow"><span/>{t.workflowEyebrow}</p><h2>{t.workflowTitle}</h2><p>{t.workflowBody}</p></div>
        <div className="mode-grid">
          <article className="mode-card live-card"><div className="mode-top"><span className="mode-icon">↗</span><p>{t.liveLabel}</p><span className="mode-status"><i/>READY</span></div><h3>{t.liveTitle}</h3><p>{t.liveBody}</p><div className="destination-chips"><span>ZOOM</span><span>MEET</span><span>OBS</span></div><ol>{(t.liveSteps as string[]).map((step,index)=><li key={step}><span>{index+1}</span>{step}</li>)}</ol></article>
          <article className="mode-card rec-card"><div className="mode-top"><span className="mode-icon">●</span><p>{t.recLabel}</p><span className="mode-status"><i/>READY</span></div><h3>{t.recTitle}</h3><p>{t.recBody}</p><div className="record-visual"><span className="rec-button">REC</span><div><i/><i/><i/><i/><i/><i/><i/><i/><i/><i/><i/></div><b>00:42:18</b></div><ol>{(t.recSteps as string[]).map((step,index)=><li key={step}><span>{index+1}</span>{step}</li>)}</ol></article>
        </div>
      </section>

      <section className="features section-shell" id="features">
        <div className="section-heading"><p className="eyebrow"><span/>{t.featuresEyebrow}</p><h2>{t.featuresTitle}</h2></div>
        <div className="feature-grid">{(t.features as string[][]).map(([num,title,body])=><article className="feature-card" key={num}><div className="feature-no">{num}</div><div className={`feature-graphic graphic-${num}`} aria-hidden="true">{num==="01"?<><i/><i/><i/><i/><i/><i/><i/><i/><i/><i/><i/><i/></>:num==="02"?<><span/><span/><span/><span/><span/><span/><span/><span/><span/></>:num==="03"?<><b>SLAP</b><b>ECHO</b><b>BIG TITLE</b></>:num==="04"?<><span className="knob"/><i/></>:num==="05"?<><span className="headphone">◖◗</span><i/><i/><i/></>:<><span className="meter"><i/></span><b>−1.0 dB</b></>}</div><h3>{title}</h3><p>{body}</p></article>)}</div>
      </section>

      <section className="verified" aria-label="Validation status"><div className="section-shell verified-inner"><div className="section-heading"><p className="eyebrow"><span/>{t.verifiedEyebrow}</p><h2>{t.verifiedTitle}</h2><p>{t.verifiedBody}</p></div><div className="stats-grid">{(t.stats as string[][]).map(([value,label])=><div key={label}><strong>{value}</strong><span>{label}</span></div>)}</div></div></section>

      <section className="oss section-shell" id="open-source">
        <div className="oss-copy"><p className="eyebrow"><span/>{t.ossEyebrow}</p><h2>{t.ossTitle}</h2><p>{t.ossBody}</p><ul>{(t.ossPoints as string[]).map((point)=><li key={point}><span>↗</span>{point}</li>)}</ul><a className="button button-primary" href={GITHUB_URL} target="_blank" rel="noreferrer"><GitHubIcon/>{t.star}<ArrowIcon/></a></div>
        <div className="goal-panel"><span className="goal-small">{t.goalSmall}</span><strong>{t.goalTitle}</strong><b>{t.goalUnit}</b><div className="goal-scale"><span>0</span><i><em/></i><span>500</span></div><p>{t.goalBody}</p><div className="orbit orbit-one"/><div className="orbit orbit-two"/></div>
      </section>

      <section className="faq section-shell"><div className="section-heading"><p className="eyebrow"><span/>FAQ</p><h2>{t.faqTitle}</h2></div><div className="faq-list">{(t.faqs as string[][]).map(([q,a],index)=><details key={q} open={index===0}><summary><span>0{index+1}</span>{q}<b>+</b></summary><p>{a}</p></details>)}</div></section>

      <section className="final-cta"><div className="final-grid"/><p className="eyebrow"><span/>{t.finalEyebrow}</p><h2>{t.finalTitle}</h2><p>{t.finalBody}</p><a className="button button-primary" href={GITHUB_URL} target="_blank" rel="noreferrer"><GitHubIcon/>{t.star}<ArrowIcon/></a></section>

      <footer><a href="#top" className="brand"><span className="on-air-dot"/>ON AIR DECK<small>STUDIO RECORDING</small></a><p>{t.footerNote}</p><div><a href={GITHUB_URL} target="_blank" rel="noreferrer">GitHub</a><a href={`${GITHUB_URL}/blob/main/LICENSE`} target="_blank" rel="noreferrer">MIT License</a><span>© 2026 ON AIR Deck</span></div></footer>
    </main>
  );
}
