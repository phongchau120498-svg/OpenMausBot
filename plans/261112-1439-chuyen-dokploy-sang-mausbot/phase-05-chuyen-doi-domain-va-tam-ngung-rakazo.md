---
phase: 5
title: "Chuyển domain và gỡ Rakazo"
status: pending
priority: P1
dependencies: [4]
---

# Phase 5: Chuyển domain và gỡ Rakazo

## Overview
Chuyển `bot.onehand.space` sang MausBot, ghép trình duyệt của anh, tạo agent chính, rồi gỡ hẳn Rakazo. Rakazo chỉ là bản thử. Anh đã cho phép gỡ mà không sao lưu và không cần hỏi lại.

## Quy tắc
- Chỉ gỡ đúng những thứ này:
  - compose Rakazo `rkPYxiV0FMWyfpAGkV4zu` (appName `compose-bypass-1080p-protocol-dv6zak`);
  - 4 domain của compose đó;
  - các container có tên bắt đầu bằng `rakazo-bot-team-`;
  - các volume có tên bắt đầu bằng `compose-bypass-1080p-protocol-dv6zak` hoặc `rakazo-`.
- **Trước mỗi lần xóa, đọc lại tên và id**, kiểm khớp đúng một trong các mẫu trên. Không khớp thì không xóa.
- **Không** xóa project `onhand-bot`: compose `mausbot` đang nằm trong đó. Không đụng repo GitHub `OnHand-Bot` hay project nào khác.
- Bước 9 (gỡ Rakazo) chỉ làm khi bước 6–8 đã đạt.

## Bảng domain Rakazo (để tạo lại nếu phải quay về trước bước 9)
Cả 4 domain cùng host `bot.onehand.space`, https, letsencrypt, middleware `onhand-headers@docker`.

| path | service | port | domainId |
|---|---|---|---|
| `/` | web | 5173 | `jK0weAwdkgjffNhs71Son` |
| `/api` | api | 3100 | `A0CpxIX6HxKrJDExtE08m` |
| `/rpc` | api | 3100 | `P3GkNOQj_pnCa-ZKYtKbq` |
| `/health` | api | 3100 | `Uiw9EjaawB5YNSZkSi1pi` |

## Các bước
1. **Tắt tự deploy của Rakazo** để push lên repo OnHand-Bot không dựng lại nó:
   `compose-update {composeId: "rkPYxiV0FMWyfpAGkV4zu", autoDeploy: false}`
2. **Dừng Rakazo:** `compose-stop {composeId: "rkPYxiV0FMWyfpAGkV4zu"}`. Kiểm bằng `docker-getContainersByAppNameMatch {appName: "compose-bypass-1080p-protocol-dv6zak", appType: "docker-compose"}`: không còn container nào `running`.
3. **Xóa 4 domain Rakazo:** gọi `domain-delete` lần lượt với từng `domainId` trong bảng.
4. **Gắn domain cho MausBot:**
   ```
   domain-create {
     composeId: MAUS_ID, domainType: "compose",
     host: "bot.onehand.space", path: "/", internalPath: "/", stripPath: false,
     serviceName: "caddy", port: 80,
     https: true, certificateType: "letsencrypt",
     middlewares: []
   }
   ```
5. **Deploy lại để áp nhãn Traefik:** `compose-deploy {composeId: MAUS_ID, title: "attach domain"}`. Theo dõi tới `done` như phase 3.
6. **Kiểm tra từ máy local.** Chạy được ngay, không cần anh làm gì:

   | # | Lệnh | Phải thấy |
   |---|---|---|
   | a | `curl -s https://bot.onehand.space/api/health` | `{"app":"openmausbot"}` |
   | b | `curl -s -o /dev/null -w '%{http_code}\n' https://bot.onehand.space/api/connectors` | `401` hoặc `403` |
   | c | `curl -s -o /dev/null -w '%{http_code} %{ssl_verify_result}\n' https://bot.onehand.space/` | `200 0`: chứng chỉ hợp lệ |
   | d | `curl -s -o /dev/null -w '%{http_code}\n' -H 'X-Forwarded-For: 127.0.0.1' https://bot.onehand.space/api/connectors` | vẫn `401` hoặc `403`: giả IP không qua được |

   - **b hoặc d trả `200`:** dừng ngay. Xóa domain vừa tạo, rồi báo anh. Lỗi này nghĩa là ai cũng vào được với quyền chủ.
   - **a trả `404` hoặc `502`:** đọc log caddy và omb. Kiểm caddy đã có `dokploy-network` chưa: `docker-getContainersByAppNameMatch` rồi xem network, hoặc xem log Traefik. Nếu Dokploy không tự gắn network, sửa compose trong repo: thêm `networks: [default, dokploy-network]` cho caddy, và khai báo `dokploy-network: {external: true}`. Sau đó deploy lại.
7. **Ghép admin đầu tiên.** Anh làm bước này; agent chỉ đưa lệnh.
   - Anh chạy trong terminal của container omb (user `maus`): `openmausbot pair --label "Trinh duyet anh"`.
   - Anh tự mở link in ra. Link dùng một lần; không dán vào chat.
   - Sau khi ghép xong, anh báo agent.
8. **Tạo agent chính** (anh làm trên UI, hoặc agent hướng dẫn từng bước):
   - Engine `codex`, model `gpt-6.1-sol`, effort `medium`.
   - Gửi "Chào em, trả lời đúng một chữ: ok". Phải có trả lời.
   - Đổi effort sang `high` rồi gửi lại. Vẫn phải có trả lời.
9. **Gỡ Rakazo.** Chỉ làm khi bước 6–8 đã đạt.
   1. `compose-delete {composeId: "rkPYxiV0FMWyfpAGkV4zu", deleteVolumes: true}`
   2. `docker-getContainersByAppNameMatch {appName: "rakazo-bot-team"}`: với mỗi container có tên bắt đầu bằng `rakazo-bot-team-`, gọi `docker-removeContainer {containerId}`.
   3. `dockerVolume-getVolumes`: với mỗi volume có tên bắt đầu bằng `compose-bypass-1080p-protocol-dv6zak` hoặc `rakazo-`, gọi `dockerVolume-removeVolume {volumeName}`. Tuyệt đối không xóa volume nào khác.
   4. Kiểm lại cả hai danh sách: không còn tên nào khớp hai mẫu trên.
10. **Backup hằng ngày.** Dokploy hiện **chưa có destination nào** (`destination.all` rỗng, kiểm ngày 12/11).
    - Gọi lại `destination-all`. Vẫn rỗng thì **không tự tạo**: việc tạo cần thông tin S3 hoặc R2 của anh. Ghi "backup chờ anh tạo destination" vào nhật ký rồi đi tiếp.
    - Đã có destination thì gọi:
      ```
      volumeBackups-create {
        name: "mausbot-data", serviceType: "compose", composeId: MAUS_ID, serviceName: "omb",
        volumeName: "onhand-mausbot_data", prefix: "mausbot",
        cronExpression: "0 3 * * *", keepLatestCount: 7,
        destinationId: <id>, turnOff: false, enabled: true
      }
      ```
11. **So mốc:** gọi `project-all` và so với `baseline-project-all.json` từ phase 3. Chỉ được khác 2 chỗ:
    - compose Rakazo không còn;
    - compose `mausbot` có domain.

    Các project khác phải giống hệt mốc.

## Quay lại (chỉ trước bước 9)
1. Xóa domain `mausbot`, rồi `compose-stop {composeId: MAUS_ID}`.
2. Tạo lại 4 domain Rakazo theo bảng ở trên, có middleware.
3. Gọi `compose-deploy` Rakazo. Deploy sẽ khởi động lại và áp nhãn.
4. Đặt lại `autoDeploy: true` cho Rakazo.

Sau bước 9 thì không quay lại được nữa, đúng như anh đã cho phép.

## Success Criteria
- [ ] Phép thử 6a–6d đúng như bảng.
- [ ] Anh đã ghép được. Agent chính trả lời được ở cả `medium` lẫn `high`.
- [ ] Không còn compose, container hay volume nào của Rakazo. Project `onhand-bot` vẫn còn.
- [ ] `project-all` chỉ khác mốc đúng 2 chỗ đã nêu.
- [ ] Backup: đã bật, hoặc ghi rõ là chờ anh tạo destination.
