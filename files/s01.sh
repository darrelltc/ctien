#!/bin/bash

# 定义颜色
RE="\033[0m"
RED="\033[1;91m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
PURPLE="\e[1;35m"
RED() { echo -e "\e[1;91m$1\033[0m"; }
GREEN() { echo -e "\e[1;32m$1\033[0m"; }
YELLOW() { echo -e "\e[1;33m$1\033[0m"; }
PURPLE() { echo -e "\e[1;35m$1\033[0m"; }
READING() { read -p "$(RED "$1")" "$2"; }

# 定义路径和变量
WORKDIR="/home/$(whoami)/logs"
UUID=${UUID:-'5195c04a-552f-4f9e-8bf9-216d257c0839'}
ARGO_DOMAIN=${ARGO_DOMAIN:-'example.com'}   # 修改为实际域名
ARGO_AUTH=${ARGO_AUTH:-'your-argo-auth-token'}  # 修改为实际 token
VLESS_PORT=${VLESS_PORT:-'40000'}
HY2_PORT=${HY2_PORT:-'41000'}
SOCKS_PORT=${SOCKS_PORT:-'42000'}
SOCKS_USER=${SOCKS_USER:-'abc123'}
SOCKS_PASS=${SOCKS_PASS:-'abc456'}
CFIP=${CFIP:-'fan.yutian.us.kg'} 
CFPORT=${CFPORT:-'443'} 

[ -d "${WORKDIR}" ] || (mkdir -p "${WORKDIR}" && chmod -R 755 "${WORKDIR}")

# 安装singbox
INSTALL_SINGBOX() {
  echo -e "${YELLOW}本脚本支持四协议共存：${PURPLE}(vless, Vless-ws-tls(argo), hysteria2, socks5)${RE}"
  GREEN "安装完成后，脚本将在用户根目录执行"
  # 这里可以省略交互过程，直接继续执行
  cd "${WORKDIR}"
  READ_VLESS_PORT
  READ_HY2_PORT
  READ_SOCKS_VARIABLES
  ARGO_CONFIGURE
  GENERATE_CONFIG
  DOWNLOAD_SINGBOX
  RUN_SB
  RUN_ARGO
  GET_LINKS
  CREAT_CORN
}

# 设置vless端口
READ_VLESS_PORT() {
    echo "vless端口设置为: $VLESS_PORT"
}

# 设置hy2端口
READ_HY2_PORT() {
    echo "hysteria2端口设置为: $HY2_PORT"
}

# 设置socks5端口、用户名、密码
READ_SOCKS_VARIABLES() {
    echo "socks端口设置为: $SOCKS_PORT"
    echo "socks用户名为: $SOCKS_USER"
    echo "socks密码为: $SOCKS_PASS"
}

# 设置 argo 隧道域名、json 或 token
ARGO_CONFIGURE() {
  if [[ -z "${ARGO_AUTH}" || -z "${ARGO_DOMAIN}" ]]; then
    RED "Argo 隧道未配置完整，请检查 ARGO_AUTH 和 ARGO_DOMAIN。"
    exit 1
  fi

  # 生成 Argo 配置
  cat > tunnel.yml << EOF
tunnel: $(cut -d\" -f12 <<< "$ARGO_AUTH")
credentials-file: ${WORKDIR}/tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:$VLESS_PORT
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
  # 使用 json 时 Argo 隧道的启动参数
  ARGS="tunnel --edge-ip-version auto --config tunnel.yml run"
  GREEN "ARGO_AUTH 是 Json 格式，将使用 Json 连接 ARGO；tunnel.yml 配置文件已生成"
}

# 下载singbox文件
DOWNLOAD_SINGBOX() {
  # 下载singbox文件并处理
  GREEN "下载singbox文件"
}

# 生成节点配置文件
GENERATE_CONFIG() {
  # 生成证书和配置文件
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
      "listen_port": $VLESS_PORT,
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
      "listen_port": $HY2_PORT,
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
      "listen_port": $SOCKS_PORT,
      "users": [
        {
          "username": "$SOCKS_USER",
          "password": "$SOCKS_PASS"
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
GET_LINKS() {
  ARGO_DOMAIN=$(GET_ARGODOMAIN)
  echo "ArgoDomain: $ARGO_DOMAIN"
  IP=$(GET_IP)
  echo "服务器IP: $IP"
  ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')

  cat > list.txt <<EOF
vless://$UUID@$IP:$VLESS_PORT?encryption=none&security=tls&sni=$ARGO_DOMAIN&path=/vless&alpn=h2#VlessNode
vless://$UUID@$CFIP:$CFPORT?encryption=none&security=tls&sni=$ARGO_DOMAIN&path=/vless&alpn=h2#Vless-Argo
hysteria2://$UUID@$IP:$HY2_PORT/?sni=www.bing.com&alpn=h3&insecure=1#$ISP
socks5://$SOCKS_USER:$SOCKS_PASS@$IP:$SOCKS_PORT
EOF
  cat list.txt
}

# 获取IP
GET_IP() {
  ip=$(curl -s --max-time 2 ipv4.ip.sb)
  echo "$ip"
}

# 主菜单
MENU() {
   INSTALL_SINGBOX
}

MENU
