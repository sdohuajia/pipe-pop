#!/bin/bash

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "请使用root权限运行此脚本"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/pipe Pop.sh"

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "新建了一个电报群，方便大家交流：t.me/Sdohua"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1. 运行pipe Pop节点"
        echo "2. 查看节点运行日志"
        echo "3. 查看节点私钥"
        echo "================================================================"
        read -p "请输入选项 (1-3): " choice

        case $choice in
            1)
                run_pipe_node
                ;;
            2)
                view_node_logs
                ;;
            3)
                show_private_key
                ;;
            *)
                echo "无效的选项，请重新选择"
                sleep 2
                ;;
        esac
    done
}

# 查看日志的函数
function view_node_logs() {
    echo "正在查看dcdnd服务日志..."
    echo "提示：按 Ctrl+C 可以退出日志查看"
    sleep 2
    sudo journalctl -f -u dcdnd.service
}

# 查看私钥的函数
function show_private_key() {
    echo "正在获取节点私钥..."
    if [ -f /opt/dcdn/pipe-tool ]; then
        /opt/dcdn/pipe-tool show-private-key
        echo -e "\n请安全保管您的私钥！"
        echo -e "按任意键返回主菜单..."
        read -n 1 -s -r
    else
        echo "错误：找不到pipe-tool工具，请确保节点已正确安装"
        echo -e "\n按任意键返回主菜单..."
        read -n 1 -s -r
    fi
}

# 运行pipe节点的函数
function run_pipe_node() {
    # 提示用户输入下载链接
    echo -e "\n=== 配置下载链接 ==="
    read -p "请输入 pipe-tool 的下载链接: " PIPE_URL
    read -p "请输入 dcdnd 的下载链接: " DCDND_URL

    # 验证用户输入
    if [ -z "$PIPE_URL" ] || [ -z "$DCDND_URL" ]; then
        echo "错误：下载链接不能为空"
        echo -e "\n按任意键返回主菜单..."
        read -n 1 -s -r
        return
    fi

    echo "开始安装和配置 Pipe 节点..."
    
    # 更新系统并安装必要工具
    apt update && apt upgrade -y
    apt install -y curl wget sudo ufw

    # 创建工作目录
    mkdir -p /opt/dcdn
    cd /opt/dcdn

    # 下载文件
    echo "正在下载 pipe-tool..."
    curl -L "$PIPE_URL" -o /opt/dcdn/pipe-tool || {
        echo "下载 pipe-tool 失败"
        exit 1
    }

    echo "正在下载 dcdnd..."
    curl -L "$DCDND_URL" -o /opt/dcdn/dcdnd || {
        echo "下载 dcdnd 失败"
        exit 1
    }

    # 设置执行权限
    chmod +x pipe-tool dcdnd

    # 配置防火墙
    ufw allow 22
    ufw allow 8080
    ufw allow 9000
    ufw --force enable

    # 创建并配置服务文件
    cat > /etc/systemd/system/dcdnd.service << EOF
[Unit]
Description=dcdnd
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/dcdn
ExecStart=/opt/dcdn/dcdnd
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

    # 启动服务
    systemctl daemon-reload
    systemctl enable dcdnd
    systemctl start dcdnd

    # 等待服务启动
    echo "等待服务启动..."
    sleep 10

    # 钱包设置功能
    echo -e "\n=== 钱包设置 ==="
    echo "请选择以下操作："
    echo "1. 生成新钱包"
    echo "2. 导入已有钱包"
    read -p "请输入选项 (1 或 2): " wallet_choice

    case $wallet_choice in
        1)
            echo -e "\n正在生成新钱包..."
            /opt/dcdn/pipe-tool generate-wallet --node-registry-url="https://rpc.pipedev.network"
            echo "新钱包已生成完成！"
            ;;
        2)
            echo -e "\n请输入您的 base58 编码的公钥："
            read -p "公钥: " public_key
            echo -e "\n正在导入钱包..."
            /opt/dcdn/pipe-tool link-wallet --node-registry-url="https://rpc.pipedev.network" --public-key="$public_key"
            echo "钱包导入完成！"
            ;;
        *)
            echo "无效的选项，程序将退出..."
            exit 1
            ;;
    esac

    # 链接钱包
    echo -e "\n=== 正在链接钱包 ==="
    /opt/dcdn/pipe-tool link-wallet --node-registry-url="https://rpc.pipedev.network"
    echo "钱包链接完成！"

    # 检查服务状态
    echo -e "\n=== 检查服务状态 ==="
    systemctl status dcdnd

    echo -e "\n=== 所有操作已完成 ==="
    echo "节点安装和配置已全部完成，钱包设置和链接成功！"
    
    # 等待用户确认后返回主菜单
    echo -e "\n按任意键返回主菜单..."
    read -n 1 -s -r
}

# 启动主菜单
main_menu
