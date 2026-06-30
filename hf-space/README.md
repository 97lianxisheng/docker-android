# Hugging Face Space 部署模板

本目录提供 **精简 Dockerfile**，用于在 [Hugging Face Spaces](https://huggingface.co/spaces) 上部署 Android 模拟器。完整镜像在 GitHub Actions 中构建并推送到 GHCR，Space 侧只负责拉取并运行。

## 架构

```
GitHub 仓库（完整 Dockerfile + scripts）
        │
        ▼
GitHub Actions（.github/workflows/build-ghcr.yml）
        │  docker build + push
        ▼
ghcr.io/<用户名>/<仓库名>:latest   ← 完整镜像存储位置
        │
        ▼
HF Space（本目录 Dockerfile）
        │  FROM ghcr.io/... + 7860 → ADB 5555 转发
        ▼
Hugging Face 拉取镜像并启动容器
```

## 前置条件

1. 将本仓库推送到你的 GitHub 账号（Fork 或新建仓库均可）。
2. 在 GitHub 仓库 **Settings → Actions → General** 中，确认 Workflow 有权限写入 Packages。
3. 首次推送 `main` 分支后，Actions 会自动构建并推送镜像到：

   ```
   ghcr.io/<你的GitHub用户名>/<仓库名>:latest
   ```

4. 在 GitHub **Packages** 页面将对应包设为 **Public**（公开 Space 必须公开镜像），或在 Space 中配置私有 Registry 凭据。

## 创建 Hugging Face Space

1. 打开 [Hugging Face Spaces](https://huggingface.co/new-space)。
2. 选择 **Docker** 作为 SDK。
3. 新建 Space 后，将本目录内容上传至 Space 根目录（或复制 `Dockerfile` 与 `README.md`）。
4. 编辑 `Dockerfile`，把占位符替换为实际 GHCR 地址：

   ```dockerfile
   FROM ghcr.io/<username>/<repo-name>:latest
   ENV PORT=7860
   # 7860 通过 socat 转发到 ADB 5555（见 hf-entrypoint.sh）
   ```

   示例：

   ```dockerfile
   FROM ghcr.io/hqarroum/docker-android:latest
   ENV PORT=7860
   ```

5. 保存后 Space 会自动构建并部署。

## 私有 GHCR 镜像（可选）

若 GHCR 包为私有，在 Space **Settings → Repository secrets** 中添加：

| Secret 名称 | 说明 |
|-------------|------|
| `GHCR_USERNAME` | GitHub 用户名 |
| `GHCR_TOKEN` | 具有 `read:packages` 的 Personal Access Token |

并在 Space 的 `README.md` front matter 中声明 Docker 凭据（HF 文档要求）：

```yaml
---
title: Android Emulator
sdk: docker
app_port: 7860
---
```

> 具体 secret 名称以 [HF Docker Spaces 文档](https://huggingface.co/docs/hub/spaces-sdks-docker) 为准。

## 手动触发构建

除 `main` 分支自动构建外，可在 GitHub **Actions → Build and push to GHCR → Run workflow** 手动触发，并选择：

- `Dockerfile` 或 `Dockerfile.gpu`
- Android API level（默认 33）
- 系统镜像类型（`google_apis` / `google_apis_playstore`）

## 端口说明

| 端口 | 用途 |
|------|------|
| `7860` | HF Space 对外端口，**socat 转发到 ADB 5555** |
| `5555` | 容器内 ADB 端口（不对外直接暴露） |

连接模拟器（通过 HF Space 对外地址）：

```bash
adb connect <your-space>.hf.space:7860
```

本地验证转发（映射 7860）：

```bash
docker run -it --rm --privileged -p 7860:7860 ghcr.io/<username>/<repo-name>:latest
adb connect 127.0.0.1:7860
```

## 重要限制

- **KVM / 硬件加速**：HF Space 通常无法挂载 `/dev/kvm`，模拟器将以软件渲染运行，性能较低。
- **资源需求**：API 33 镜像建议至少 **8 GB 磁盘**、**4 GB 内存**；可在 Space 硬件档位中选择更高配置。
- **镜像体积**：完整镜像约 **2 GB（压缩）**，首次拉取较慢，属正常现象。
- **持久化**：Space 重启后 `/data` 内 AVD 数据可能丢失，如需持久化请自行挂载 Volume（取决于 Space 计划能力）。

## 本地验证 GHCR 镜像

在推送 Space 之前，可先本地拉取验证：

```bash
docker pull ghcr.io/<username>/<repo-name>:latest
docker run -it --rm --privileged -p 7860:7860 ghcr.io/<username>/<repo-name>:latest
adb connect 127.0.0.1:7860
```

## 相关文件

| 文件 | 说明 |
|------|------|
| [`../Dockerfile`](../Dockerfile) | 完整构建定义（含 Android SDK / 模拟器） |
| [`../.github/workflows/build-ghcr.yml`](../.github/workflows/build-ghcr.yml) | GHCR 构建与推送工作流 |
| [`Dockerfile`](Dockerfile) | HF Space 精简 Dockerfile 模板 |
| [`hf-entrypoint.sh`](hf-entrypoint.sh) | 7860 → ADB 5555 转发 + 启动模拟器 |
