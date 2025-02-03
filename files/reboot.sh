#!/bin/bash

red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
USERNAME=$(whoami)
HOSTNAME=$(hostname)
WORKDIR="/home/${USERNAME}/logs"
chmod -R 755 "${WORKDIR}"
cd ${WORKDIR} || { red "无法切换到工作目录 ${WORKDIR}"; exit 1; }
export TMPDIR=$(pwd)

ps aux | grep $(whoami) | grep -v "sshd\|bash\|grep" | awk '{print $2}' | xargs -r kill -9 > /dev/null 2>&1
red "已清理所有进程"

# 重启哪吒探针
if pgrep -x 'npm' > /dev/null; then
   green "NEZHA 正在运行"
else
   red "NEZHA 已停止，尝试重启……"
   nohup ./nezha.sh >/dev/null 2>&1 &
   sleep 2
   if pgrep -x 'npm' > /dev/null; then
      green "NEZHA 重启成功"
   else
      red "NEZHA 重启失败！"
   fi
fi

# 重启singbox
if pgrep -x 'web' > /dev/null; then
   green "singbox 正在运行"
else
   red "singbox 已停止，尝试重启……"
   nohup ./web run -c config.json >/dev/null 2>&1 &
   sleep 2
   if pgrep -x 'web' > /dev/null; then
      green "singbox 重启成功"
   else
      red "singbox 重启失败！"
   fi
fi

# 重启argo
if pgrep -x 'bot' > /dev/null; then
   green "ARGO 正在运行"
else
   red "ARGO 已停止，尝试重启……"
   nohup ./argo.sh >/dev/null 2>&1 &
   sleep 2
   if pgrep -x 'bot' > /dev/null; then
      green "ARGO 重启成功"
   else
      red "ARGO 重启失败！"
   fi
fi
