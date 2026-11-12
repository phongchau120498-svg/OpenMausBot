---
phase: 4
title: "Đăng nhập CLI trên VPS"
status: pending
priority: P1
dependencies: [3]
---

# Phase 4: Đăng nhập CLI trên VPS

## Overview
Anh đăng nhập Codex (engine chính), Claude Code (dự phòng) và Grok (tùy chọn) bên trong container `omb`. Agent thực thi **chỉ hướng dẫn và kiểm tra kết quả**.

## Quy tắc
- **Agent không được tự đăng nhập.** Agent không nhập mật khẩu, không dán mã thiết bị, không mở link đăng nhập thay anh. Agent chỉ đưa lệnh cho anh và đọc kết quả anh gửi lại.
- Agent không có SSH và không có `docker exec` tới máy Dokploy. Mọi lệnh trong container do anh chạy ở **Dokploy → project onhand-bot → mausbot → Docker → `<MAUS_APP>-omb-1` → Terminal**.
- Không chép file đăng nhập ra ngoài, không đưa nội dung đó vào chat hay log. Anh có thể gửi lại kết quả lệnh, trừ phần mã hoặc link đăng nhập.
- HOME của user `maus` là `/data`, nằm trên volume (`Dockerfile:88`). Đăng nhập vì vậy còn nguyên qua restart và redeploy.

## Các bước (agent gửi anh lần lượt, từng bước một, chờ anh trả kết quả)

### 1. Mở terminal và kiểm tra
```bash
whoami; echo $HOME; codex --version; claude --version; grok --version
```
Phải thấy `maus` và `/data`. Nếu `whoami` ra `root`, chạy `su -s /bin/bash maus` rồi chạy lại lệnh trên. Nếu HOME không phải `/data`, **dừng**: đăng nhập sẽ mất khi deploy lại. Báo anh.

### 2. Codex (engine chính, gói ChatGPT)
```bash
codex login --device-auth
```
Lệnh in ra một link và một mã. Anh mở link trên máy mình, nhập mã, chọn tài khoản ChatGPT. Sau đó kiểm tra:
```bash
codex login status
```
Phải thấy dòng báo đã đăng nhập bằng ChatGPT.

### 3. Claude Code (dự phòng, gói Claude)
```bash
claude
```
Trong giao diện, gõ `/login` và chọn gói Claude. Mở link, dán mã trả về, rồi gõ `/exit`. Kiểm tra:
```bash
claude -p "Trả lời đúng một chữ: ok"
```

### 4. Grok (tùy chọn, anh quyết)
Có 2 cách:
- Chạy `grok` trong terminal và làm theo hướng dẫn.
- Hoặc để sau phase 5, đăng nhập bằng mã thiết bị trong app ở Settings → Engines.

### 5. Kiểm tra từ server
```bash
openmausbot status
```
CLI không có lệnh `doctor`. Ghi lại kết quả. Sau phase 5, xem thêm ở Settings → Engines trên giao diện.

### 6. Kiểm tra đăng nhập còn sau restart
1. Agent gọi `docker-restartContainer {containerId: <id của omb>}`. Đây là tool ghi, nhưng chỉ đụng container của `mausbot`.
2. Chờ container healthy trở lại.
3. Anh mở terminal mới và chạy `codex login status`. Kết quả vẫn phải báo đã đăng nhập.

## Success Criteria
- [ ] `codex login status` báo đã đăng nhập, cả trước và sau khi restart.
- [ ] `claude -p` trả lời được.
- [ ] Grok: đã đăng nhập, hoặc anh chọn để sau. Ghi rõ là trường hợp nào.

## Khi gặp lỗi
- `codex login --device-auth` báo không có cờ này: chạy `codex login --help`, rồi báo anh cách đăng nhập không cần trình duyệt mà bản này hỗ trợ.
- Terminal Dokploy không mở được: anh dùng nút "Open terminal" trong trang Docker của Dokploy. Không có cách nào khác vì không có SSH.
