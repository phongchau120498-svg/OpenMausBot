---
phase: 1
title: Kiểm kê và sao lưu
status: completed
priority: P1
dependencies: []
---

# Phase 1: Kiểm kê và sao lưu

## Overview
Chụp lại mọi thứ trước khi sửa và kiểm các công cụ xử lý file trên server. Phase này chỉ đọc. Lượt chat ở bước 4 là thao tác duy nhất chạy trên server.

## Requirements
- Bản chụp **nằm ngoài repo**: `~/OMB-private/261113-bot-migration/` trên Mac, quyền `700`.
- Không sửa bot, routine hay skill.

## Implementation Steps
1. Tạo thư mục: `mkdir -p ~/OMB-private/261113-bot-migration && chmod 700 ~/OMB-private`.
2. **Sao lưu toàn bộ (để dự phòng):** anh vào **Settings → Backups → Export backup** rồi lưu file vào thư mục trên. Chỉ dùng file này khi hỏng nặng, vì import sẽ thay toàn bộ bản cài.
3. **Chụp từng phần** bằng API, lưu thành JSON trong thư mục trên:
   - `GET /api/bots`: soul, model, mức duyệt, nơi làm việc, `browser` của 6 bot;
   - `GET /api/routines`: 19 routine, nguyên prompt và lịch;
   - `GET /api/bots/<id>/skills` cho từng bot: danh sách skill, `origin`, `enabled`, và nội dung từng skill nếu GET trả về;
   - **trí nhớ của từng bot**: `MEMORY.md` và các topic, qua route trong `server/routes/bot-memory.ts` hoặc **Bot Settings → Memory**.
   - Trong Nhật ký chỉ ghi số đếm (6 bot, 19 routine, N skill, N file trí nhớ) và mã sha256 của từng file.
4. **Kiểm công cụ xử lý file:** mở chat mới với **Chiêu Giao** bằng phiên của anh và gửi đúng câu:
   `Chạy trên server và trả nguyên kết quả, không làm gì khác: whoami; echo $HOME; pwd; which python3 uv pdftotext unzip; python3 --version; uv --version; df -h $HOME | tail -1`
   - Ghi kết quả vào Nhật ký. Thiếu `uv` hoặc `python3` thì dừng và báo anh, vì phase 2 và 4 dựa vào chúng.
5. **Engine:** mở **Settings → Engines** và ghi số tài khoản Codex, cùng trạng thái Claude và Grok.
6. **App đã nối:** mở **Connect apps** và ghi app nào đã nối. Gia Huy cần **Google Sheets** (sheet giá) và **Stella MCP** nếu Stella có MCP. App nào còn thiếu thì đánh dấu để làm ở phase 4.
7. **Routine, phân loại theo đọc thật:** đọc nguyên prompt từng routine trong bản chụp và ghi vào Nhật ký một bảng gồm tên rút gọn, bot và loại:
   - chỉ đọc nội bộ;
   - đăng công khai;
   - sửa giá hoặc camp;
   - gửi Zalo;
   - nộp Upwork;
   - quá hạn.
   - Phase 5 dùng bảng này để chia nhóm. Không chia theo tên routine.

## Success Criteria
- [ ] Có file backup và bản chụp JSON đủ 6 bot, 19 routine, skill và trí nhớ, nằm ngoài repo.
- [ ] Biết chắc server có `python3`, `uv` và `pdftotext`, và biết thư mục làm việc của bot.
- [ ] Có danh sách engine và app đã nối.
- [ ] Có bảng phân loại 19 routine dựa trên nội dung prompt.

## Risk Assessment
- Bản chụp chứa luật kinh doanh và có thể có dữ liệu KOC. Vì vậy chỉ để trên Mac, quyền `700`, không đưa vào repo.
- Lượt chat ở bước 4 chạy ở mức `full`. Câu lệnh chỉ đọc. Bot làm thêm gì ngoài lệnh thì dừng và báo anh.
