---
phase: 5
title: "Chuyển domain và gỡ Rakazo"
status: pending
priority: P1
dependencies: [4]
---

# Phase 5: Chuyển domain và gỡ Rakazo

## Overview
Chuyển `bot.onehand.space` sang MausBot, ghép thiết bị của anh, tạo agent chính, rồi gỡ hẳn Rakazo. Rakazo chỉ là bản thử, chưa chạy thật. Anh đã cho phép gỡ mà không cần sao lưu.

## Requirements
- Chỉ gỡ tài nguyên của Rakazo, gồm:
  - compose `rkPYxiV0FMWyfpAGkV4zu` (appName `compose-bypass-1080p-protocol-dv6zak`) cùng volume và network của nó;
  - các container `rakazo-bot-team-*` do Rakazo tự tạo.
- **Không** xóa project `onhand-bot`, vì compose `mausbot` nằm trong đó. Không đụng repo GitHub `OnHand-Bot`.
- Domain mới không gắn middleware `onhand-headers@docker`. Middleware này do container Rakazo khai báo nên sẽ mất theo.
- Gỡ Rakazo **sau khi** MausBot đã chạy qua domain. Trước lúc đó vẫn còn đường quay lại.

## Implementation Steps
1. `compose.update` Rakazo: đặt `autoDeploy: false`. Từ đây push lên repo OnHand-Bot không còn tự deploy lại Rakazo.
2. `compose.stop` Rakazo. Kiểm tra bằng `docker.getContainersByAppNameMatch`: các container phải ở trạng thái exited.
3. Xóa 4 domain Rakazo (`domain.delete`): `jK0weAwdkgjffNhs71Son`, `A0CpxIX6HxKrJDExtE08m`, `P3GkNOQj_pnCa-ZKYtKbq`, `Uiw9EjaawB5YNSZkSi1pi`.
4. `domain.create` cho compose `mausbot`:
   - host `bot.onehand.space`, path `/`, serviceName `caddy`, port `80`.
   - https bật, certificateType `letsencrypt`.
   - Không gắn middleware.
5. `compose.deploy` `mausbot` để áp nhãn Traefik. Xác nhận caddy đã được gắn vào `dokploy-network`.
6. Kiểm tra từ máy local:
   - `curl -s https://bot.onehand.space/api/health` → kết quả chứa `openmausbot`.
   - `curl -sI https://bot.onehand.space/` → chuyển tới trang pair hoặc trả 200 trang pair, không phải giao diện app.
   - Nhập sai mã pair vài lần từ một mạng. Sau đó thử từ một IP khác, ví dụ 4G điện thoại: IP đó vẫn phải pair được, tức là bộ đếm khóa tính theo IP thật của từng client.
7. Ghép admin đầu tiên. Trong terminal container (user `maus`), chạy `openmausbot pair --label "Trình duyệt anh"`. Anh tự mở link. Link chỉ dùng một lần, không dán vào log hay chat.
8. Tạo agent chính trong UI:
   - Engine `codex`, model `gpt-6.1-sol`, effort `medium`.
   - Chạy một lượt thử, rồi thử thêm một lượt ở mức `high`.
9. **Gỡ Rakazo**, chỉ làm khi bước 6–8 đã đạt:
   - `compose.delete` Rakazo với `deleteVolumes: true`.
   - `docker.getContainersByAppNameMatch` theo `rakazo-bot-team`, rồi `docker.removeContainer` từng container trong kết quả. Chỉ xóa những tên bắt đầu bằng `rakazo-`.
   - `dockerVolume.getVolumes`: xóa volume có tên bắt đầu bằng `compose-bypass-1080p-protocol-dv6zak` hoặc `rakazo-` nếu vẫn còn. Đọc tên từng volume trước khi xóa.
10. Bật backup cho volume `onhand-mausbot_data` (chứa đăng nhập CLI, cặp ghép và chat) bằng `volumeBackups.create`, chạy hằng ngày.
    - Đích lưu dùng destination có sẵn trên Dokploy (`destination.all`). Nếu chưa có destination nào, báo anh.
    - Trước mỗi lần đổi `OMB_BASE_IMAGE`, chạy backup tay. Lùi về image cũ hơn có thể làm hỏng dữ liệu (`docs/deploy-vps.md`).
11. So `project.all` với mốc ở phase 3. Chỉ được khác hai chỗ: compose Rakazo không còn, và compose `mausbot` có thêm domain. Các project khác phải giữ nguyên.

## Rollback
- Trước bước 9: xóa domain `mausbot` và `compose.stop mausbot`. Tạo lại 4 domain Rakazo theo bảng trong plan.md, `compose.start` Rakazo, rồi đặt lại `autoDeploy: true`.
- Sau bước 9 thì không còn đường quay về Rakazo, đúng như anh đã cho phép. Nếu MausBot lỗi, sửa MausBot.

## Success Criteria
- [ ] Đạt tiêu chí nghiệm thu 1–3 và 5–6 trong plan.md.
- [ ] Chứng chỉ HTTPS hợp lệ, không có cảnh báo trên trình duyệt.
- [ ] Giao diện chat stream được, tức là SSE không bị buffer.
- [ ] Không còn container hay volume nào của Rakazo. RAM và đĩa trống tăng lên.

## Risk Assessment
- Let's Encrypt chưa cấp lại chứng chỉ ngay cho router mới. Traefik dùng chung kho ACME theo tên miền nên thường dùng lại được chứng chỉ cũ. Nếu lỗi, chờ vài phút rồi xem log Traefik.
- Xóa nhầm tài nguyên của project khác. Cách tránh: chỉ xóa theo id compose của Rakazo và theo tiền tố tên đã nêu. Đọc tên trước mỗi lần xóa.
