---
phase: 4
title: "Đăng nhập CLI trên VPS"
status: pending
priority: P1
dependencies: [3]
---

# Phase 4: Đăng nhập CLI trên VPS

## Overview
Đăng nhập Codex (chính), Claude Code (dự phòng) và Grok (tùy chọn) **bên trong container `omb`**. Thông tin đăng nhập nằm trong volume `/data` nên còn nguyên qua restart.

## Requirements
- **Anh tự đăng nhập.** Claude chỉ hướng dẫn và kiểm tra kết quả, không nhập mật khẩu hay mã.
- Chạy với user `maus` của image, không chạy bằng root. Nếu chạy bằng root, thông tin đăng nhập sẽ nằm ở home khác (`docs/deploy-vps.md`).
- Không chép file đăng nhập ra ngoài container, không đưa vào git hay vào log.

## Implementation Steps
Mở Dokploy → project `onhand-bot` → `mausbot` → **Docker** → container `…-omb-1` → **Terminal** (shell `bash`, user mặc định của image).

1. Kiểm tra môi trường:
   ```bash
   whoami && echo "$HOME" && codex --version && claude --version && grok --version
   ```
   Kết quả phải là user `maus` và home nằm dưới `/data`. Nếu home không nằm dưới `/data`, dừng lại. Khi đó đăng nhập sẽ mất lúc redeploy, cần sửa compose.
2. **Codex** (agent chính, dùng gói ChatGPT):
   ```bash
   codex login --device-auth
   ```
   Anh mở link được in ra trên máy mình, nhập mã, rồi chọn tài khoản ChatGPT. Kiểm tra bằng `codex login status`.
3. **Claude Code** (dự phòng, dùng gói Claude):
   ```bash
   claude
   ```
   Trong giao diện, gõ `/login`, chọn gói Claude, mở link, dán mã, rồi `/exit`. Kiểm tra bằng `claude -p "ok"`. Lệnh này trả về một câu.
4. **Grok** (tùy chọn, thay Grok bot cũ): đăng nhập bằng mã thiết bị từ trong app (Settings → Engines). Hoặc chạy `grok` trong terminal và làm theo hướng dẫn.
5. Kiểm tra từ phía server:
   ```bash
   openmausbot status
   ```
   CLI không có lệnh `doctor`. Sau phase 5, xem thêm trong UI ở Settings → Engines.
6. Restart container `omb` trong Dokploy, rồi chạy lại `codex login status`. Vẫn phải báo đã đăng nhập.

## Success Criteria
- [ ] `codex login status` báo đã đăng nhập, kể cả sau restart.
- [ ] `claude -p "ok"` trả lời được. Grok tùy anh.
- [ ] Không có file đăng nhập nào nằm ngoài volume `/data`.

## Risk Assessment
- Image chạy bằng user `maus` với HOME=/data (`Dockerfile:15,159`). Nếu terminal vẫn mở bằng root, chạy `su -s /bin/bash maus`.
- Dùng một tài khoản ChatGPT cho nhiều nơi cùng lúc có thể chạm giới hạn lượt. Theo dõi trong tuần đầu.
