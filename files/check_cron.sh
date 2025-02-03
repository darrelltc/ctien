#!/bin/bash

red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
USERNAME=$(whoami)
WORKDIR="/home/${USERNAME}/logs"
CRON_NEZHA="nohup ./nezha.sh >/dev/null 2>&1 &"
CRON_SB="nohup ./web run -c config.json >/dev/null 2>&1 &"
CRON_ARGO="nohup ./argo.sh >/dev/null 2>&1 &"
chmod -R 755 "${WORKDIR}"

# 检查是否存在指定的 crontab 任务
check_crontab() {
  crontab -l 2>/dev/null | grep -q "$1"
  return $?
}

# 添加新的 crontab 任务
add_crontab() {
  (crontab -l 2>/dev/null; echo "$1") | crontab -
}

# 检查 nezha.sh, web, argo.sh 文件是否都存在
if [ -e "${WORKDIR}/nezha.sh" ] && [ -e "${WORKDIR}/web" ] && [ -e "${WORKDIR}/argo.sh" ]; then
  green "相关文件都已存在，正在检查并添加 corntab 任务"

  # 检查重启和定时任务是否存在
  if check_crontab "@reboot pkill -kill -u $(whoami)" && check_crontab "pgrep -x \"npm\"" && check_crontab "pgrep -x \"web\"" && check_crontab "pgrep -x \"bot\""; then
    green "全部重启和定时任务均已存在"
  else
    if ! check_crontab "@reboot pkill -kill -u $(whoami)"; then
      add_crontab "@reboot pkill -kill -u $(whoami) && cd ${WORKDIR} && ${CRON_NEZHA} ${CRON_SB} ${CRON_ARGO}" && \
      green "全部重启任务添加完成"
    fi
    if ! check_crontab "pgrep -x \"npm\""; then
      add_crontab "*/10 * * * * pgrep -x \"npm\" > /dev/null || cd ${WORKDIR} && ${CRON_NEZHA}" && \
      green "nezha 定时任务添加完成"
    fi
    if ! check_crontab "pgrep -x \"web\""; then
      add_crontab "*/10 * * * * pgrep -x \"web\" > /dev/null || cd ${WORKDIR} && ${CRON_SB}" && \
      green "singbox 定时任务添加完成"
    fi
    if ! check_crontab "pgrep -x \"bot\""; then
      add_crontab "*/10 * * * * pgrep -x \"bot\" > /dev/null || cd ${WORKDIR} && ${CRON_ARGO}" && \
      green "argo 定时任务添加完成"
    fi
  fi

else
  red "仅存在部分启动文件"

  # 检查 nezha.sh 文件是否存在
  if [ -e "${WORKDIR}/nezha.sh" ]; then
    green "哪吒已安装"
    if check_crontab "@reboot pkill -kill -u $(whoami)" && check_crontab "pgrep -x \"npm\""; then
      green "nezha 任务已存在"
    else
      add_crontab "@reboot pkill -kill -u $(whoami) && cd ${WORKDIR} && ${CRON_NEZHA}" && \
      add_crontab "*/10 * * * * pgrep -x \"npm\" > /dev/null || cd ${WORKDIR} && ${CRON_NEZHA}" && \
      green "nezha 重启和定时任务添加完成"
    fi
  else
    red "nezha 未安装，启动文件不存在"
  fi

  # 检查 web 文件是否存在
  if [ -e "${WORKDIR}/web" ]; then
    green "singbox 已安装"
    if check_crontab "@reboot pkill -kill -u $(whoami)" && check_crontab "pgrep -x \"web\""; then
      green "singbox 任务已存在"
    else
      add_crontab "@reboot pkill -kill -u $(whoami) && cd ${WORKDIR} && ${CRON_SB}" && \
      add_crontab "*/10 * * * * pgrep -x \"web\" > /dev/null || cd ${WORKDIR} && ${CRON_SB}" && \
      green "singbox 重启和定时任务添加完成"
    fi
  else
    red "singbox 未安装，启动文件不存在"
  fi

  # 检查 argo.sh 文件是否存在
  if [ -e "${WORKDIR}/argo.sh" ]; then
    green "argo 已安装"
    if check_crontab "@reboot pkill -kill -u $(whoami)" && check_crontab "pgrep -x \"bot\""; then
      green "argo 任务已存在"
    else
      add_crontab "@reboot pkill -kill -u $(whoami) && cd ${WORKDIR} && ${CRON_ARGO}" && \
      add_crontab "*/10 * * * * pgrep -x \"bot\" > /dev/null || cd ${WORKDIR} && ${CRON_ARGO}" && \
      green "argo 重启和定时任务添加完成"
    fi
  else
    red "argo 未安装，启动文件不存在"
  fi
fi
