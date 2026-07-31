@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:menu
cls
echo ========================================
echo   BuildSelf App - Git 日常操作工具
echo ========================================
echo.
echo 当前分支:
git branch --show-current
echo.
echo 当前状态:
git status --short --branch
echo.
echo ========================================
echo   请选择操作:
echo ========================================
echo.
echo   [1] 查看更改详情 (git diff)
echo   [2] 添加所有更改并提交 (快速提交)
echo   [3] 查看提交历史
echo   [4] 切换分支
echo   [5] 创建新分支
echo   [6] 合并指定分支到当前分支
echo   [7] 删除分支
echo   [8] 推送到远程仓库
echo   [9] 从远程仓库拉取
echo   [0] 退出
echo.
set /p choice="请输入选项编号 (0-9): "

if "%choice%"=="1" goto :diff
if "%choice%"=="2" goto :quick_commit
if "%choice%"=="3" goto :log
if "%choice%"=="4" goto :switch_branch
if "%choice%"=="5" goto :new_branch
if "%choice%"=="6" goto :merge_branch
if "%choice%"=="7" goto :delete_branch
if "%choice%"=="8" goto :push
if "%choice%"=="9" goto :pull
if "%choice%"=="0" goto :eof
echo.
echo [错误] 无效选项，请重新选择
pause
goto :menu

:diff
cls
echo ========================================
echo   更改详情
echo ========================================
git diff
echo.
pause
goto :menu

:quick_commit
cls
echo ========================================
echo   快速提交
echo ========================================
echo.
echo 提交类型:
echo   feat     - 新功能
echo   fix      - 修复 bug
echo   refactor - 重构（既不是新功能也不是修 bug）
echo   style    - 样式/UI 调整
echo   perf     - 性能优化
echo   docs     - 文档变更
echo   chore    - 构建/工具/依赖变更
echo   remove   - 删除功能/文件
echo.
set /p type="请输入类型 (feat/fix/refactor/style/perf/docs/chore/remove): "
set /p msg="请输入提交描述: "

if "!msg!"=="" (
    echo [错误] 提交描述不能为空
    pause
    goto :menu
)

if "!type!"=="" set "type=chore"

echo.
git add -A
git commit -m "!type!: !msg!"

if !errorlevel! equ 0 (
    echo.
    echo √ 提交成功！
) else (
    echo.
    echo [警告] 无新内容可提交或提交失败
)
echo.
pause
goto :menu

:log
cls
echo ========================================
echo   最近 15 条提交记录
echo ========================================
git log --oneline --graph --decorate -15
echo.
echo  [按 q 退出查看]
pause
goto :menu

:switch_branch
cls
echo ========================================
echo   切换分支
echo ========================================
echo.
echo 可用分支:
git branch
echo.
set /p branch="请输入要切换的分支名: "
if "!branch!"=="" goto :menu
git checkout !branch!
echo.
pause
goto :menu

:new_branch
cls
echo ========================================
echo   创建新分支
echo ========================================
echo.
echo 命名建议:
echo   feature/xxx  - 新功能，如 feature/dark-mode
echo   fix/xxx      - 修复 bug，如 fix/login-crash
echo   refactor/xxx - 重构，如 refactor/database-layer
echo.
set /p branch="请输入新分支名: "
if "!branch!"=="" goto :menu
git checkout -b !branch!
echo.
echo √ 新分支 !branch! 已创建并切换
echo.
pause
goto :menu

:merge_branch
cls
echo ========================================
echo   合并分支
echo ========================================
echo.
echo 当前分支:
git branch --show-current
echo.
echo 可用分支:
git branch
echo.
set /p branch="请输入要合并到当前分支的分支名: "
if "!branch!"=="" goto :menu
git merge --no-ff !branch!
echo.
pause
goto :menu

:delete_branch
cls
echo ========================================
echo   删除分支
echo ========================================
echo.
echo 可用分支:
git branch
echo.
set /p branch="请输入要删除的分支名: "
if "!branch!"=="" goto :menu
echo.
echo 确认要删除分支 !branch! ? (Y/N)
set /p confirm=": "
if /i not "!confirm!"=="Y" goto :menu
git branch -d !branch!
echo.
pause
goto :menu

:push
cls
echo ========================================
echo   推送到远程仓库
echo ========================================
git remote -v
echo.
git push
echo.
pause
goto :menu

:pull
cls
echo ========================================
echo   从远程仓库拉取
echo ========================================
git pull
echo.
pause
goto :menu

:eof
endlocal
