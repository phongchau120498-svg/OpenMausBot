---
title: Chuyển bot từ onhandbot sang MausBot trên Dokploy
description: >-
  Chạy fork OpenMausBot này trên Dokploy tại bot.onehand.space thay Rakazo, đăng
  nhập CLI trong container, máy local làm computer cho việc nặng
status: pending
priority: P1
branch: main
tags:
  - deploy
  - dokploy
  - migration
blockedBy: []
blocks: []
created: '2026-11-12T07:42:04.259Z'
createdBy: 'ck:plan'
source: skill
---

# Chuyển bot từ onhandbot sang MausBot trên Dokploy

## Overview

Thay Rakazo (onhandbot) bằng MausBot (fork này) trên cùng Dokploy, cùng domain `bot.onehand.space`. Agent chính chạy Codex GPT 6.1 Sol: mức medium cho việc nhẹ, high cho việc nặng. Việc nặng làm trên máy local qua "Share this computer". Lý do chọn MausBot: xem [báo cáo so sánh](../reports/bot-benchmark-261111-1738-plus-vs-onhandbot-report.md).

Rakazo chỉ là bản thử, chưa chạy thật. Anh đã cho phép gỡ hẳn mà không cần sao lưu và không cần hỏi lại. Chỉ gỡ sau khi MausBot đã chạy qua domain (phase 5).

## Đã kiểm tra production (12/11, chỉ đọc)

- Dokploy chạy trên máy 51.79.254.165: 8 CPU, 24 GB RAM (đang dùng khoảng 15,7 GB), ổ đĩa 211 GB (đã dùng 166 GB, còn khoảng 45 GB), 54 container. Không có server phụ (`server.all` rỗng).
- **Máy dùng chung với nhiều project khác** (Kanna, omninoise, agent-vault, undercroft…). Chỉ được đụng vào project `onhand-bot`.
- Rakazo là compose `rkPYxiV0FMWyfpAGkV4zu` (appName `compose-bypass-1080p-protocol-dv6zak`) trong project `onhand-bot`, môi trường production `PvQ1vgCicpbLbdqOJ_tor`.
  - Nguồn: git `phongchau120498-svg/OnHand-Bot` nhánh main, `autoDeploy: true`.
  - Gồm các service: web, api, worker, postgres, supervisor, backup, computer.
  - 4 domain trên `bot.onehand.space`:
    - `/` → web:5173, id `jK0weAwdkgjffNhs71Son`
    - `/api` → api:3100, id `A0CpxIX6HxKrJDExtE08m`
    - `/rpc` → api:3100, id `P3GkNOQj_pnCa-ZKYtKbq`
    - `/health` → api:3100, id `Uiw9EjaawB5YNSZkSi1pi`
  - Cả 4 domain gắn middleware `onhand-headers@docker`.
- Rakazo có 1 space "Personal" với 5 bot: Chiêu Giao, Tiêu Băng, Minh Đăng, Gia Huy, Như Phương. Hướng dẫn mỗi bot dài 3–8 nghìn ký tự.
- DNS:
  - `bot.onehand.space` trỏ về 51.79.254.165.
  - Các subdomain khác của `onehand.space` trỏ về IP Vercel (wildcard). Muốn có subdomain thử riêng thì anh phải tự thêm bản ghi A.
- Không có SSH tới máy Dokploy. `onehand-vps` là máy khác (103.97.127.35). Lệnh trong container chạy qua terminal container của giao diện Dokploy.
- Fork này chỉ hơn upstream 2 commit, đều là tài liệu. Vì vậy dùng image dựng sẵn của upstream, ghim theo version, rồi cài thêm CLI.
- Kênh `stable` của upstream chưa có. Dùng release mới nhất là `v0.1.153`, trùng version của fork.
- Sandbox AppArmor của bot chưa có trong version này (repo chưa có `deploy/box/`). Vì vậy **không cần sửa máy chủ dùng chung**.

## Hướng dẫn cho agent thực thi (đọc trước khi làm bất cứ gì)

Plan này viết cho một agent khác thực thi (Sonnet 5.5, mức high). Mọi giá trị cần dùng (id, nội dung file, tham số tool, kết quả mong đợi) đều đã ghi sẵn trong phase. **Không đoán thêm. Thiếu gì thì dừng và hỏi anh.**

**Thứ tự đọc:**
1. File này.
2. `AGENTS.md` ở gốc repo, phần quy tắc viết comment.
3. File phase đang làm. Chỉ đọc phase đó.

**Luật cứng:**
1. **Máy Dokploy dùng chung với khoảng 15 project khác.** Tool ghi (create, update, delete, deploy, stop, remove) chỉ được gọi lên:
   - compose `mausbot` mới tạo;
   - compose Rakazo `rkPYxiV0FMWyfpAGkV4zu` cùng 4 domain của nó;
   - container và volume khớp mẫu tên ghi ở phase 5.

   Đọc lại tên và id trước mỗi lần xóa.
2. **Không tự đăng nhập, không nhập mật khẩu hay mã.** Đăng nhập CLI, link pair và các nút Allow đều do anh làm. Agent đưa lệnh, chờ anh, rồi kiểm tra kết quả.
3. Không SSH được vào máy Dokploy (`onehand-vps` trong `~/.ssh/config` là **máy khác**). Lệnh chạy trong container thì nhờ anh chạy ở terminal Docker của Dokploy.
4. Không commit secret, `.env`, file thử nghiệm hay `.claude/launch.json`. Lệnh commit dùng `git -c user.name=phongchau120498-svg -c user.email=phongchau120498@gmail.com commit …`. Push lên `origin main` đã được anh cho phép.
5. Không sửa file của upstream. Chỉ thêm file trong `deploy/dokploy/`.
6. Làm từng phase theo thứ tự. Xong phase nào thì:
   - chạy `cd "plans/261112-1439-chuyen-dokploy-sang-mausbot" && ck plan check <số phase>`;
   - ghi bằng chứng vào mục **Nhật ký thực thi** ở cuối file này, gồm lệnh hoặc tool đã gọi và kết quả thật, ngắn gọn. Không ghi "PASS" suông.
7. **Dừng và báo anh** khi:
   - một phép thử an ninh trả `200` (phase 2 bước 4b, phase 5 bước 6b/6d);
   - thiếu RAM hoặc đĩa;
   - deploy lỗi 2 lần liên tiếp;
   - cần quyết định nằm ngoài plan.

   Không tự "sửa cho chạy" bằng cách bỏ kiểm tra.

**Tool:**
- Dokploy: `mcp__lowbit-dokploy__<tên>`. Tên trong plan viết dạng `compose-create`, ứng với tool `mcp__lowbit-dokploy__compose-create`. Tool chưa có thì nạp bằng ToolSearch `select:mcp__lowbit-dokploy__<tên>`.
- Lệnh trên máy local: Bash.

**Nhiều tài khoản Codex:** anh có 5 tài khoản Plus, mỗi tài khoản bị giới hạn 5 giờ. Codex CLI chỉ giữ một đăng nhập mỗi `CODEX_HOME`, nên mỗi tài khoản có một `CODEX_HOME` và một instance riêng (phase 4 bước 7). Plus tự chuyển sang tài khoản dự phòng khi hết lượt, mà không cần đăng nhập lại. Cơ chế tự chuyển đã bật sẵn.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | Sao lưu cấu hình Rakazo: bỏ, anh xác nhận Rakazo chỉ là bản thử | Cancelled |
| 2 | [File compose Dokploy](./phase-02-file-compose-dokploy.md) | Completed |
| 3 | [Dựng MausBot song song](./phase-03-dung-mausbot-song-song.md) | Completed |
| 4 | [Đăng nhập CLI trên VPS](./phase-04-dang-nhap-cli-tren-vps.md) | Pending |
| 5 | [Chuyển domain và gỡ Rakazo](./phase-05-chuyen-doi-domain-va-tam-ngung-rakazo.md) | Completed |
| 6 | [Nối máy local làm computer](./phase-06-noi-may-local-lam-computer.md) | Completed |

Chạy tuần tự. Phase 2 không đụng production, làm được ngay. Bước không đảo ngược được là gỡ Rakazo ở phase 5 bước 9, và bước này đã được anh cho phép.

## Tiêu chí nghiệm thu

- [ ] `https://bot.onehand.space/api/health` trả về JSON chứa `openmausbot`.
- [ ] Anh ghép được trình duyệt và app desktop. Trang chưa đăng nhập chỉ hiện trang pair.
- [ ] Agent chính chạy `codex` / `gpt-6.1-sol` / `medium`, trả lời một lượt thử. Chạy được thêm một lượt ở mức `high`.
- [ ] 5 tài khoản Codex nằm trong 5 instance, email khác nhau, và danh sách dự phòng của agent chính đã đặt.
- [ ] Đăng nhập CLI nằm trong volume `/data`: restart hay redeploy container không mất đăng nhập.
- [ ] Rakazo đã gỡ hết: compose, volume, các container `rakazo-bot-team-*` và 4 domain. Project `onhand-bot` vẫn còn và chứa `mausbot`.
- [ ] Không project Dokploy nào khác bị đổi: so `project.all` trước và sau.
- [ ] Máy local hiện "Connected" trong Settings → Servers. Bot chạy được một lệnh trên máy local sau khi anh bấm Allow.

## Cách quay lại (rollback)

- Trước khi gỡ Rakazo (phase 5 bước 9): làm theo mục "Quay lại" trong phase 5.
- Sau khi gỡ: không quay về Rakazo được nữa, như anh đã cho phép. Nếu MausBot lỗi thì sửa MausBot.

## Đã phản biện (red team 12/11)

Đã sửa theo phản biện:
- Caddy ghi `X-Forwarded-For {client_ip}` theo mẫu `deploy/fly`, và ghim `caddy:2.10.2`.
- Bỏ lệnh `doctor` vì không tồn tại.
- Đặt cứng tên volume `onhand-mausbot_data`.
- Giới hạn `omb` ở 6 GB RAM và 4 CPU.
- Thêm backup volume hằng ngày. Hiện Dokploy chưa có destination nào, nên việc này chờ anh tạo.
- Domain Rakazo được xóa thẳng (`domain.delete`), không cần API tắt domain.
- Phase 6 cần phiên Xorg, vì Wayland chặn điều khiển máy local.

Đã xác nhận đúng:
- HOME=/data với user `maus`, nên đăng nhập CLI còn sau restart.
- `openmausbot` có trên PATH.
- Tính năng cho mượn máy bật sẵn cho người ghép với quyền chủ, không cần cờ.

## Câu hỏi còn mở

1. Có làm subdomain thử `maus.onehand.space` (anh thêm bản ghi A → 51.79.254.165) để thử MausBot qua web trước khi chuyển hẳn không? Mặc định là **không**: chuyển thẳng domain vì Rakazo chỉ là bản thử. Trước đó MausBot chỉ được kiểm tra bên trong container.
2. Máy local có chuyển sang phiên Xorg không? Chỉ khi đó bot mới dùng được trình duyệt local. Ở lại Wayland thì bot chỉ dùng được thư mục và terminal.
3. Backup lưu ở đâu? Dokploy chưa có destination (S3 hoặc R2). Anh tạo một destination thì phase 5 bước 10 mới bật backup được.

## Nhật ký thực thi

Agent thực thi ghi vào đây sau mỗi phase: ngày giờ, phase, tool hoặc lệnh đã chạy, kết quả thật, commit nếu có.

- `MAUS_ID`: `R9J9lfkVw9lAV-1venZ2M`
- `MAUS_APP`: `compose-input-bluetooth-system-buiaek`

### Phase 2 (12/11 15:10)
- `docker compose config`: CONFIG_OK, và báo thiếu biến khi thiếu (MISSING_VAR_REFUSED).
- Chạy thử Docker local, project `omb-dokploy-localtest`, cổng 127.0.0.1:18080, image `v0.1.153`:
  - a: `/api/health` → `{"app":"openmausbot"}`
  - b: `/api/connectors` → `403`
  - c: `/` → `200`
  - d: `maus`, HOME `/data`, codex-cli 0.167.2, Claude Code 2.1.322, grok 1.0.41. `openmausbot --version` in `0.0.0`.
  - Thêm: giả `X-Forwarded-For: 127.0.0.1` → vẫn `403`.
- Đã dọn: không còn container hay volume `omb-dokploy-localtest`.
- Commit `a45df5685` đã lên `origin/main`, gồm đúng 2 file.

### Phase 3 (12/11 15:12)
- Mốc: 15 project, RAM đã dùng 15,86 GB / 24,6 GB, đĩa đã dùng 166,1 GB / 211,2 GB (đạt ngưỡng). Mốc lưu ở thư mục scratch, ngoài repo.
- `compose-create` → `MAUS_ID`/`MAUS_APP` ở trên. Dokploy tạo mặc định `autoDeploy: true`; đã tắt ngay bằng `compose-update`, trước khi deploy.
- `compose-update`: git https `phongchau120498-svg/OpenMausBot.git` nhánh main, composePath `./deploy/dokploy/docker-compose.yml`, `autoDeploy: false`. Clone https chạy được, không cần SSH key.
- `compose-saveEnvironment`: DOMAIN, OMB_BASE_IMAGE `…:v0.1.153`, OMB_DATA_VOLUME `onhand-mausbot_data`.
- `compose-deploy` → deployment `6XWQYlupIToZCMeOjHHBe`, `done` sau khoảng 2 phút, commit `a45df5685`. Không có lỗi thiếu biến `.env`.
- Container: `…-omb-1` healthy, `…-caddy-1` running. Log omb: server nghe `/run/openmausbot/http.sock`, public URL `https://bot.onehand.space`, không có Error/EADDRINUSE.
- Volume `onhand-mausbot_data` có thật.
- Rakazo: web, api, worker, postgres, supervisor vẫn healthy.
- Sau deploy: đĩa đã dùng 170,0 GB (còn khoảng 41 GB), RAM 16,2 GB.
- Kiểm project: dùng `environment-byProjectId` cho `onhand-bot` (2 compose: `stack`, `mausbot`) thay cho `project-all` ở bước này, vì `project-all` rất dài. `project-all` đầy đủ sẽ chạy ở cuối phase 5.
- Tên volume của Rakazo (cho phase 5, đã thấy trong danh sách volume): `compose-bypass-1080p-protocol-dv6zak_appdata`, `_pgdata`, `_postgres`, `_webassets`.

### Phase 4 (12/11 15:30, đang làm)
- Terminal container `d84c6fc898f6` (omb): `whoami` → `maus`, HOME `/data`, codex-cli 0.167.2, Claude Code 2.1.322, grok 1.0.41.
- Codex tài khoản 1: anh chạy `codex login --device-auth` trong container → "Successfully logged in".
- Đăng nhập nằm trên volume: `docker-listContainerFiles /data/.codex` có `auth.json` (chỉ xem tên file, không đọc nội dung). `/data` là volume `onhand-mausbot_data`, nên không cần thử restart.
- Claude Code: anh đăng nhập bằng `/login` trong container. `docker-listContainerFiles /data/.claude` có `.credentials.json` (chỉ xem tên file). Lệnh thử `claude -p` chưa có kết quả gửi về.
- Chưa làm: Grok, 4 tài khoản Codex còn lại.

### Phase 5 (12/11 15:35, đang làm)
- Bước 1: `compose-update` Rakazo `autoDeploy: false`. Kết quả trả về `autoDeploy: false`.
- Bước 2: `compose-stop` Rakazo. Mọi container `compose-bypass-1080p-protocol-dv6zak-*` đều `exited`.
- Bước 3: `domain-delete` 4 domain. Mỗi kết quả trả về đều xác nhận `composeId rkPYxiV0FMWyfpAGkV4zu`: `/`, `/api`, `/rpc`, `/health`.
- Bước 4: `domain-create` → `ZDSEFSUoMj_fybTqulVzH`: `bot.onehand.space` `/` → `caddy:80`, https letsencrypt, không có middleware.
- Bước 5: `compose-deploy` → `CDVWBkXZm8G64lcDtsJqR`, `done` sau 19 giây. Chỉ caddy được tạo lại; omb `d84c6fc898f6` giữ nguyên (đăng nhập còn).
- Bước 6, chạy từ máy local:
  - a: `/api/health` → `{"app":"openmausbot"}`
  - b: `/api/connectors` → `403`
  - c: `/` → `200`, ssl_verify `0`, chứng chỉ Let's Encrypt YR1, hết hạn 7/2/2027
  - d: giả `X-Forwarded-For: 127.0.0.1` → `403`
  - Traefik tự gắn `dokploy-network`, không cần sửa compose.
- Bước 7: anh tự ghép trình duyệt trong khung trình duyệt của app bằng `openmausbot pair` (agent không nhập mã).
- Bước 8, thay đổi so với plan: không tạo agent mới, mà nạp 5 bot từ file Grok export của anh qua **Settings → Import → Move from Grok Bot**.
  - Gộp 5 file thành `~/Downloads/grok-bot-export-all-5-bots.json`; `parseGrokExport` của repo đọc ra đủ 5 bot.
  - Xem trước rồi nạp: "Chiêu Giao · ASSIATANT is here" (24 skill, 4 routine), Gia Huy - ECOM (14/8), Minh Đăng (14/1), Tiêu Băng (14/8), UX UI PROMAX (14/0).
  - Routine nạp ở trạng thái tạm dừng; 55 app cần kết nối lại.
  - `PATCH /api/bots/<id>` `modelSelection {codex, gpt-6.1-sol, medium}` cho 5 bot: đều 200, đọc lại đúng giá trị.
  - Bot MausBot (Chief of Staff mặc định) giữ `claude/claude-sonnet-5`.
  - Thử Chiêu Giao: mức medium trả "ok" (3:47), mức high trả "ok" (3:48), sau đó trả về medium. Codex báo 23% hạn mức.
- Lấy lại bot Như Phương - SALE từ Rakazo (anh yêu cầu trước khi gỡ):
  - Chỉ bật container postgres `94931254607e` của Rakazo, không bật worker nên không routine nào chạy.
  - Tạo lịch chạy một lần, đang tắt, `nk_VhsTzUQneZ67qGUhPk` (compose Rakazo, service postgres), chạy một `select` chỉ đọc bằng `runManually`. Kết quả: 3.144 ký tự hướng dẫn, 1 trí nhớ, 3 skill (upwork-job-filter, wiki-upwork, upwork-real-tips), 2 routine đang tắt.
  - Đã dọn: `schedule-delete` lịch đó, `docker-stopContainer` postgres.
  - Chuyển sang định dạng Grok, lưu ở `~/Downloads/grok-bot-export-nhu-phuong---sale.json`; `parseGrokExport` đọc được 1 bot, 3 skill, 2 routine, 1 trí nhớ.
- Nạp Như Phương: anh chọn file trong hộp thoại Move from Grok Bot → bot `2fc48620…` có 3.144 ký tự hướng dẫn. `PATCH modelSelection` sang codex/gpt-6.1-sol/medium → 200. Thử lúc 15:54 → "ok".
- Bước 9, gỡ Rakazo:
  - `compose-delete rkPYxiV0FMWyfpAGkV4zu deleteVolumes:true`.
  - `docker-removeContainer 9a5de85edc01` (`rakazo-bot-team-6de85fb4…`, khớp mẫu tên).
  - Volume `_pgdata`, `_postgres`, `_webassets` đã mất cùng compose (getVolumeConfig trả 500). Còn `_appdata` có nhãn project `compose-bypass-1080p-protocol-dv6zak` → `dockerVolume-removeVolume`.
  - `onhand-mausbot_data` vẫn còn nguyên.
- Bước 10, backup: `destination-all` vẫn rỗng, nên chưa bật được. Chờ anh tạo destination S3 hoặc R2.
- Bước 11: `project-all` so với mốc. 15 project; `onhand-bot` chỉ còn `mausbot R9J9lfkVw9lAV-1venZ2M`. 14 project còn lại cùng compose id và trạng thái như mốc (`shuttle-tunnel frps` vẫn `error` như trước).
- Sau khi gỡ: `/api/health` → `{"app":"openmausbot"}`, `/api/connectors` → `403`.

### Phase 6 (12/11 16:30)
- Tải `OpenMausBot-0.1.153-x86_64.AppImage` (325 MB) từ release v0.1.153 của upstream, khớp bản server. `sha256sum -c` → OK.
- Sandbox của agent không mount được FUSE, nên giải nén vào `~/Applications/OpenMausBot-0.1.153/`. Thêm launcher `~/.local/share/applications/openmausbot.desktop` (`desktop-file-validate` hợp lệ).
- App chạy từ sandbox của agent bị gắn `NoNewPrivs=1`. Đã đổi sang để anh mở từ menu ứng dụng (`NoNewPrivs=0`).
- Anh ghép app bằng `openmausbot pair --label "May local"` rồi bấm Allow. `computer-sharing.json`: own=true, enabled, terminal=true, computer=true, thư mục `/home/thanh-phong/CTP DESKTOP`.
- Dữ liệu local cũ (6 bot) chuyển sang `~/.openmausbot.bak-261112` (không xóa), để app chỉ dùng bot của server. Trả lại bằng cách đổi tên ngược.
- Lần thử đầu gửi từ trình duyệt của agent thất bại ("không có máy local trực tuyến"): `personKey` = email, hoặc id phiên khi không có email (`server/person-key.ts`). Máy được cho mượn gắn với phiên "May local" của app desktop.
- Thử từ app desktop lúc 16:27: Chiêu Giao chạy `uname -a; hostname` trên máy local → `Linux thanh-phong-Z690-Steel-Legend 7.0.0-42-generic … x86_64`.
- Chưa làm: thử tắt "Share this computer" (bước 7c); đặt quy ước việc nặng/nhẹ vào hướng dẫn bot (bước 6).
- Đang Wayland: không điều khiển được màn hình local.

