---
phase: 3
title: "Dựng MausBot song song"
status: pending
priority: P1
dependencies: [2]
---

# Phase 3: Dựng MausBot song song

## Overview
Tạo compose mới tên `mausbot` trong project `onhand-bot` trên Dokploy. Chạy nó cạnh Rakazo, chưa gắn domain. Rakazo vẫn phục vụ như cũ.

## Requirements
- Chỉ tạo mới bên trong project `onhand-bot`, môi trường production `PvQ1vgCicpbLbdqOJ_tor`. Không sửa project nào khác.
- `autoDeploy: false`. Push tài liệu lên main không được tự restart bot. Chỉ deploy khi chủ động.
- Không gắn domain ở phase này. Vì vậy chưa có router Traefik nào trùng với Rakazo.

## Implementation Steps
1. Chụp `project.all` làm mốc để so sánh ở cuối plan.
2. `compose.create`:
   - name `mausbot`, environmentId `PvQ1vgCicpbLbdqOJ_tor`, composeType `docker-compose`.
   - Nguồn custom git `git@github.com:phongchau120498-svg/OpenMausBot.git`, branch `main`. Dùng SSH key giống Rakazo (`customGitSSHKeyId 2BjmDZNZcLVyRIwgx8mud`), nhưng phải kiểm trước rằng key có quyền đọc repo OpenMausBot. Nếu không có quyền: thêm deploy key chỉ đọc (anh làm trên GitHub) hoặc dùng URL https vì repo public.
   - composePath `./deploy/dokploy/docker-compose.yml`.
3. `compose.update`: đặt `autoDeploy: false` và `isolatedDeployment: false`.
4. `compose.saveEnvironment` với 3 biến. Không thêm secret.
   - `DOMAIN=bot.onehand.space`
   - `OMB_BASE_IMAGE=ghcr.io/milind-soni/openmausbot:v0.1.153`, theo version đã chốt ở phase 2.
   - `OMB_DATA_VOLUME=onhand-mausbot_data`
   
   Xác nhận trong log deploy rằng Dokploy đặt `.env` cạnh file compose, để các biến `${…:?}` được nội suy.
5. `compose.deploy`, rồi đọc log deploy tới khi xong. Lần đầu sẽ build lớp CLI. Theo dõi RAM và đĩa bằng `docker.getServerHealth`.
6. Kiểm tra:
   - `docker.getContainersByAppNameMatch` cho thấy `omb` (healthy) và `caddy` đang chạy.
   - Log `omb` không có lỗi.
   - Xác nhận volume tên đúng `onhand-mausbot_data`.
7. Kiểm tra trước API dùng ở phase 5:
   - Tìm `domain.toggleEnable` trong OpenAPI của Dokploy (`settings.getOpenApiDocument`, chỉ đọc).
   - Nếu không có: ghi lại đủ cấu hình 4 domain Rakazo (host, path, service, port, middleware). Phase 5 sẽ xóa rồi tạo lại khi cần rollback.
8. Đọc cấu hình Traefik (`settings.readTraefikConfig`, chỉ đọc) để xem `forwardedHeaders` của entrypoint `websecure`. Phải là chế độ không tin client (mặc định), nghĩa là Traefik bỏ `X-Forwarded-For` mà client tự gửi lên.

## Success Criteria
- [ ] `omb` healthy, `caddy` đang chạy, Rakazo vẫn healthy và trang `bot.onehand.space` vẫn mở được.
- [ ] Đĩa trống còn ít nhất 30 GB sau khi build.
- [ ] `project.all` chỉ khác mốc ở đúng compose mới.

## Risk Assessment
- Thiếu RAM hoặc đĩa trên máy dùng chung. Cách xử lý: dừng ở bước này. Không dọn image của project khác, mà báo anh.
- Build lỗi do mạng (tải npm hoặc Grok). Cách xử lý: deploy lại. Grok có thể tắt tạm bằng build arg `GROK_VERSION=`.
