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

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | Sao lưu cấu hình Rakazo: bỏ, anh xác nhận Rakazo chỉ là bản thử | Cancelled |
| 2 | [File compose Dokploy](./phase-02-file-compose-dokploy.md) | Pending |
| 3 | [Dựng MausBot song song](./phase-03-dung-mausbot-song-song.md) | Pending |
| 4 | [Đăng nhập CLI trên VPS](./phase-04-dang-nhap-cli-tren-vps.md) | Pending |
| 5 | [Chuyển domain và gỡ Rakazo](./phase-05-chuyen-doi-domain-va-tam-ngung-rakazo.md) | Pending |
| 6 | [Nối máy local làm computer](./phase-06-noi-may-local-lam-computer.md) | Pending |

Chạy tuần tự. Phase 2 không đụng production, làm được ngay. Bước không đảo ngược được là gỡ Rakazo ở phase 5 bước 9, và bước này đã được anh cho phép.

## Tiêu chí nghiệm thu

- [ ] `https://bot.onehand.space/api/health` trả về JSON chứa `openmausbot`.
- [ ] Anh ghép được trình duyệt và app desktop. Trang chưa đăng nhập chỉ hiện trang pair.
- [ ] Agent chính chạy `codex` / `gpt-6.1-sol` / `medium`, trả lời một lượt thử. Chạy được thêm một lượt ở mức `high`.
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

- `MAUS_ID`: (ghi ở phase 3)
- `MAUS_APP`: (ghi ở phase 3)
