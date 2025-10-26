#!/bin/bash
# ETP Client Auto Install Script
# Usage: curl -fsSL https://raw.githubusercontent.com/zhengyuping/etp-install-scripts/main/etp_client_install.sh | bash

set -e

# 配置参数
SERVER_ADDR="47.117.108.81"
SERVER_PORT="9527"
SECRET_KEY="okx-market-sentry-2025-secret"
INSTALL_DIR="/opt/etp"
SERVICE_NAME="etp-client"

echo "🚀 开始安装 ETP 客户端..."

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
echo "⬇️  下载 ETP 客户端..."
wget -q --show-progress $DOWNLOAD_URL -O etp.tar.gz
tar -xzf etp.tar.gz --strip-components=1
rm -f etp.tar.gz

# 创建配置文件
echo "⚙️  生成配置文件..."
cat > etpc.toml <<EOF
serverAddr = "$SERVER_ADDR"
serverPort = $SERVER_PORT
secretKey = "$SECRET_KEY"
EOF

# 设置权限
chmod +x etpc

# 创建 systemd 服务
echo "🔧 创建系统服务..."
cat > /etc/systemd/system/${SERVICE_NAME}.service <<EOF
[Unit]
Description=ETP Client Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/etpc
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
systemctl daemon-reload
systemctl enable ${SERVICE_NAME}
systemctl start ${SERVICE_NAME}

echo ""
echo "✅ ETP 客户端安装完成！"
echo ""
echo "📍 安装目录: $INSTALL_DIR"
echo "🔗 服务器地址: $SERVER_ADDR:$SERVER_PORT"
echo ""
echo "常用命令:"
echo "  查看状态: systemctl status ${SERVICE_NAME}"
echo "  查看日志: journalctl -u ${SERVICE_NAME} -f"
echo "  重启服务: systemctl restart ${SERVICE_NAME}"
echo "  停止服务: systemctl stop ${SERVICE_NAME}"
echo ""
