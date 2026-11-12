---
phase: 6
title: Nối máy local làm computer
status: completed
priority: P2
dependencies:
  - 5
---

# Phase 6: Nối máy local làm computer

## Overview
Ghép app MausBot desktop trên máy local của anh với server `bot.onehand.space`, rồi bật "Let bot.onehand.space use this computer". Việc nặng sẽ chạy trên máy anh, với trình duyệt đã đăng nhập sẵn và IP nhà (`docs/self-hosting.md`, mục "Let your server use this computer").

## Quy tắc
- Mọi bấm **Allow** và mọi quyền hệ thống đều do **anh** tự làm. Agent chỉ hướng dẫn và kiểm tra.
- Ghép bằng mã quyền đầy đủ của chủ server. Mã `--phone` hay `--client` không cho mượn máy.
- Chỉ bật đúng quyền cần dùng. Các quyền terminal và màn hình đọc được thông tin ngoài thư mục đã chọn.
- Không cần bật cờ trên server: tính năng mượn máy bật sẵn cho cặp ghép của chủ (`server/config.ts`, `features.sharedComputers`).

## Bước 0: Wayland hay Xorg
Chạy `echo $XDG_SESSION_TYPE` trên máy local. Ngày 12/11 lệnh này trả `wayland`.
- Trên GNOME **Wayland**, quyền điều khiển màn hình local bị khóa cứng (`docs/linux-desktop.md:18-23`). Bot chỉ dùng được thư mục và terminal, không mở được trình duyệt local.
- Muốn bot dùng trình duyệt local (Shopee, Upwork…): anh đăng xuất, chọn **Ubuntu on Xorg** ở màn hình đăng nhập, đăng nhập lại, rồi kiểm tra lại lệnh trên phải trả `x11`.
- Anh chọn hướng nào thì ghi vào nhật ký. Nếu ở lại Wayland, bỏ phép thử 6b bên dưới.

## Các bước
1. Cài hoặc cập nhật app desktop Linux đúng version với server, theo `docs/linux-desktop.md`. Đối chiếu version: `curl -s https://bot.onehand.space/.well-known/openmausbot/environment` và mục About trong app.
2. Anh mở terminal container omb trên Dokploy, chạy `openmausbot pair --label "May local"`, rồi copy link.
3. Trong app local, chọn **Server → Add Server from Copied Pairing Link…** (trên Linux, nhấn Alt để hiện menu). Hoặc chọn **＋ → Connect to a server** rồi dán link.
4. App hỏi "Let bot.onehand.space use this computer?". Anh chọn **Allow**.
5. Vào **Settings → Servers → bot.onehand.space → Choose what it can use**:
   - Thư mục làm việc: mặc định chỉ đọc. Chỉ bật quyền ghi nếu cần.
   - Terminal: bật.
   - Điều khiển màn hình: bật chỉ khi đang ở Xorg, rồi bật thêm **Enable local control**.
   - Mỗi quyền sẽ hiện hộp thoại hệ thống để anh xác nhận.
6. Thêm đoạn này vào hướng dẫn của agent chính (Settings của bot → Instructions):
   > Việc nặng, hoặc cần trình duyệt đã đăng nhập (Shopee, Upwork…), thì dùng máy local của anh. Việc lặp lại và routine thì chạy trên server. Nếu máy local đang offline, báo anh, không tự chuyển việc đó sang server.
7. Thử:
   - a. Nhờ bot: "Chạy `uname -a` trên máy local của anh". Phải thấy tên máy local, và lần đầu bot phải hỏi xin phép.
   - b. Chỉ khi ở Xorg: nhờ bot mở `https://shopee.vn` bằng trình duyệt local, rồi chụp màn hình.
   - c. Tắt công tắc **Share this computer**, rồi nhờ lại 7a. Bot phải báo không còn quyền.

## Success Criteria
- [ ] Settings → Servers báo máy local "Connected".
- [ ] Đạt 7a và 7c. Đạt 7b nếu anh chọn Xorg.
- [ ] Hướng dẫn của agent chính đã có quy ước việc nặng và việc nhẹ.

## Khi gặp lỗi
- App không hỏi "use this computer": link pair đang dùng không phải mã quyền đầy đủ. Tạo lại bằng `openmausbot pair` (không thêm `--client` hay `--phone`).
- Máy local hiện "Offline": app phải đang mở. Tính năng chỉ chạy khi app chạy.
