#!/bin/bash

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "请使用root权限运行此脚本"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/pipe pop.sh"

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1. 部署 pipe pop节点"
        echo "2. 查看声誉"
        echo "3. 备份 info"
        echo "4. 生成pop邀请（必须运行1）"
        echo "5. 升级版本（升级前必须备份info）"
        echo "6. 退出"

        read -p "请输入选项: " choice

        case $choice in
            1)
                deploy_pipe_pop
                ;;
            2)
                check_status
                ;;
            3)
                backup_node_info
                ;;
            4)
                generate_referral
                ;;
            5)
                upgrade_version
                ;;
            6)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效选项，请重新选择。"
                read -p "按任意键继续..."
                ;;
        esac
    done
}

# 部署 pipe pop 函数
function deploy_pipe_pop() {
    # 检测 DevNet 1 节点服务是否正在运行
    if systemctl is-active --quiet dcdnd.service; then
        echo "DevNet 1 节点服务正在运行，正在停止并禁用该服务..."
        sudo systemctl stop dcdnd.service
        sudo systemctl disable dcdnd.service
    else
        echo "DevNet 1 节点服务未运行，无需操作。"
    fi

    # 配置防火墙，允许 TCP 端口 8003
    echo "配置防火墙，允许 TCP 端口 8003..."
    sudo ufw allow 8003/tcp
    sudo ufw reload
    echo "防火墙已更新，允许 TCP 端口 8003。"

    # 安装 screen 环境
    echo "正在安装 screen..."
    sudo apt-get update
    sudo apt-get install -y screen

    # 使用 curl 下载文件
    echo "尝试使用 curl 下载文件..."
    if ! curl -L -o pop "https://dl.pipecdn.app/v0.2.5/pop"; then
        echo "curl 下载失败，尝试使用 wget..."
        wget -O pop "https://dl.pipecdn.app/v0.2.5/pop"
    fi

    # 修改文件权限
    chmod +x pop

    # 创建下载缓存目录
    mkdir -p download_cache

    echo "下载完成，文件名为 pop，已赋予执行权限，并创建了 download_cache 目录。"

    # 让用户输入邀请码，如果未输入，则使用默认邀请码
    read -p "请输入邀请码（默认：cb2927df9209ba0a）：" REFERRAL_CODE
    REFERRAL_CODE=${REFERRAL_CODE:-cb2927df9209ba0a}  # 如果用户没有输入，则使用默认邀请码
    echo "使用的邀请码是：$REFERRAL_CODE"

    # 让用户输入内存大小、磁盘大小和 Solana 地址，设置默认值
    read -p "请输入分配内存大小（默认：4，单位：GB）：" MEMORY_SIZE
    MEMORY_SIZE=${MEMORY_SIZE:-4}  # 如果用户没有输入，则使用默认值 4
    MEMORY_SIZE="${MEMORY_SIZE}"  # 确保单位为 G

    read -p "请输入分配磁盘大小（默认：100，单位：GB）：" DISK_SIZE
    DISK_SIZE=${DISK_SIZE:-100}  # 如果用户没有输入，则使用默认值 100
    DISK_SIZE="${DISK_SIZE}"  # 确保单位为 G

    read -p "请输入 Solana 地址： " SOLANA_ADDRESS

    # 使用 screen 执行 ./pop
    screen -dmS pipe ./pop --ram $MEMORY_SIZE --max-disk $DISK_SIZE --cache-dir /data --pubKey $SOLANA_ADDRESS

    echo "已使用 screen 启动 ./pop 进程。"

    # 提示用户如何进入后台
    echo "要查看正在运行的进程或重新进入该会话，请使用以下命令："
    echo "  screen -r pipe"
    
    read -p "按任意键返回主菜单..."
}

# 查看声誉函数
function check_status() {
    echo "正在查看 ./pop 的状态..."
    ./pop --status
    read -p "按任意键返回主菜单..."
}

# 备份 node_info.json 函数
function backup_node_info() {
    echo "正在备份 node_info.json 文件..."
    cp ~/node_info.json ~/node_info.backup2-4-25  # 备份文件到新的目标文件
    echo "备份完成，node_info.json 已备份到 ~/node_info.backup2-4-25 文件。"
    read -p "按任意键返回主菜单..."
}

# 生成pop邀请
function generate_referral() {
    echo "正在生成 pop邀请码..."
    ./pop --gen-referral-route
    read -p "按任意键返回主菜单..."
}

# 升级版本 (2.0.5)
function upgrade_version() {
    echo "正在升级到版本 2.0.5..."

    # 检查并停止运行中的 pipe screen 会话
    if screen -list | grep -q "pipe"; then
        echo "检测到 pipe screen 会话正在运行，正在终止..."
        screen -S pipe -X quit
        echo "pipe screen 会话已终止。"
    else
        echo "没有检测到正在运行的 pipe screen 会话。"
    fi

    # 创建 /opt/pop 目录，如果目录不存在
    sudo mkdir -p /opt/pop

    # 下载新版本的 pop 直接保存到 /opt/pop/pop
    sudo wget -O /opt/pop/pop "https://dl.pipecdn.app/v0.2.5/pop"
    sudo chmod +x /opt/pop/pop

    # 创建 /var/lib/pop 目录，如果目录不存在
    sudo mkdir -p /var/lib/pop

    # 备份 node_info.backup2-4-25 到 /var/lib/pop 并重命名为 node_info.json
    if [ -f ~/node_info.backup2-4-25 ]; then
        echo "备份 node_info.backup2-4-25 到 /var/lib/pop/ 目录，并重命名为 node_info.json..."
        sudo cp ~/node_info.backup2-4-25 /var/lib/pop/node_info.json
        echo "备份完成，文件已重命名为 node_info.json。"
    else
        echo "未找到 node_info.backup2-4-25 文件，跳过备份步骤。"
    fi

    # 修改工作目录
    cd /var/lib/pop

    # 刷新 pop 配置
    /opt/pop/pop --refresh

    echo "升级完成，pop 已更新为版本 2.0.5。"

    read -p "按任意键返回主菜单..."
}

# 启动主菜单
main_menu
