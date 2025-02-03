#!/bin/bash

# 定义颜色
re="\033[0m"
red="\033[1;91m"
green="\e[1;32m"
yellow="\e[1;33m"
purple="\e[1;35m"
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }

# 定义路径
USERNAME=$(whoami)
HOSTNAME=$(hostname)
WORKDIR="/home/${USERNAME}/logs"

# 定义文件下载地址
REBOOT_URL="https://raw.githubusercontent.com/darrelltc/ctien/master/files/reboot.sh"
CORN_URL="https://raw.githubusercontent.com/darrelltc/ctien/master/files/check_cron.sh"

[ -d "${WORKDIR}" ] || (mkdir -p "${WORKDIR}" && chmod -R 755 "${WORKDIR}")

# 重启所有进程
echo "执行：重启所有进程"
bash <(curl -s ${REBOOT_URL})

# 写入面板 CORN 任务
echo "执行：写入面板 CORN 任务"
bash <(curl -s ${CORN_URL})

# 结束脚本
echo "所有任务完成，脚本结束。"
