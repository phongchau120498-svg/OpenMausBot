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

## Bước 7: nhiều tài khoản Codex (anh có 5 tài khoản Plus, mỗi tài khoản bị giới hạn 5 giờ)

**Vấn đề:** Codex CLI chỉ giữ một đăng nhập trong `CODEX_HOME` (mặc định `/data/.codex`). Đăng nhập tài khoản thứ hai sẽ ghi đè tài khoản đầu.

**Cách giải quyết:** mỗi tài khoản một thư mục `CODEX_HOME` riêng, ứng với một instance Codex riêng trong Plus. Instance nhận `environment` và truyền vào tiến trình Codex (`server/drivers/codex.ts:336-340`). Plus đọc `CODEX_HOME` đó (`server/drivers/codex-identity.ts:11`). Tài khoản 1 dùng `/data/.codex` có sẵn, nên chỉ cần thêm 4 instance cho tài khoản 2–5.

Ghi chú về an toàn:
- Anh xác nhận việc dùng nhiều tài khoản Plus là quyết định của anh. Việc này có thể vi phạm điều khoản của OpenAI, và rủi ro là bị khóa tài khoản. Agent không bàn thêm.
- Agent không tự đăng nhập. Mỗi lệnh `codex login` do anh chạy.

Các bước (agent đưa lệnh, anh chạy trong terminal container `omb`, user `maus`):

1. Tạo thư mục. Lặp lại cho `2`, `3`, `4`, `5`:
   ```bash
   mkdir -p /data/codex-homes/2 && chmod 700 /data/codex-homes/2
   ```
2. Đăng nhập từng tài khoản **một lần**. Mỗi lần dùng tài khoản ChatGPT Plus khác:
   ```bash
   CODEX_HOME=/data/codex-homes/2 codex login --device-auth
   CODEX_HOME=/data/codex-homes/2 codex login status
   ```
   Lặp lại cho 3, 4, 5. Thư mục nằm trong `/data` nên đăng nhập còn nguyên sau khi deploy lại.
3. Thêm instance vào `/data/.openmausbot/config.json`, mục `"instances"`. Anh thêm bằng tay, hoặc agent đưa đoạn JSON để anh dán. Chỉ **thêm**, không xóa mục có sẵn:
   ```json
   "codex-2": { "driver": "codex", "displayName": "Codex 2", "environment": { "CODEX_HOME": "/data/codex-homes/2" } },
   "codex-3": { "driver": "codex", "displayName": "Codex 3", "environment": { "CODEX_HOME": "/data/codex-homes/3" } },
   "codex-4": { "driver": "codex", "displayName": "Codex 4", "environment": { "CODEX_HOME": "/data/codex-homes/4" } },
   "codex-5": { "driver": "codex", "displayName": "Codex 5", "environment": { "CODEX_HOME": "/data/codex-homes/5" } }
   ```
   Trước khi sửa, sao chép file để quay lại được: `cp /data/.openmausbot/config.json /data/.openmausbot/config.json.bak`. Sau khi sửa, kiểm tra JSON hợp lệ: `node -e "JSON.parse(require('fs').readFileSync('/data/.openmausbot/config.json','utf8'));console.log('JSON_OK')"`.
4. Restart container `omb`: agent gọi `docker-restartContainer`. Instance chỉ được đọc lúc khởi động (`docs/custom-engines.md`).
5. **Phép thử bắt buộc, không bỏ qua.** Trong UI, mục Settings → Engines:
   - 5 instance Codex phải hiện, và mỗi cái báo đã đăng nhập.
   - Email hiển thị của mỗi instance phải **khác nhau**. Nếu hai instance hiện cùng một email thì `CODEX_HOME` bị đè và đăng nhập đang dùng chung: dừng và báo anh.
   - Tạo một bot thử, chọn engine `Codex 2`, gửi "trả lời đúng một chữ: ok". Phải có trả lời. Sau đó xóa bot thử.
6. **Dự phòng khi hết giới hạn.** Tự chuyển khi hết lượt đã bật sẵn (`server/quota-switch.ts:74-77`: chỉ tắt khi `OMB_QUOTA_SWITCH=0`). Không đặt biến đó.
   - Trong cài đặt của agent chính, chọn danh sách dự phòng theo thứ tự `Codex 2` → `Codex 3` → `Codex 4` → `Codex 5`. Thứ tự này do `chosen(botId)` trong `server/host/limit-takeover.ts` quyết định.
   - Khi không chọn thì Plus tự chọn engine khác dùng gói đăng ký, nhưng không theo thứ tự anh muốn.
   - Agent không có cách ép tài khoản hết lượt để thử chuyển. Phần này chỉ kiểm khi tài khoản đầu hết lượt thật. Ghi vào nhật ký là "chưa kiểm chuyển tự động".
7. Ghi vào nhật ký: 5 email đã đăng nhập (chỉ ghi dạng `a***@gmail.com`, không ghi đủ), và kết quả bước 5.

Chưa kiểm chứng trước khi viết (từ đọc code, chưa chạy): hai instance cùng driver Codex có tách đăng nhập đúng không. Phép thử ở bước 5 chính là để xác nhận điều này.

## Success Criteria
- [ ] 5 instance Codex đã đăng nhập, email khác nhau, và instance `Codex 2` trả lời được.
- [ ] Danh sách dự phòng của agent chính đã đặt theo thứ tự.
- [ ] `codex login status` báo đã đăng nhập, cả trước và sau khi restart.
- [ ] `claude -p` trả lời được.
- [ ] Grok: đã đăng nhập, hoặc anh chọn để sau. Ghi rõ là trường hợp nào.

## Khi gặp lỗi
- Hai instance hiện cùng một email: dừng. Không đăng nhập thêm tài khoản khác cho đến khi anh xem. Khôi phục bằng `config.json.bak`.
- Sau khi sửa `config.json`, `omb` không lên: khôi phục `cp config.json.bak config.json` rồi restart.
- `codex login --device-auth` báo không có cờ này: chạy `codex login --help`, rồi báo anh cách đăng nhập không cần trình duyệt mà bản này hỗ trợ.
- Terminal Dokploy không mở được: anh dùng nút "Open terminal" trong trang Docker của Dokploy. Không có cách nào khác vì không có SSH.
