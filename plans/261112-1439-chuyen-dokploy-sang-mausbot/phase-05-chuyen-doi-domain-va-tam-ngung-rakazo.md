---
phase: 5
title: "Chuyển domain và tạm ngưng Rakazo"
status: pending
priority: P1
dependencies: [4]
---

# Phase 5: Chuyển domain và tạm ngưng Rakazo

## Overview
Tạm ngưng Rakazo, chuyển `bot.onehand.space` sang MausBot, ghép thiết bị của anh và tạo agent chính. Anh đã cho phép tạm ngưng Rakazo mà không cần hỏi lại.

## Requirements
- Tạm ngưng nghĩa là: dừng container, tắt domain và tắt `autoDeploy`. **Không** xóa compose, volume, project hay backup.
- Trước khi chuyển, ghi lại trạng thái Rakazo: 4 domain id, `autoDeploy: true` và trạng thái container.
- Domain mới không gắn middleware `onhand-headers@docker`. Middleware này do container Rakazo khai báo, sẽ mất khi Rakazo dừng.

## Implementation Steps
1. Báo anh giờ bắt đầu chuyển. Routine của Rakazo sẽ ngừng từ lúc này.
2. `compose.update` Rakazo `rkPYxiV0FMWyfpAGkV4zu`: đặt `autoDeploy: false`. Từ đây push lên repo OnHand-Bot không còn tự bật lại Rakazo.
3. `compose.stop` Rakazo. Kiểm tra bằng `docker.getContainersByAppNameMatch`: các service web, api, worker, supervisor và computer phải ở trạng thái exited.
4. Tắt 4 domain `jK0weAwdkgjffNhs71Son`, `A0CpxIX6HxKrJDExtE08m`, `P3GkNOQj_pnCa-ZKYtKbq`, `Uiw9EjaawB5YNSZkSi1pi`.
   - Dùng `domain.toggleEnable`.
   - Nếu phase 3 không tìm thấy API đó: xóa cả 4 domain, dựa vào bản ghi cấu hình đã lưu.
5. `domain.create` cho compose `mausbot`:
   - host `bot.onehand.space`, path `/`, serviceName `caddy`, port `80`.
   - https bật, certificateType `letsencrypt`.
   - Không gắn middleware.
6. `compose.deploy` `mausbot` để áp nhãn Traefik.
7. Kiểm tra từ máy local:
   - `curl -s https://bot.onehand.space/api/health` → kết quả chứa `openmausbot`.
   - `curl -sI https://bot.onehand.space/` → chuyển tới trang pair hoặc trả 200 trang pair, không phải giao diện app.
   - Nhập sai mã pair vài lần từ một mạng. Sau đó thử từ một IP khác, ví dụ 4G điện thoại: IP đó vẫn phải pair được, tức là bộ đếm khóa tính theo IP thật của từng client.
8. Ghép admin đầu tiên. Trong terminal container (user `maus`), chạy `openmausbot pair --label "Trình duyệt anh"`. Anh tự mở link. Link chỉ dùng một lần, không dán vào log hay chat.
9. Tạo agent chính trong UI:
   - Engine `codex`, model `gpt-6.1-sol`, effort `medium`.
   - Chạy một lượt thử, rồi thử thêm một lượt ở mức `high`.
10. Bật backup cho volume `onhand-mausbot_data` (chứa đăng nhập CLI, cặp ghép và chat) bằng `volumeBackups.create`, chạy hằng ngày.
    - Đích lưu dùng destination có sẵn trên Dokploy (`destination.all`). Nếu chưa có destination nào, báo anh.
    - Trước mỗi lần đổi `OMB_BASE_IMAGE`, chạy backup tay. Lùi về image cũ hơn có thể làm hỏng dữ liệu (`docs/deploy-vps.md`).
11. So `project.all` với mốc ở phase 3. Chỉ được khác: compose mới, domain mới, và `autoDeploy`, trạng thái, domain của Rakazo.

## Rollback
1. Tắt domain của `mausbot` (`domain.toggleEnable`, hoặc xóa nếu không có API đó), rồi `compose.stop mausbot`.
2. Bật lại 4 domain Rakazo, chạy `compose.start` Rakazo và đặt lại `autoDeploy: true`.
3. Kiểm tra lại `bot.onehand.space/health` của Rakazo.

## Success Criteria
- [ ] Đạt tiêu chí nghiệm thu 1–3 và 5–6 trong plan.md.
- [ ] Chứng chỉ HTTPS hợp lệ, không có cảnh báo trên trình duyệt.
- [ ] Giao diện chat stream được, tức là SSE không bị buffer.

## Risk Assessment
- Let's Encrypt chưa cấp lại chứng chỉ ngay cho router mới. Traefik dùng chung kho ACME theo tên miền nên thường dùng lại được chứng chỉ cũ. Nếu lỗi, chờ vài phút rồi xem log Traefik.
- Có bên ngoài gọi `/api` hoặc `/rpc` của Rakazo (webhook, app điện thoại Rakazo). Những lời gọi này sẽ lỗi. Ghi danh sách từ bản xuất ở phase 1 để anh xử lý.
