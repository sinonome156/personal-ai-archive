# AI-READONLY: scripts —— 仓库自检工具

## security-scan.ps1
扫描文件中的**凭据泄露**与**雇主可锁定 PII**，命中即非零退出（用于拦截提交）。

- 内置凭据特征：GitHub OAuth/PAT 令牌前缀、AWS AKIA、PEM 私钥头、JWT、`某密钥=长随机值`形态、身份证/银行卡位数。
- 雇主词表来自仓库根的 **`.pii-blocklist.local.txt`**（已 gitignore，真实词永不入库；模板见 `pii-blocklist.example.txt`）。

用法：
```powershell
# 扫全部入库文件
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/security-scan.ps1
# 只扫暂存文件（pre-commit 用）
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/security-scan.ps1 -Staged
```

## pre-commit 钩子
`.git/hooks/pre-commit` 已安装：每次 `git commit` 自动跑 `-Staged` 扫描，命中即阻止提交。
换设备重新克隆后需重装一次（钩子不随仓库同步），命令：把 `scripts/pre-commit.sh` 内容复制到 `.git/hooks/pre-commit`。

## 已知取舍
- `\b\d{16,19}\b` 可能误报长数字串；若确有此类数据，在本地名单外按需微调脚本阈值，勿放宽凭据规则。
- 扫描只覆盖"当前/暂存内容"，不覆盖历史。历史泄露的处置见仓库 README「版本保护」与 AGENTS.md 第 4 节"历史不可回收"。
