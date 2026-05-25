#!/bin/zsh
/usr/bin/osascript <<'APPLESCRIPT'
display notification "该做谁在花钱日报了" with title "谁在花钱" subtitle "工作日 11:00 提醒"
APPLESCRIPT
