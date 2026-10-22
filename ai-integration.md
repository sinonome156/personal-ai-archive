# AI-READONLY: 跨 AI 平台接入配置（ai-integration）

> 本文件回答一个问题：**怎么把这个仓库接到各类 AI 平台上，让它们读取你的档案、按协议写回。**
> 平台信息核实日期：2026-10-22。AI 平台功能变化快，接入前以各平台官方文档为准。

## 0. 通用读取原理（所有平台共用）

GitHub 公开仓库的内容可通过 raw 链接直接读取，无需登录：

```
https://raw.githubusercontent.com/sinonome156/personal-ai-archive/main/<目录>/<文件>.md
```

任何支持"访问网址 / 上传文件 / 克隆仓库"的 AI 都能消费本档案。推荐接入深度从浅到深：

| 层级 | 能力 | 适用 |
|---|---|---|
| L1 只读引用 | AI 能读档案（贴链接/上传文件） | 所有平台，5 分钟搞定 |
| L2 持久记忆 | 平台把档案存为长期知识（Projects/Gems/知识库） | ChatGPT、Claude、Gemini |
| L3 自动同步 | AI 通过 GitHub 授权直接读写仓库、按 AGENTS.md 写回 | 编码 Agent、支持 GitHub 集成的 Agent |

## 1. ChatGPT（OpenAI）

**L1 快速接入**：新对话中直接说——
> 请先阅读我的个人档案仓库的以下文件，之后按其中约定与我协作：
> https://raw.githubusercontent.com/sinonome156/personal-ai-archive/main/AGENTS.md
> https://raw.githubusercontent.com/sinonome156/personal-ai-archive/main/identity/00-profile.md
> （按需追加其余文件链接）

**L2 Projects**：ChatGPT → Projects → 新建 Project → Custom instructions 粘贴档案要点 → Knowledge 上传 `identity/`、`workflow/` 的 .md 文件（或连接 GitHub 授权后直接挂载本仓库）。该 Project 内的所有对话自动继承档案。
**注意**：ChatGPT 记忆功能（Memory）与本仓库互补——记忆存平台内、档案存 GitHub；以档案为权威源，冲突时要求 AI 以仓库内容为准并回写修正。

**OpenAI dots（常驻个人 Agent）**：dots 拥有独立云端电脑与浏览器，可要求它克隆本仓库并在完成任务后按 `AGENTS.md` 第 2、3 节协议写回提交（需向其配置 GitHub 授权，见第 6 节安全建议）。
**可用性提示**：dots 随 ChatGPT Pro / Business Premium 提供，2026-09 上线，首发不含欧洲经济区/英国，逐步推送中。

## 2. Claude（Anthropic）

**L1**：对话开头贴 raw 链接（同 ChatGPT 方式）。
**L2 Projects**：Claude → Projects → 新建 → Knowledge 上传档案 .md 文件 + 把 `AGENTS.md` 全文粘贴进 Custom instructions。所有该 Project 的对话遵循协议。
**L3**：Claude Desktop / Claude Code 可通过 GitHub MCP 连接器直接读写仓库；**Claude Code 在本地克隆目录运行时会自动读取根目录 `AGENTS.md`，本仓库克隆到本地即天然接入**（Codex CLI、Cursor 等同样支持 AGENTS.md 标准）。

## 3. Gemini（Google）

**L1**：对话中贴 raw 链接要求先读后答。
**L2 Gems**：Gemini → 新建 Gem → Instructions 粘贴 `AGENTS.md` 第 1、2 节 + Knowledge 上传 `identity/`、`workflow/` 文件。
**提示**：Gemini 的文件知识容量与读取优先级策略调整频繁，重要档案建议同时在 Instructions 里放一段"档案摘要 + 仓库地址"作为兜底。

## 4. Meta Muse

Muse（2026-09 上线的个人 Agent，运行于独立云端 VM，内置浏览器）接入方式：
- **L1 读取**：首次任务时发给它——"访问并记住 https://github.com/sinonome156/personal-ai-archive 的 AGENTS.md 与 identity/ 内容，之后按此与我协作"。
- **L3 写回**：可行但谨慎——需向 Muse 授予 GitHub 授权。**建议只授予只读**，写回交给有本地 git 环境的 Agent（第 5 节），原因见第 6 节。
- **可用性提示**：Muse 目前仅在美国、加拿大提供服务（iOS/Android/网页/Mac）。

## 5. 本地编码 / 桌面 Agent（QwenWork、豆包办公、Claude Code、Codex、Cursor 等）

最深度接入，三步：

```bash
# ① 克隆到固定位置（各设备统一路径，便于所有 Agent 引用）
git clone https://github.com/sinonome156/personal-ai-archive.git ~/personal-ai-archive

# ② 在 Agent 的全局配置中注册（各家写法不同，任选其一）
#    - 支持 AGENTS.md 标准的 Agent：直接在该 Agent 的工作目录设置指向本仓库，或在仓库内继续维护该 Agent 的专属子目录
#    - QwenWork/豆包办公：将仓库路径加入其"记忆/知识库"目录，或把本文件要点并入 ~/.qwenworkcn/awareness 的 USER.md/MEMORY.md
# ③ 建立同步习惯（每天开工前一条命令拉取最新版，收尾时写回）
git -C ~/personal-ai-archive pull --rebase
```

这些 Agent 拥有 shell + git 能力，是唯一能完整执行 `AGENTS.md` 写回协议（提交、规范 commit message）的层级——**把它作为档案的"主笔"，对话类 AI 作为"读者"**。

## 6. 自动更新规则与写回触发语

写回协议本体见 `AGENTS.md` 第 2、3 节。日常只需记住一句触发语（可发给任何有写权限的 Agent）：

> 「把本次任务形成的偏好/决策/经验，按仓库 AGENTS.md 的写回协议归档到 personal-ai-archive 对应文件，单独提交并推送；没有增量就不写。」

**给 Agent 配置 GitHub 写权限（重要·安全）：**
- 使用 **Fine-grained Personal Access Token**：只授权 `personal-ai-archive` 这一个仓库、权限只勾 **Contents: Read and write**、设置过期时间。绝不用全账号权限的 classic token。
- Token 属于机密：**永不提交进仓库、永不贴进对话**；通过 Agent 的凭据管理功能（如 git credential manager、环境变量）注入。
- 公开档案 + 公开仓库 ≠ 可被任意人修改：写权限只在你手里的 Token；他人只能读和 fork。

## 7. 多设备一致性规则

- 冲突处理：所有设备先 `pull --rebase` 再写；文本冲突时保留双方条目（追加式文件的特性使然），标注 `[待合并 YYYY-MM-DD]` 留给下次人工裁决。
- 换设备迁移成本 = 0：新设备上任何 AI 按第 1~5 节重新接入即可，档案本身跟人走。
