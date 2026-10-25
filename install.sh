#!/bin/bash
# 从仓库所在位置创建 Hammerspoon 配置目录的软链接。
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
user_root="$(cd -- "${HOME:?HOME 未设置}" && pwd -P)"
config_dir="$user_root/.hammerspoon"

if [[ ! -f "$repo_dir/init.lua" || ! -d "$repo_dir/modules" ]]; then
    printf '错误：请从完整的 Hammerspoon 配置仓库运行本脚本。\n' >&2
    exit 1
fi

if [[ "$repo_dir" == "$config_dir" ]]; then
    printf '仓库已位于 %s，无需创建软链接。移动仓库后重新运行本脚本即可。\n' "$config_dir"
    exit 0
fi

if [[ -L "$config_dir" && -d "$config_dir" ]]; then
    linked_dir="$(cd -- "$config_dir" && pwd -P)"
    if [[ "$linked_dir" == "$repo_dir" ]]; then
        printf '软链接已就绪：%s -> %s\n' "$config_dir" "$repo_dir"
        exit 0
    fi
fi

if [[ -e "$config_dir" || -L "$config_dir" ]]; then
    printf '目标位置已有配置：%s\n安装已停止，请自行处理后重新运行。\n' "$config_dir" >&2
    exit 1
fi

ln -s -- "$repo_dir" "$config_dir"
printf '已创建软链接：%s -> %s\n' "$config_dir" "$repo_dir"
printf '请重新加载 Hammerspoon 配置。\n'
