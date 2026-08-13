#!/bin/sh

set -e
echo "ON AIR Deck Audio Driver をアンインストールします。"
sudo /bin/rm -rf "/Library/Audio/Plug-Ins/HAL/OnAirDeckAudio.driver"
sudo /usr/bin/killall coreaudiod >/dev/null 2>&1 || true
echo "完了しました。このウインドウは閉じて構いません。"
read -r _
