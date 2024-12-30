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
reading() { read -p "$(red "$1")" "$2"; }

# 定义路径
USERNAME=$(whoami)
HOSTNAME=$(hostname)
WORKDIR="/home/${USERNAME}/logs"

# 定义变量
export LC_ALL=C
export UUID=${UUID:-'506e4fb1-80de-4ed4-8773-5e41966d55a8'}
# export NEZHA_SERVER=${NEZHA_SERVER:-'nezha.yutian81.top'} 
# export NEZHA_PORT=${NEZHA_PORT:-'5555'}     
# export NEZHA_KEY=${NEZHA_KEY:-''} 
export ARGO_DOMAIN=${ARGO_DOMAIN:-''}   
export ARGO_AUTH=${ARGO_AUTH:-''} 
export vless_port=${vless_port:-'40000'}
export hy2_port=${hy2_port:-'41000'}
export socks_port=${socks_port:-'42000'}
export socks_user=${socks_user:-'abc123'}
export socks_pass=${socks_pass:-'abc456'}
export CFIP=${CFIP:-'fan.yutian.us.kg'} 
export CFPORT=${CFPORT:-'443'} 

# 定义文件下载地址
SB_WEB_ARMURL="https://github.com/eooce/test/releases/download/arm64/sb"
# AG_BOT_ARMURL="https://github.com/eooce/test/releases/download/arm64/bot13"
AG_BOT_ARMURL="https://github.com/yutian81/serv00-ct8-ssh/releases/download/arm64/cloudflared_arm64"
# NZ_NPM_ARMURL="https://github.com/eooce/test/releases/download/ARM/swith"
NZ_NPM_ARMURL="https://github.com/yutian81/serv00-ct8-ssh/releases/download/arm64/nezha_agent_arm64"
SB_WEB_X86URL="https://00.2go.us.kg/web"
AG_BOT_X86URL="https://00.2go.us.kg/bot"
NZ_NPM_X86URL="https://00.2go.us.kg/npm"
CORN_URL="https://raw.githubusercontent.com/yutian81/serv00-ct8-ssh/main/check_sb_cron.sh"
UPDATA_URL="https://raw.githubusercontent.com/darrelltc/ctien/master/files/serv004in1.sh"
REBOOT_URL="https://raw.githubusercontent.com/yutian81/serv00-ct8-ssh/main/reboot.sh"

[ -d "${WORKDIR}" ] || (mkdir -p "${WORKDIR}" && chmod -R 755 "${WORKDIR}")

# 安装singbox
install_singbox() {
echo -e "${yellow}本脚本同时支持四协议共存${purple}(vless, Vless-ws-tls(argo), hysteria2, socks5)${re}"
echo -e "${yellow}开始运行前，请确保在面板${purple}已开放3个端口，两个tcp端口和一个udp端口${re}"
echo -e "${yellow}面板${purple}Additional services中的Run your own applications${yellow}已开启为${purple}Enabled${yellow}状态${re}"
green "安装完成后，可在用户根目录输入 \`bash sb00.sh\` 再次进入主菜单"
reading "\n确定继续安装吗？【y/n】: " choice
  case "$choice" in
    [Yy])
        cd "${WORKDIR}"
        read_vless_port
        read_hy2_port
        read_socks_variables
        argo_configure
        read_nz_variables
        generate_config
        download_singbox
#        run_nezha
        run_sb
        run_argo
        get_links
        creat_corn ;;
    [Nn]) menu ;;
    *) red "无效的选择，请输入 y 或 n" && install_singbox ;;
  esac
}

# 设置vless端口
read_vless_port() {
    while true; do
        reading "请输入vless端口 (面板开放的TCP端口): " vless_port
        if [[ "$vless_port" =~ ^[0-9]+$ ]] && [ "$vless_port" -ge 1 ] && [ "$vless_port" -le 65535 ]; then
            green "你的vless端口为: $vless_port"
            break
        else
            yellow "输入错误，请重新输入面板开放的TCP端口"
        fi
    done
}

# 设置hy2端口
read_hy2_port() {
    while true; do
        reading "请输入hysteria2端口 (面板开放的UDP端口): " hy2_port
        if [[ "$hy2_port" =~ ^[0-9]+$ ]] && [ "$hy2_port" -ge 1 ] && [ "$hy2_port" -le 65535 ]; then
            green "你的hysteria2端口为: $hy2_port"
            break
        else
            yellow "输入错误，请重新输入面板开放的UDP端口"
        fi
    done
}

# 设置socks5端口、用户名、密码
read_socks_variables() {
    while true; do
        reading "请输入socks端口 (面板开放的TCP端口): " socks_port
        if [[ "$socks_port" =~ ^[0-9]+$ ]] && [ "$socks_port" -ge 1 ] && [ "$socks_port" -le 65535 ]; then
            green "你的socks端口为: $socks_port"
            break
        else
            yellow "输入错误，请重新输入面板开放的TCP端口"
        fi
    done

    while true; do
        reading "请输入socks用户名: " socks_user
        if [[ ! -z "$socks_user" ]]; then
            green "你的socks用户名为: $socks_user"
            break
        else
            yellow "用户名不能为空，请重新输入"
        fi
    done

    while true; do
        reading "请输入socks密码，不能包含:和@符号: " socks_pass
        if [[ ! -z "$socks_pass" && ! "$socks_pass" =~ [:@] ]]; then
            green "你的socks密码为: $socks_pass"
            break
        else
            yellow "密码不能为空或包含非法字符(:和@)，请重新输入"
        fi
    done
}

# 设置 argo 隧道域名、json 或 token
argo_configure() {
  if [[ -z "${ARGO_AUTH}" || -z "${ARGO_DOMAIN}" ]]; then
    reading "是否需要使用固定 argo 隧道？【y/n】: " argo_choice
    [[ -z $argo_choice ]] && return
    [[ "$argo_choice" != "y" && "$argo_choice" != "Y" && "$argo_choice" != "n" && "$argo_choice" != "N" ]] && { red "无效的选择，请输入y或n"; return; }
    if [[ "$argo_choice" == "y" || "$argo_choice" == "Y" ]]; then
        reading "请输入 argo 固定隧道域名: " ARGO_DOMAIN
        green "你的 argo 固定隧道域名为: $ARGO_DOMAIN"
        reading "请输入 argo 固定隧道密钥（Json 或 Token）: " ARGO_AUTH
        green "你的 argo 固定隧道密钥为: $ARGO_AUTH"
        echo -e "${red}注意：${purple}使用 token，需要在 cloudflare 后台设置隧道端口和面板开放的 tcp 端口一致${re}"
    else
        green "ARGO 变量未设置，将使用临时隧道"
        return
    fi
  fi
  if [[ "${ARGO_AUTH}" =~ TunnelSecret ]]; then
    echo "${ARGO_AUTH}" > tunnel.json
    cat > tunnel.yml << EOF
tunnel: $(cut -d\" -f12 <<< "$ARGO_AUTH")
credentials-file: ${WORKDIR}/tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:$vless_port
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
    # 定义使用 json 时 argo 隧道的启动参数变量
    declare -g args="tunnel --edge-ip-version auto --config tunnel.yml run"
    green "ARGO_AUTH 是 Json 格式，将使用 Json 连接 ARGO；tunnel.yml 配置文件已生成"
  elif [[ "${ARGO_AUTH}" =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
    declare -g args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token \"${ARGO_AUTH}\""
    green "ARGO_AUTH 是 Token 格式，将使用 Token 连接 ARGO"
  else
    declare -g args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile boot.log --loglevel info --url http://localhost:$vless_port"
    green "ARGO_AUTH 未定义，将使用 ARGO 临时隧道"
  fi
  # 生成 argo.sh 脚本
  cat > "${WORKDIR}/argo.sh" << EOF
#!/bin/bash

cd ${WORKDIR} || exit
export TMPDIR=$(pwd)
chmod +x ./bot
./bot ${args} >/dev/null 2>&1 &
EOF
  chmod +x "${WORKDIR}/argo.sh"
}

# 生成节点配置文件
generate_config() {
  openssl ecparam -genkey -name prime256v1 -out "private.key"
  openssl req -new -x509 -days 3650 -key "private.key" -out "cert.pem" -subj "/CN=${USERNAME}.serv00.net"
  cat > config.json << EOF
{
  "log": {
    "disabled": true,
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "google",
        "address": "tls://8.8.8.8",
        "strategy": "ipv4_only",
        "detour": "direct"
      }
    ]
  },
  "inbounds": [
    {
      "tag": "vless-in",
      "type": "vless",
      "listen": "::",
      "listen_port": $vless_port,
      "users": [
        {
          "uuid": "$UUID",
          "encryption": "none"
        }
      ],
      "transport": {
        "type": "ws",
        "path": "/vless",
        "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    },
    {
      "tag": "hysteria-in",
      "type": "hysteria2",
      "listen": "::",
      "listen_port": $hy2_port,
      "users": [
        {
          "password": "$UUID"
        }
      ],
      "masquerade": "https://bing.com",
      "tls": {
        "enabled": true,
        "alpn": ["h3"],
        "certificate_path": "cert.pem",
        "key_path": "private.key"
      }
    },
    {
      "tag": "socks-in",
      "type": "socks",
      "listen": "::",
      "listen_port": $socks_port,
      "users": [
        {
          "username": "$socks_user",
          "password": "$socks_pass"
        }
      ]
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ]
}
EOF
}

# 获取节点链接
get_links() {
argodomain=$(get_argodomain)
echo -e "\e[1;32mArgoDomain:\e[1;35m${argodomain}\e[0m\n"
IP=$(get_ip)
ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')
yellow "注意：使用vless需配置TLS或其他安全加密方式\n"
cat > list.txt <<EOF
vless://$UUID@$IP:$vless_port?encryption=none&security=tls&sni=$argodomain&path=/vless&alpn=h2#VlessNode
vless://$UUID@$CFIP:$CFPORT?encryption=none&security=tls&sni=$argodomain&path=/vless&alpn=h2#Vless-Argo
hysteria2://$UUID@$IP:$hy2_port/?sni=www.bing.com&alpn=h3&insecure=1#$ISP
socks5://$socks_user:$socks_pass@$IP:$socks_port
EOF
cat list.txt
purple "\n$WORKDIR/list.txt 节点文件已保存"
green "安装完成"
}

# 主菜单
menu() {
   clear
   echo ""
   purple "--- Serv00 VLESS 一键脚本 ---\n"
   echo -e "${green}支持 VLESS, Vless-ws-tls(argo), Hysteria2 和 Socks5${re}\n"
   red "1. 安装sing-box"
   echo  "----------------"
   red "2. 卸载或清理服务器"
   echo  "----------------"
   green "3. 查看节点信息"
   echo  "----------------"
   green "4. 重启所有进程"
   echo  "----------------"
   yellow "5. 写入面板CORN任务"
   echo  "----------------"
   yellow "6. 更新最新脚本"
   echo  "----------------"
   red "0. 退出脚本"
   echo "----------------"
   reading "请输入选择(0-6): " choice
   echo ""
    case "${choice}" in
        1) install_singbox ;;
        2) clean_all ;; 
        3) cat ${WORKDIR}/list.txt ;; 
        4) bash <(curl -s ${REBOOT_URL}) ;;
        5) creat_corn ;;
        6) curl -s ${UPDATA_URL} -o sb00.sh && chmod +x sb00.sh && ./sb00.sh ;;
        0) exit 0 ;;
        *) red "无效的选项，请输入 0 到 6" && menu ;;
    esac
}
menu
