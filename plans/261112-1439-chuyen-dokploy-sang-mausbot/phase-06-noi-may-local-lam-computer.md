---
phase: 6
title: "Nối máy local làm computer"
status: pending
priority: P2
dependencies: [5]
---

# Phase 6: Nối máy local làm computer

## Overview
Ghép app MausBot trên máy local của anh với server. Sau đó bật "Let <server> use this computer" để việc nặng chạy bằng trình duyệt đã đăng nhập sẵn và IP nhà (`docs/self-hosting.md`, "Let your server use this computer").

## Requirements
- Ghép bằng mã quyền đầy đủ, tức là quyền chủ server. Mã `--phone` không cho mượn máy.
- Chỉ cấp những gì cần: thư mục làm việc (mặc định chỉ đọc), terminal và điều khiển màn hình. Mỗi quyền bật riêng và anh tự xác nhận trong hộp thoại hệ thống.
- App local phải đang mở thì bot mới dùng được máy.

## Điều kiện bắt buộc: phiên Xorg
Máy local hiện chạy GNOME **Wayland**. Trên Wayland, quyền điều khiển máy local bị tắt cứng (`docs/linux-desktop.md:18-23`). Vì vậy bot không mở được trình duyệt local.
- Muốn bot dùng trình duyệt hoặc màn hình local: đăng xuất, chọn **Ubuntu on Xorg** ở màn hình đăng nhập, rồi bật **Enable local control**.
- Ở lại Wayland thì bot chỉ dùng được thư mục và terminal. Tiêu chí "mở trang Shopee bằng trình duyệt local" khi đó bị loại.

## Implementation Steps
0. Kiểm tra `echo $XDG_SESSION_TYPE` trả `x11`. Nếu không, theo mục trên.
1. Cài hoặc cập nhật app desktop Linux đúng version với server (`docs/linux-desktop.md`).
2. Trong terminal container, chạy `openmausbot pair --label "May local"`. Trong app local, chọn **Server → Add Server from Copied Pairing Link…**, hoặc **＋ → Connect to a server**.
3. Khi app hỏi "Let bot.onehand.space use this computer?", chọn **Allow**.
4. Trong **Settings → Servers → Choose what it can use**, chọn thư mục làm việc. Bật terminal nếu cần. Bật điều khiển màn hình nếu muốn bot dùng trình duyệt local.
5. Thêm vào hướng dẫn của agent chính một quy ước: "Việc nặng hoặc cần trình duyệt đã đăng nhập (Shopee, Upwork…) → dùng máy local. Việc lặp lại và routine → chạy trên server."
6. Thử: nhờ bot chạy `uname -a` trên máy local, rồi mở một trang Shopee bằng trình duyệt local.

## Success Criteria
- [ ] Settings → Servers báo máy local "Connected".
- [ ] Bot chạy được lệnh và mở được trang trên máy local. Lần đầu có hỏi xin phép.
- [ ] Tắt công tắc "Share this computer" thì bot mất quyền ngay.

## Risk Assessment
- Bot thấy được thông tin ngoài thư mục đã chọn khi có quyền terminal hoặc màn hình. Cách xử lý: chỉ bật khi cần, tắt bằng công tắc.
- Máy local tắt hoặc app đóng. Cách xử lý: hướng dẫn của bot phải ghi rõ trường hợp này thì báo anh, không tự chuyển sang server.
