---
phase: 2
title: "File compose Dokploy"
status: pending
priority: P1
dependencies: [1]
---

# Phase 2: File compose Dokploy

## Overview
Thêm một bản compose dành cho Dokploy vào fork. Traefik của Dokploy giữ cổng 80 và 443 và lo HTTPS. Caddy chỉ chuyển request từ Traefik vào socket của server.

## Requirements
- **Không publish cổng nào ra host.** Cổng 80 và 443 thuộc Traefik dùng chung.
- Server vẫn chỉ nghe trên loopback và socket, giữ đúng thiết kế upstream (`server/lan-address.ts`: không bật `OMB_LAN`).
- Proxy phải chuyển đúng `Host`, `X-Forwarded-For` và `X-Forwarded-Proto: https`, không buffer SSE, và hỗ trợ WebSocket (`docs/self-hosting.md`, mục "Putting a proxy in front").
- Volume `data` cố định qua mỗi lần redeploy. Không bật `isolatedDeployment` hay `randomize`.

## Architecture
```
Internet → Traefik (Dokploy, TLS) → caddy:80 (dokploy-network) → unix socket /run/openmausbot/http.sock → omb
                                                              → /hooks/* → hooks.sock
```
Lý do giữ Caddy: Traefik không tự tới được socket. Bật `OMB_LAN=1` sẽ đổi luật truy cập "local". Caddy thì là cách upstream đã kiểm chứng.

## Related Code Files
- Tạo `deploy/dokploy/docker-compose.yml`.
- Tạo `deploy/dokploy/Caddyfile`.
- Dùng lại `deploy/local/Dockerfile`: image gốc cộng các CLI Claude Code, Codex và Grok. File này giữ nguyên.

## Implementation Steps
1. Viết `deploy/dokploy/Caddyfile` theo mẫu đã kiểm chứng của repo (`deploy/fly/Caddyfile:18-27`, `deploy/fly/edge-routes.caddy`):
   ```
   {
   	admin off
   	auto_https off
   	servers {
   		trusted_proxies static private_ranges
   		trusted_proxies_strict
   		client_ip_headers X-Forwarded-For
   	}
   }
   :80 {
   	encode zstd gzip
   	handle /hooks/* {
   		reverse_proxy unix//run/openmausbot/hooks.sock {
   			header_up X-Forwarded-Proto https
   			header_up X-Forwarded-For {client_ip}
   		}
   	}
   	handle {
   		reverse_proxy unix//run/openmausbot/http.sock {
   			header_up X-Forwarded-Proto https
   			header_up X-Forwarded-For {client_ip}
   			header_up -Accept-Encoding
   			flush_interval -1
   		}
   	}
   }
   ```
   Server chỉ đọc **hop cuối** của `X-Forwarded-For` (`server/request-auth.ts:241-248`). Vì vậy Caddy phải tự ghi đúng một giá trị, là IP thật của client (`{client_ip}`, lấy qua Traefik được tin). Nếu không, mọi người dùng chung một bộ đếm khóa pairing.
   - Đặt cứng `X-Forwarded-Proto https`, vì Traefik luôn kết thúc TLS. Cookie nhờ vậy có cờ Secure và kiểm tra cùng origin đúng.
   - Rủi ro đã chấp nhận: `private_ranges` tin cả các container khác trên `dokploy-network`. Chúng chỉ giả được IP trong bộ đếm khóa, không giả được quyền truy cập.
2. Viết `deploy/dokploy/docker-compose.yml`, chép từ `compose.yaml` ở gốc repo rồi sửa:
   - `build.context: ../local`, `BASE_IMAGE: ${OMB_BASE_IMAGE:?}`. Không có giá trị mặc định `latest`, để image luôn được ghim version.
   - Caddy: `image: caddy:2.10.2`, ghim version vì `client_ip_headers` cần bản 2.7 trở lên. Bỏ `ports:`. Volume trỏ tới `./Caddyfile`.
   - Volume `data`: `name: ${OMB_DATA_VOLUME:?}`, đặt trong env là `onhand-mausbot_data`. Không để tên rơi về mặc định chung `openmausbot_data` trên máy dùng chung.
   - `OMB_PUBLIC_URL` và `OMB_WEBHOOK_PUBLIC_URL` = `https://${DOMAIN:?}`. Đặt `OMB_SERVER_NAME=${DOMAIN}`.
   - Giới hạn tài nguyên của `omb` vì máy dùng chung: `mem_limit: 6g`, `cpus: 4`.
   - Giữ nguyên `init: true`, `shm_size: 512m`, healthcheck và volume `edge` kiểu tmpfs.
   - Không khai báo network. Dokploy tự gắn `dokploy-network` cho service có domain. Kiểm lại ở phase 5.
3. Thử ở máy local, với dữ liệu cô lập và một project compose riêng:
   - `docker compose -f deploy/dokploy/docker-compose.yml config` chạy không lỗi.
   - Chạy `up --build` với `OMB_BASE_IMAGE=ghcr.io/milind-soni/openmausbot:v0.1.153`. Kiểm tra trước rằng tag này tồn tại.
   - Tạm publish caddy ra `127.0.0.1:18080` bằng một file override (override không commit).
   - Gọi `curl -H 'X-Forwarded-Proto: https' -H 'Host: bot.onehand.space' http://127.0.0.1:18080/api/health`.
   - Xong thì `down -v` để dọn.
4. Commit `feat(deploy): add a Dokploy compose behind Traefik`, rồi push lên `origin/main`. Anh đã cho phép push repo này.

## Success Criteria
- [ ] `compose config` chạy không lỗi. Không service nào có `ports:`.
- [ ] Ở local, health trả về `openmausbot` và trang `/` không có session thì chuyển tới pair.
- [ ] CLI có trong image: `codex --version`, `claude --version` và `grok --version` đều chạy.

## Risk Assessment
- Tag `v0.1.153` không có trên ghcr. Cách xử lý: chọn release mới nhất đang có, rồi ghi version đã chọn vào plan.
- Dokploy không tự gắn `dokploy-network`. Cách xử lý: khai báo network external `dokploy-network` cho riêng caddy.
