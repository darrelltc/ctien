#!/bin/bash

# Argo 域名
ARGO_DOMAIN="修改为你的二狗域名"

# 失败计数
ARGO_FAILURE_COUNT=0
MAX_FAILURES=3

# 本地端口号连接两个一样的端口
PORT=5252
ARGO_PORT=5252

# Argo 配置信息
ARGO_AUTH='二狗的秘锁'
CFPORT=8443
CFIP='www.xxxxxxxx.nyc.mn'

# 最大重试次数
MAX_RETRIES=3
RETRY_INTERVAL=10

# 检查脚本是否已经在运行，防止重复执行
if pgrep -f "$(basename "$0")" | grep -v $$ > /dev/null; then
   echo "Script is already running. Exiting."
   exit 1
fi

# 检查 Argo 的 HTTP 状态
check_argo_status() {
    http_code=$(curl -o /dev/null -s -w "%{http_code}\n" "https://$ARGO_DOMAIN")
    if [ "$http_code" == "530" ]; then
        ((ARGO_FAILURE_COUNT++))
        echo "Argo 服务不可用！失败次数：$ARGO_FAILURE_COUNT"
        return 1
    else
        ARGO_FAILURE_COUNT=0
        echo "Argo 服务正常。"
        return 0
    fi
}

# 检查端口状态
check_port() {
    if sockstat -l | grep -q ":$PORT"; then
        echo "Port $PORT is already in use."
        return 0
    else
        echo "Port $PORT is not in use."
        return 1
    fi
}

# 执行远程安装操作
install_argo() {
    echo "开始执行远程安装脚本..."
    bash -c "ARGO_AUTH='$ARGO_AUTH' ARGO_DOMAIN='$ARGO_DOMAIN' CFPORT='$CFPORT' CFIP='$CFIP' ARGO_PORT='$PORT' bash <(curl -Ls https://github.love999.us.kg/onlyno999/xxxxxxxxxx/main/vless/00_vless.sh)"
    
    if [ $? -eq 0 ]; then
        echo "远程安装成功完成。"
    else
        echo "远程安装失败。"
    fi
}

# 重试逻辑函数
retry_check() {
    local retries=0
    local max_retries=$1      # 最大重试次数
    local retry_interval=$2   # 每次重试的间隔时间（秒）

    shift 2                   # 移动参数位置，之后的参数用于具体的检查逻辑函数

    while [ $retries -lt $max_retries ]; do
        echo "重试检查第 $((retries+1)) 次..."

        # 执行传递进来的检查函数
        "$@"
        local status=$?

        # 如果检查通过，则退出重试
        if [ $status -eq 0 ]; then
            echo "重试后状态正常。"
            return 0
        fi

        # 增加重试次数并等待
        ((retries++))
        sleep $retry_interval
    done

    echo "重试 $max_retries 次后仍然不正常。"
    return 1
}

# 主循环
while true; do
    echo "检查时间: $(date +"%Y-%m-%d %H:%M")"

    # 检查 Argo HTTP 状态
    retry_check $MAX_RETRIES $RETRY_INTERVAL check_argo_status
    argo_status=$?

    # 检查端口状态
    retry_check $MAX_RETRIES $RETRY_INTERVAL check_port
    port_status=$?

    # 如果 Argo 服务不正常或端口未被占用，则执行远程安装操作
    if [ $argo_status -ne 0 ] || [ $port_status -ne 0 ]; then
        echo "检测到异常，开始执行远程安装操作..."
        install_argo

        # 如果 Argo 的失败次数超过最大值，进行重置
        if [ $ARGO_FAILURE_COUNT -ge $MAX_FAILURES ]; then
            echo "Argo 服务连续失败次数达到最大值，进行重置..."
            ARGO_FAILURE_COUNT=0
        fi
    else
        echo "Argo 服务和端口状态都正常，无需重新安装。"
    fi

    # 随机等待 1 到 60 秒之间
    sleep $((1 + RANDOM % 60))
done
