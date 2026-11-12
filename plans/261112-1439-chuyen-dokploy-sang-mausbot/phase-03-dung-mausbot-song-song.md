---
phase: 3
title: Dựng MausBot song song
status: completed
priority: P1
dependencies:
  - 2
---

# Phase 3: Dựng MausBot song song

## Overview
Tạo compose `mausbot` trong project `onhand-bot` trên Dokploy và deploy nó, **chưa gắn domain**. Rakazo vẫn chạy và vẫn giữ `bot.onehand.space`.

## Quy tắc
- Mọi thao tác Dokploy dùng tool MCP `mcp__lowbit-dokploy__*`. Tool chưa được nạp thì nạp bằng ToolSearch, query `select:<tên>`.
- Chỉ **tạo mới** trong project `onhand-bot` (`projectId 9oM0rKdu-q-2e3a7I_oVz`), môi trường `PvQ1vgCicpbLbdqOJ_tor`.
- **Không gọi bất kỳ tool ghi nào lên id thuộc project khác.** Máy này dùng chung với khoảng 15 project. Ở phase này cũng không đụng Rakazo.
- Không thêm domain ở phase này.

## Bước 1: chụp mốc
Gọi `project-all` rồi lưu kết quả vào file scratch `baseline-project-all.json`. File này ở thư mục scratch, **không** nằm trong repo, vì nó có tên các project khác. Gọi thêm `docker-getServerHealth {sinceHours: 1}` và ghi lại `memUsedBytes` và `disk.usedBytes`.

**Dừng nếu** đĩa trống dưới 25 GB hoặc RAM trống dưới 5 GB, rồi báo anh. Không tự dọn image hay volume của project khác.

## Bước 2: tạo compose
```
compose-create {
  name: "mausbot",
  environmentId: "PvQ1vgCicpbLbdqOJ_tor",
  composeType: "docker-compose",
  sourceType: "git",
  description: "OpenMausBot (fork) behind Traefik"
}
```
Ghi lại `composeId` và `appName` trả về. Các phase sau gọi chúng là `MAUS_ID` và `MAUS_APP`.

## Bước 3: trỏ nguồn git và tắt tự deploy
Repo fork để public (đã kiểm), nên dùng URL https và không cần SSH key:
```
compose-update {
  composeId: MAUS_ID,
  sourceType: "git",
  customGitUrl: "https://github.com/phongchau120498-svg/OpenMausBot.git",
  customGitBranch: "main",
  customGitSSHKeyId: null,
  composePath: "./deploy/dokploy/docker-compose.yml",
  autoDeploy: false,
  isolatedDeployment: false,
  randomize: false
}
```

## Bước 4: biến môi trường
```
compose-saveEnvironment {
  composeId: MAUS_ID,
  createEnvFile: true,
  env: "DOMAIN=bot.onehand.space\nOMB_BASE_IMAGE=ghcr.io/milind-soni/openmausbot:v0.1.153\nOMB_DATA_VOLUME=onhand-mausbot_data"
}
```

## Bước 5: deploy và theo dõi
1. Gọi `compose-deploy {composeId: MAUS_ID, title: "first deploy"}`.
2. Theo dõi tiến trình:
   - `deployment-allByCompose {composeId: MAUS_ID}` để lấy `deploymentId` mới nhất.
   - `deployment-readLogs {deploymentId, tail: 200}`, gọi lại khoảng mỗi 60 giây.
   - Lần đầu mất khoảng 5–15 phút vì phải kéo image và cài CLI.
3. Trạng thái `done` là xong. Gặp `error` thì đọc khoảng 200 dòng log cuối, rồi xem mục "Khi gặp lỗi" bên dưới.
4. Trong log phải có dòng nạp `.env`, hoặc ít nhất không có lỗi `required variable ... is missing`. Có lỗi này nghĩa là Dokploy không đặt `.env` cạnh file compose. Khi đó dừng và báo anh.

## Bước 6: kiểm tra container
- `docker-getContainersByAppNameMatch {appName: MAUS_APP, appType: "docker-compose"}` phải cho thấy:
  - `…-omb-1` đang chạy và healthy (chờ tối đa 3 phút);
  - `…-caddy-1` đang chạy.
- `compose-readLogs {composeId: MAUS_ID, containerId: <id của omb>, tail: 100}` không được có `Error` hay `EADDRINUSE`.
- `dockerVolume-getVolumes` phải có volume tên đúng `onhand-mausbot_data`.
- Gọi lại `docker-getContainersByAppNameMatch` cho Rakazo (`compose-bypass-1080p-protocol-dv6zak`): các container web, api, worker phải vẫn healthy.
- `docker-getServerHealth`: đĩa trống còn ít nhất 20 GB.

## Success Criteria
- [ ] `omb` healthy, `caddy` đang chạy, volume `onhand-mausbot_data` có thật.
- [ ] Rakazo không bị ảnh hưởng.
- [ ] `project-all` chỉ khác mốc đúng một chỗ: compose `mausbot` mới.
- [ ] `MAUS_ID` và `MAUS_APP` đã ghi vào "Nhật ký thực thi" trong plan.md.

## Khi gặp lỗi
- Clone lỗi (repo private hoặc URL sai): kiểm bằng `gh repo view phongchau120498-svg/OpenMausBot --json visibility`. Không tự gắn SSH key của Rakazo.
- Build lỗi do mạng: deploy lại 1 lần. Lỗi lần nữa thì dừng và báo anh.
- Container `omb` khởi động lại liên tục: đọc log, báo anh. Không đổi cấu hình compose trên Dokploy bằng tay; sửa file trong repo (phase 2) rồi deploy lại.
