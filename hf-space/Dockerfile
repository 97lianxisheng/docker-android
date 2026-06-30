# Hugging Face Space 精简 Dockerfile
# 完整镜像由 GitHub Actions 构建并推送到 GHCR，此处仅引用预构建镜像。
#
# 使用前请将下方镜像地址替换为你的 GHCR 地址：
#   ghcr.io/<GitHub用户名>/<仓库名>:latest
#
# 示例（本仓库）：
#   ghcr.io/hqarroum/docker-android:latest

FROM ghcr.io/<username>/<repo-name>:latest

# Hugging Face Docker Space 对外暴露端口（转发至 ADB 5555）
ENV PORT=7860

COPY hf-entrypoint.sh /opt/hf-entrypoint.sh
RUN chmod +x /opt/hf-entrypoint.sh

EXPOSE 7860

ENTRYPOINT ["/opt/hf-entrypoint.sh"]
