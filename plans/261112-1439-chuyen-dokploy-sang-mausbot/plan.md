---
title: "Chuyển bot từ onhandbot sang MausBot trên Dokploy"
description: "Chạy fork OpenMausBot này trên Dokploy tại bot.onehand.space thay Rakazo, đăng nhập CLI trong container, máy local làm computer cho việc nặng"
status: pending
priority: P1
branch: "main"
tags: [deploy, dokploy, migration]
blockedBy: []
blocks: []
created: "2026-11-12T07:42:04.259Z"
createdBy: "ck:plan"
source: skill
---

# Chuyển bot từ onhandbot sang MausBot trên Dokploy

## Overview

Thay Rakazo (onhandbot) bằng MausBot (fork này) trên cùng Dokploy, cùng domain `bot.onehand.space`. Agent chính chạy Codex GPT 6.1 Sol: mức medium cho việc nhẹ, high cho việc nặng. Việc nặng làm trên máy local qua "Share this computer". Lý do chọn MausBot: xem [báo cáo so sánh](../reports/bot-benchmark-261111-1738-plus-vs-onhandbot-report.md).

Anh đã cho phép tạm ngưng Rakazo mà không cần hỏi lại. Tạm ngưng nghĩa là dừng container và tắt domain. **Không xóa** dữ liệu, volume hay project Rakazo.

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

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Sao lưu cấu hình Rakazo](./phase-01-sao-luu-cau-hinh-rakazo.md) | Pending |
| 2 | [File compose Dokploy](./phase-02-file-compose-dokploy.md) | Pending |
| 3 | [Dựng MausBot song song](./phase-03-dung-mausbot-song-song.md) | Pending |
| 4 | [Đăng nhập CLI trên VPS](./phase-04-dang-nhap-cli-tren-vps.md) | Pending |
| 5 | [Chuyển domain và tạm ngưng Rakazo](./phase-05-chuyen-doi-domain-va-tam-ngung-rakazo.md) | Pending |
| 6 | [Nối máy local làm computer](./phase-06-noi-may-local-lam-computer.md) | Pending |

Chạy tuần tự. Phase 1 và 2 không đụng production, làm được ngay. Bước khó đảo ngược duy nhất nằm ở phase 5, và phase 5 có cách quay lại.

## Tiêu chí nghiệm thu

- [ ] `https://bot.onehand.space/api/health` trả về JSON chứa `openmausbot`.
- [ ] Anh ghép được trình duyệt và app desktop. Trang chưa đăng nhập chỉ hiện trang pair.
- [ ] Agent chính chạy `codex` / `gpt-6.1-sol` / `medium`, trả lời một lượt thử. Chạy được thêm một lượt ở mức `high`.
- [ ] Đăng nhập CLI nằm trong volume `/data`: restart hay redeploy container không mất đăng nhập.
- [ ] Container Rakazo đã dừng, 4 domain đã tắt, `autoDeploy` đã tắt. Volume và project còn nguyên.
- [ ] Không project Dokploy nào khác bị đổi: so `project.all` trước và sau.
- [ ] Máy local hiện "Connected" trong Settings → Servers. Bot chạy được một lệnh trên máy local sau khi anh bấm Allow.
- [ ] Có bản xuất cấu hình 5 bot Rakazo nằm ngoài git.

## Cách quay lại (rollback)

Tắt domain của MausBot, rồi bật lại 4 domain Rakazo, chạy `compose.start` Rakazo và bật lại `autoDeploy`. Volume Rakazo không bị đụng nên dữ liệu còn nguyên. Chi tiết ở phase 5.

## Đã phản biện (red team 12/11)

Đã sửa theo phản biện:
- Caddy ghi `X-Forwarded-For {client_ip}` theo mẫu `deploy/fly`, và ghim `caddy:2.10.2`.
- Bỏ lệnh `doctor` vì không tồn tại.
- Đặt cứng tên volume `onhand-mausbot_data`.
- Giới hạn `omb` ở 6 GB RAM và 4 CPU.
- Thêm backup volume hằng ngày.
- Kiểm tra trước API `domain.toggleEnable`.
- Phase 6 cần phiên Xorg, vì Wayland chặn điều khiển máy local.

Đã xác nhận đúng:
- HOME=/data với user `maus`, nên đăng nhập CLI còn sau restart.
- `openmausbot` có trên PATH.
- Tính năng cho mượn máy bật sẵn cho người ghép với quyền chủ, không cần cờ.

## Câu hỏi còn mở

1. Có làm subdomain thử `maus.onehand.space` (anh thêm bản ghi A → 51.79.254.165) để thử MausBot qua web trước khi chuyển hẳn không? Mặc định là **không**: chuyển thẳng domain vì anh đã cho tạm ngưng Rakazo. Trước đó MausBot chỉ được kiểm tra bên trong container.
2. Máy local có chuyển sang phiên Xorg không? Chỉ khi đó bot mới dùng được trình duyệt local. Ở lại Wayland thì bot chỉ dùng được thư mục và terminal.
3. Có cần chép 5 bot Rakazo sang MausBot ngay không? Mặc định chỉ tạo agent chính. Hướng dẫn của 5 bot được giữ trong bản xuất để anh chép sau.
