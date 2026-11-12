---
phase: 2
title: "File compose Dokploy"
status: pending
priority: P1
dependencies: []
---

# Phase 2: File compose Dokploy

## Overview
Thêm 2 file vào repo: `deploy/dokploy/docker-compose.yml` và `deploy/dokploy/Caddyfile`. Thử chúng trên Docker local với dữ liệu riêng, rồi commit và push. Phase này **không đụng Dokploy**.

## Vì sao làm thế này
Phần này chỉ để hiểu, không phải làm.
- Traefik của Dokploy giữ cổng 80 và 443 cho mọi project, nên MausBot không được publish cổng nào.
- Server MausBot chỉ nghe trên loopback và 2 unix socket, gọi là "thiết kế upstream" (`server/lan-address.ts`). Traefik không vào được socket, nên cần Caddy làm cầu: Traefik → `caddy:80` → socket.
- Server chỉ đọc **hop cuối** của `X-Forwarded-For` (`server/request-auth.ts:241-248`). Vì vậy Caddy phải tự ghi đúng 1 giá trị là IP thật của client, lấy qua `client_ip_headers` từ Traefik được tin. Mẫu này chép từ `deploy/fly/Caddyfile` và `deploy/fly/edge-routes.caddy`, đã chạy ổn ở upstream.
- Traefik của Dokploy không đặt `forwardedHeaders.trustedIPs`, đã kiểm ngày 12/11. Traefik vì vậy bỏ `X-Forwarded-For` mà client tự gửi lên, và tự ghi IP thật vào.
- Image: `deploy/local/Dockerfile` lấy image dựng sẵn của upstream rồi cài thêm Claude Code, Codex và Grok, giữ `USER maus`. User `maus` có HOME là `/data` (`Dockerfile:88`). Đăng nhập CLI vì vậy nằm trong volume và không mất khi deploy lại. Fork chỉ hơn upstream 2 commit tài liệu, nên dùng image upstream là đúng code.
- Tag `ghcr.io/milind-soni/openmausbot:v0.1.153` có thật, đã kiểm ngày 12/11 (HTTP 200).
- Hai file dưới đây đã được kiểm trước ngày 12/11: `docker compose config` chạy không lỗi, và báo thiếu biến khi thiếu; `caddy validate` (caddy:2.10.2) trả "Valid configuration".

## Quy tắc
- Chỉ tạo 2 file trên. **Không sửa** `compose.yaml`, `deploy/docker-compose.yml`, `deploy/local/*` hay file nào khác.
- Không commit file `.env`, file override thử nghiệm hay bất kỳ secret nào.
- Theo `AGENTS.md`: không viết comment kể lịch sử, không viết comment lặp lại tên. Chỉ ghi comment cho điều bắt buộc từ bên ngoài, ví dụ yêu cầu của Traefik hay Dokploy.

## Bước 1: tạo `deploy/dokploy/Caddyfile`, đúng nội dung này

```
# Dokploy's Traefik ends TLS and reaches this Caddy over dokploy-network; Caddy reaches the
# server over the Unix sockets in the edge volume. The server reads the last X-Forwarded-For
# hop, so Caddy writes exactly one: the client address Traefik reported.
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

## Bước 2: tạo `deploy/dokploy/docker-compose.yml`, đúng nội dung này

```yaml
# OpenMausBot on a Dokploy host. Dokploy's Traefik owns 80/443 and routes the domain to caddy:80,
# so nothing here publishes a port. Dokploy writes .env next to this file from the compose's
# Environment tab: DOMAIN, OMB_BASE_IMAGE and OMB_DATA_VOLUME are required.
services:
  omb:
    init: true
    shm_size: 512m
    build:
      context: ../local
      args:
        BASE_IMAGE: ${OMB_BASE_IMAGE:?set OMB_BASE_IMAGE to a released image tag}
    image: onhand-mausbot-local:current
    restart: unless-stopped
    mem_limit: 6g
    cpus: 4
    volumes:
      - data:/data
      - edge:/run/openmausbot
    environment:
      OMB_PORT: "8799"
      OMB_WEBHOOK_PORT: "8800"
      OMB_TUNNEL_SOCKET: /run/openmausbot/http.sock
      OMB_WEBHOOK_SOCKET: /run/openmausbot/hooks.sock
      OMB_SERVER_NAME: ${DOMAIN:?set DOMAIN}
      OMB_PUBLIC_URL: https://${DOMAIN:?set DOMAIN}
      OMB_WEBHOOK_PUBLIC_URL: https://${DOMAIN:?set DOMAIN}
    healthcheck:
      test:
        - CMD
        - node
        - -e
        - "fetch('http://127.0.0.1:8799/api/health', { signal: AbortSignal.timeout(4000) }).then(async r => { if (!r.ok || !(await r.text()).includes('openmausbot')) process.exit(1); }).catch(() => process.exit(1))"
      interval: 15s
      timeout: 5s
      start_period: 30s
      retries: 5
  caddy:
    image: caddy:2.10.2
    restart: unless-stopped
    depends_on:
      omb:
        condition: service_started
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - edge:/run/openmausbot
      - caddy_data:/data
      - caddy_config:/config
volumes:
  data:
    name: ${OMB_DATA_VOLUME:?set OMB_DATA_VOLUME}
  edge:
    driver_opts:
      type: tmpfs
      device: tmpfs
      o: mode=1777,size=1m
  caddy_data:
  caddy_config:
```

Ghi chú (không đưa vào file):
- `ENGINES` không cần truyền vì `deploy/local/Dockerfile` đã mặc định cài `@anthropic-ai/claude-code @openai/codex`. Grok cũng được cài sẵn với `GROK_VERSION=1.0.41`.
- Không khai báo network. Khi có domain, Dokploy tự gắn `dokploy-network` cho service đó; Rakazo cũng chạy kiểu này (`onhandbot/infra/compose/docker-compose.dokploy.yml`). Phase 5 kiểm lại điều này.

## Bước 3: kiểm tra cú pháp

```bash
cd "/home/thanh-phong/CTP DESKTOP/OnHand Bot Plus/deploy/dokploy"
DOMAIN=bot.onehand.space OMB_BASE_IMAGE=ghcr.io/milind-soni/openmausbot:v0.1.153 OMB_DATA_VOLUME=x docker compose -f docker-compose.yml config >/dev/null && echo CONFIG_OK
docker compose -f docker-compose.yml config 2>&1 | grep -q "required variable" && echo MISSING_VAR_REFUSED
```

Kết quả phải in ra cả `CONFIG_OK` và `MISSING_VAR_REFUSED`.

## Bước 4: chạy thử trên Docker local, cô lập hoàn toàn

Dùng thư mục scratch của phiên làm `$T`, không dùng thư mục trong repo. Project tên `omb-dokploy-localtest` riêng, volume riêng. **Không đụng** server MausBot thật của anh ở cổng 8799.

```bash
T=<thư mục scratch của phiên>/dokploy-test && mkdir -p "$T"
printf 'DOMAIN=bot.onehand.space\nOMB_BASE_IMAGE=ghcr.io/milind-soni/openmausbot:v0.1.153\nOMB_DATA_VOLUME=omb-dokploy-localtest_data\n' > "$T/test.env"
printf 'services:\n  caddy:\n    ports:\n      - "127.0.0.1:18080:80"\n' > "$T/ports.yml"
cd "/home/thanh-phong/CTP DESKTOP/OnHand Bot Plus/deploy/dokploy"
C="docker compose -p omb-dokploy-localtest --env-file $T/test.env -f docker-compose.yml -f $T/ports.yml"
$C up -d --build
```

Lần đầu phải kéo image vài GB, nên chạy lệnh `up` ở chế độ nền và chờ tối đa 15 phút. Sau đó chờ `omb` lên healthy:

```bash
until [ "$($C ps --format '{{.Service}} {{.Health}}' | grep -c '^omb healthy')" = 1 ]; do sleep 10; done
```

Chạy 4 phép thử dưới đây. Ghi lại kết quả thật, không ghi "PASS" suông.

| # | Lệnh | Phải thấy |
|---|---|---|
| a | `curl -s -H 'Host: bot.onehand.space' http://127.0.0.1:18080/api/health` | `{"app":"openmausbot"}` |
| b | `curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: bot.onehand.space' http://127.0.0.1:18080/api/connectors` | `401` hoặc `403`: request đi qua proxy phải bị coi là remote và bị chặn |
| c | `curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: bot.onehand.space' http://127.0.0.1:18080/` | `200`: trang app tĩnh. Phần app tự hiện màn pair |
| d | `$C exec omb sh -c 'whoami; echo $HOME; codex --version; claude --version; grok --version; openmausbot --version'` | `maus`, `/data`, và 4 dòng version |

Dọn sau khi thử:

```bash
$C down -v && docker volume rm omb-dokploy-localtest_data 2>/dev/null; docker image rm onhand-mausbot-local:current 2>/dev/null; true
```

## Bước 5: commit và push

```bash
cd "/home/thanh-phong/CTP DESKTOP/OnHand Bot Plus"
git add deploy/dokploy/docker-compose.yml deploy/dokploy/Caddyfile
git -c user.name=phongchau120498-svg -c user.email=phongchau120498@gmail.com commit -m "feat(deploy): run behind Dokploy's Traefik

Co-Authored-By: <dòng attribution của model thực thi>"
git pull --rebase origin main && git push origin main
```

Anh đã cho phép push repo này. `git status` trước khi commit chỉ được có đúng 2 file này, cộng `.claude/launch.json` chưa track; không add file đó.

## Success Criteria
- [ ] Bước 3 in ra cả `CONFIG_OK` và `MISSING_VAR_REFUSED`.
- [ ] Bước 4 có đủ 4 phép thử a–d, kết quả đúng như bảng.
- [ ] Đã dọn: `docker ps -a` và `docker volume ls` không còn gì tên `omb-dokploy-localtest`.
- [ ] Commit đã lên `origin/main` và chỉ chứa 2 file.

## Khi gặp lỗi
- `up --build` lỗi ở bước cài Grok (mạng): thử lại 1 lần. Lỗi lần nữa thì dừng và báo anh; không tự bỏ Grok.
- Phép thử b trả `200`: **dừng**, không push. Lỗi này nghĩa là proxy làm server tưởng request là local, tức lộ quyền chủ. Báo anh kèm header và log.
- Phép thử a lỗi `502`: xem `$C logs caddy omb`. Nguyên nhân thường là socket chưa tạo xong; chờ healthy rồi thử lại.
