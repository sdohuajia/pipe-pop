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
        echo "3. 备份 node_info.json"
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

    # 提示用户输入下载链接
    read -p "请输入下载链接: " url

    # 使用 curl 下载文件
    curl -L -o pop "$url"

    # 修改文件权限
    chmod +x pop

    # 创建下载缓存目录
    mkdir -p download_cache

    echo "下载完成，文件名为 pop，已赋予执行权限，并创建了 download_cache 目录。"

    # 使用 pm2 执行 ./pop
    pm2 start ./pop --name "pop_process"

    echo "已使用 pm2 启动 ./pop 进程。"
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

# 启动主菜单
main_menu
