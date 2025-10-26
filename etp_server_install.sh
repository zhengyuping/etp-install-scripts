#!/bin/bash
# ETP Server Auto Install Script
# Usage: curl -fsSL https://raw.githubusercontent.com/zhengyuping/etp-install-scripts/main/etp_server_install.sh | bash

set -e

# 配置参数
BIND_PORT="9527"
SECRET_KEY="okx-market-sentry-2025-secret"
INSTALL_DIR="/opt/etp"
SERVICE_NAME="etp-server"
LOG_FILE="/tmp/etp-server.log"

echo "🚀 开始安装 ETP 服务端..."

# 检测架构
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    DOWNLOAD_URL="https://github.com/xiaoniucode/etp/releases/download/v1.0.5/etp_v1.0.5_linux_amd64.tar.gz"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    DOWNLOAD_URL="https://github.com/xiaoniucode/etp/releases/download/v1.0.5/etp_v1.0.5_linux_arm64.tar.gz"
else
    echo "❌ 不支持的架构: $ARCH"
    exit 1
fi

echo "📦 检测到架构: $ARCH"

# 创建安装目录
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# 下载并解压
echo "⬇️  下载 ETP 服务端..."
wget -q --show-progress $DOWNLOAD_URL -O etp.tar.gz
tar -xzf etp.tar.gz --strip-components=1
rm -f etp.tar.gz

# 创建配置文件
echo "⚙️  生成配置文件..."
cat > etps.toml <<EOF
bindPort=$BIND_PORT

[[clients]]
name = "Ubuntu-Client"
secretKey = "$SECRET_KEY"

[[clients.proxies]]
name = "ssh"
type = "tcp"
localPort = 22
remotePort = 2222

[[clients.proxies]]
name = "redis"
type = "tcp"
localPort = 6379
remotePort = 6380

[[clients.proxies]]
name = "http"
type = "tcp"
localPort = 80
remotePort = 8080
EOF

# 设置权限
chmod +x etps

# 检测是否有systemd
if command -v systemctl >/dev/null 2>&1; then
    echo "🔧 创建系统服务..."
    cat > /etc/systemd/system/${SERVICE_NAME}.service <<EOF
[Unit]
Description=ETP Server Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/etps
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ${SERVICE_NAME}
    systemctl start ${SERVICE_NAME}

    echo ""
    echo "✅ ETP 服务端安装完成！"
    echo ""
    echo "📍 安装目录: $INSTALL_DIR"
    echo "🔗 监听端口: $BIND_PORT"
    echo "🔑 密钥: $SECRET_KEY"
    echo ""
    echo "映射端口:"
    echo "  SSH:   22 → 2222"
    echo "  Redis: 6379 → 6380"
    echo "  HTTP:  80 → 8080"
    echo ""
    echo "常用命令:"
    echo "  查看状态: systemctl status ${SERVICE_NAME}"
    echo "  查看日志: journalctl -u ${SERVICE_NAME} -f"
    echo "  重启服务: systemctl restart ${SERVICE_NAME}"
    echo "  停止服务: systemctl stop ${SERVICE_NAME}"
else
    echo "🐳 检测到容器环境，使用后台运行模式..."
    
    # 停止旧进程
    pkill -f "$INSTALL_DIR/etps" 2>/dev/null || true
    
    # 后台启动
    nohup $INSTALL_DIR/etps > $LOG_FILE 2>&1 &
    PID=$!
    
    echo ""
    echo "✅ ETP 服务端安装完成！"
    echo ""
    echo "📍 安装目录: $INSTALL_DIR"
    echo "🔗 监听端口: $BIND_PORT"
    echo "🔑 密钥: $SECRET_KEY"
    echo "🆔 进程ID: $PID"
    echo "📄 日志文件: $LOG_FILE"
    echo ""
    echo "映射端口:"
    echo "  SSH:   22 → 2222"
    echo "  Redis: 6379 → 6380"
    echo "  HTTP:  80 → 8080"
    echo ""
    echo "常用命令:"
    echo "  查看日志: tail -f $LOG_FILE"
    echo "  查看进程: ps aux | grep etps"
    echo "  停止服务: pkill -f etps"
    echo "  重启服务: pkill -f etps && cd $INSTALL_DIR && nohup ./etps > $LOG_FILE 2>&1 &"
fi

echo ""
