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
        echo "4. 退出"

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
    if ! curl -L -o pop "https://dl.pipecdn.app/v0.2.4/pop"; then
        echo "curl 下载失败，尝试使用 wget..."
        wget -O pop "https://dl.pipecdn.app/v0.2.4/pop"
    fi

    # 修改文件权限
    chmod +x pop

    # 创建下载缓存目录
    mkdir -p download_cache

    echo "下载完成，文件名为 pop，已赋予执行权限，并创建了 download_cache 目录。"

    # 让用户输入邀请码，如果未输入，则使用默认邀请码
    read -p "请输入邀请码（默认：41d562e5663104c）：" REFERRAL_CODE
    REFERRAL_CODE=${REFERRAL_CODE:-41d562e5663104c}  # 如果用户没有输入，则使用默认邀请码
    echo "使用的邀请码是：$REFERRAL_CODE"

    # 让用户输入内存大小、磁盘大小和 Solana 地址，设置默认值
    read -p "请输入分配内存大小（默认：4，单位：GB）：" MEMORY_SIZE
    MEMORY_SIZE=${MEMORY_SIZE:-4}  # 如果用户没有输入，则使用默认值 4
    MEMORY_SIZE="${MEMORY_SIZE}G"  # 确保单位为 G

    read -p "请输入分配磁盘大小（默认：100，单位：GB）：" DISK_SIZE
    DISK_SIZE=${DISK_SIZE:-100}  # 如果用户没有输入，则使用默认值 100
    DISK_SIZE="${DISK_SIZE}G"  # 确保单位为 G

    read -p "请输入 Solana 地址： " SOLANA_ADDRESS

    # 使用 screen 执行 ./pop
    screen -dmS pipe ./pop --ram $MEMORY_SIZE --max-disk $DISK_SIZE --cache-dir /data --pubKey $SOLANA_ADDRESS --signup-by-referral-route $REFERRAL_CODE

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
    mkdir -p ~/pop  # 创建 pop 目录
    cp /root/node_info.json ~/pop/  # 备份文件到 pop 目录
    echo "备份完成，node_info.json 已备份到 ~/pop/ 目录。"
    read -p "按任意键返回主菜单..."
}

# 生成邀请
function generate_referral() {
    echo "正在生成 pop邀请码..."
    ./pop --gen-referral-route
    read -p "按任意键返回主菜单..."
}

# 启动主菜单
main_menu
