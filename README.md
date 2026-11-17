# The Best Novels

基于 Hugo 的经典长篇小说阅读站点。书籍与章节内容来自导出的数据，`data/library.json` 保存书籍目录、章节顺序和上下章导航索引。

## 本地开发

需要 Hugo 0.165.0 或更高版本（extended）。

```bash
# 本地预览
hugo server

# 重新生成书籍/章节数据索引（在导出内容发生变化后执行）
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/build-library-data.ps1

# 生成本地静态站点
hugo --gc --minify
```

## 自动部署

推送到 `main` 或 `master` 会触发 `.github/workflows/deploy.yml`：

- 构建并部署到 GitHub Pages；
- 同时以根路径 `/` 重新构建，把静态文件发布到 `gh-pages` 分支，供远程 Web 服务器使用。

## 远程服务器更新（Git）

远程服务器上的站点目录是静态文件的 Git 检出，部署分支为 `gh-pages`。在服务器上进入站点目录后执行：

```bash
git pull --ff-only origin gh-pages
```

也可以从本地通过 SSH 一次性执行：

```bash
ssh <your-server-alias> 'git -C /path/to/site pull --ff-only origin gh-pages'
```

其中：

- `<your-server-alias>` 替换为你的 SSH 主机别名；
- `/path/to/site` 替换为服务器上站点目录的实际路径；
- `--ff-only` 用于fast-forward 更新，避免产生合并提交；
- 拉取会保留未跟踪文件，例如域名验证用的 `.well-known/` 目录，不要手动删除；
- 静态文件更新后通常无需重启 Web 服务；若启用了页面缓存，请按实际环境清理缓存。

## 主要目录

- `content/`：站点内容与章节 Markdown
- `data/library.json`：书籍与章节导航数据
- `layouts/`：Hugo 模板
- `assets/`：样式与脚本
- `scripts/`：数据索引生成脚本
- `.github/workflows/`：自动部署工作流
