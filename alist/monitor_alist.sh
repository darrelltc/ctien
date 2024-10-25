#!/bin/bash

# 检查 alist 是否在运行
if ! pgrep -f "alist" > /dev/null; then
    echo "alist is not running. Starting it..."
    # 启动 alist 的命令
    /domains/alist &
else
    echo "alist is running."
fi
