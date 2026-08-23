@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo   BuildSelf App - Git 版本管理初始化工具
echo ========================================
echo.

REM 检查 git 是否安装
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未检测到 Git，请先安装 Git for Windows
    echo 下载地址: https://git-scm.com/download/win
    pause
    exit /b 1
)

echo [1/6] 检查当前 git 状态...
git status >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo Git 仓库已初始化，跳过初始化步骤。
    goto :after_init
)

echo.
echo [2/6] 初始化 Git 仓库...
git init -b main
if %errorlevel% neq 0 (
    echo [错误] Git 初始化失败！
    pause
    exit /b 1
)
echo √ Git 仓库初始化成功（默认分支: main）

echo.
echo [3/6] 配置用户信息...
set /p git_name="请输入 Git 用户名 (如: 张三): "
set /p git_email="请输入 Git 邮箱 (如: zhangsan@example.com): "

if not "!git_name!"=="" (
    git config user.name "!git_name!"
    echo √ 用户名已设置: !git_name!
)
if not "!git_email!"=="" (
    git config user.email "!git_email!"
    echo √ 邮箱已设置: !git_email!
)

REM 配置一些实用的 git 默认设置
git config core.autocrlf true
git config init.defaultBranch main
echo √ Git 换行符策略已配置 (Windows: CRLF - LF)
echo √ 默认分支已设置为 main

:after_init
echo.
echo [4/6] 添加项目文件到暂存区...
git add -A
echo √ 文件已添加

echo.
echo [5/6] 提交初始版本...
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value ^| find "="') do set "dt=%%I"
set "datetime=!dt:~0,4!-!dt:~4,2!-!dt:~6,2! !dt:~8,2!:!dt:~10,2!"

git commit -m "chore: 初始提交 - 当前手机可运行的稳定版本

- 完成 Flutter 项目基础架构搭建
- 实现底部 Tab 导航（工作/生活/目标/阅读/设置）
- 首页问候语、App 图标和应用名称已配置
- 各模块基础功能可正常运行
- 数据库和数据模型已建立

提交时间: !datetime!"

if %errorlevel% neq 0 (
    echo [警告] 提交失败或无新内容可提交
) else (
    echo √ 初始版本提交成功！
)

echo.
echo [6/6] 创建开发分支 develop...
git branch develop >nul 2>&1
git checkout -b develop >nul 2>&1
echo √ 开发分支 develop 已创建并切换

echo.
echo ========================================
echo   Git 版本管理设置完成！
echo ========================================
echo.
echo 当前分支:
git branch -a
echo.
echo 最近提交记录:
git log --oneline -5
echo.
echo ========================================
echo   后续使用指南
echo ========================================
echo.
echo 日常开发流程（在 develop 分支上）:
echo   1. 修改代码后，查看更改:   git status
echo   2. 添加更改到暂存区:       git add .
echo   3. 提交更改:               git commit -m "描述信息"
echo.
echo 新功能开发建议:
echo   git checkout develop          ^<-- 切换到 develop 分支
echo   git checkout -b feature/xxx   ^<-- 创建新功能分支，如 feature/dark-mode
echo   ^(开发完成后^)
echo   git checkout develop
echo   git merge feature/xxx         ^<-- 合并回 develop
echo   git branch -d feature/xxx     ^<-- 删除功能分支
echo.
echo 里程碑/稳定版本发布:
echo   git checkout main
echo   git merge develop             ^<-- 将 develop 合并到 main 打标签
echo   git tag v1.0.0                ^<-- 打版本标签
echo   git checkout develop
echo.
echo 连接远程仓库 ^(如 GitHub/Gitee ^(可选^)^):
echo   git remote add origin ^<仓库地址^>
echo   git push -u origin main
echo   git push -u origin develop
echo.
pause
