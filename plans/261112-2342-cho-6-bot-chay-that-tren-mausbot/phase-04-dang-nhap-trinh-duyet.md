---
phase: 4
title: Đăng nhập trình duyệt
status: in-progress
priority: P1
dependencies:
  - 3
---

# Phase 4: Đăng nhập trình duyệt

## Overview
Anh đăng nhập một lần các trang mà bot cần, ngay trong **trình duyệt riêng của từng bot trên server**. Sau đó mỗi bot chạy một lượt thử **không gửi, không đăng, không sửa** để kiểm cả phần web lẫn phần xử lý file.

## Requirements
- Mật khẩu, OTP, QR **do anh làm**. Agent chỉ mở đúng tab Trình duyệt của bot rồi chờ.
- Mỗi bot dùng trình duyệt **riêng** (mặc định), không tạo hồ sơ dùng chung.
- Lượt thử mở trong **chat mới do anh mở hoặc agent mở bằng phiên của anh**, dán câu dặn giới hạn ở đầu.

## Implementation Steps
1. **Nối app còn thiếu** (theo phase 1 bước 6): anh nối **Google Sheets** cho Gia Huy (đọc sheet giá) qua **Connect apps**, cùng các app khác nếu thiếu.
2. **Gia Huy:** mở khung màn hình, tab **Trình duyệt**. Anh đăng nhập:
   - Shopee Seller Center;
   - TikTok Seller Center VN;
   - Stella;
   - Zalo Web (quét QR bằng điện thoại);
   - Google, nếu cần mở sheet trên web.
   - **Lượt thử:** "CHẠY THỬ, CHỈ ĐỌC: kiểm nhanh giá camp Shopee theo luật của em, nhưng **không sửa, không rút, không đăng ký, không gửi Zalo**. Đọc giá trong sheet, tải file mẫu Excel về thư mục của em, điền giá bằng Python, **dừng trước bước upload**, rồi báo kết quả kèm đường dẫn file."
   - Kiểm: có đọc được sheet, có file `.xlsx` trong thư mục bot, không có thao tác ghi nào trên Shopee, Zalo không gửi gì.
3. **Tiêu Băng:** anh đăng nhập `threads.net` và `instagram.com` trong trình duyệt của bot.
   - Anh gửi 2–3 ảnh vào chat với Tiêu Băng.
   - **Lượt thử:** "CHẠY THỬ: soạn bài Threads khung 20h30 theo luật, chọn một ảnh anh vừa gửi, xóa metadata, đổi sang WebP, ghi vào `memory/anh-da-dung.md`, **không đăng**, gửi bản nháp cho anh xem."
   - Kiểm: file WebP có trong thư mục bot, không còn metadata, chưa có bài nào được đăng.
   - Instagram hoặc Threads đòi xác minh vì IP lạ thì anh xác minh. Bị khóa hoặc checkpoint lặp lại thì ghi Nhật ký và báo anh.
4. **Như Phương:** anh đăng nhập Upwork trong trình duyệt của bot.
   - **Lượt thử:** "CHẠY THỬ: mở My Proposals, dựng lại `upwork-job-log.csv` từ các proposal đã nộp, rồi tìm job theo skill `upwork-job-filter` và liệt kê 2 job phù hợp nhất. **Không nộp, không bấm Submit.**"
   - Kiểm: file log có dữ liệu, không có proposal mới.
   - Cloudflare chặn hoặc bắt captcha liên tục thì **dừng**. Lúc đó anh chọn: Upwork chỉ làm khi anh tự nhắn, bot dùng Mac trong chat đó; hoặc tạm bỏ nhóm Upwork.
5. **Chiêu Giao, UX UI:** không cần đăng nhập. Gửi UX UI "dựng một trang HTML thử 1 dòng chữ và mở bằng trình duyệt để kiểm", để thử trình duyệt và thư mục.

## Success Criteria
- [ ] Gia Huy: đã đăng nhập 4 trang và Zalo; lượt thử tạo được file Excel từ sheet và không ghi gì lên Shopee hay Zalo.
- [ ] Tiêu Băng: đã đăng nhập Threads và Instagram; lượt thử tạo ra WebP sạch metadata và chưa đăng.
- [ ] Như Phương: đã đăng nhập Upwork; dựng xong log, không nộp gì. Hoặc đã có quyết định thay thế nếu bị chặn.
- [ ] UX UI: trang thử mở được trong trình duyệt.

## Risk Assessment
- **IP máy chủ dễ bị xác minh** (Instagram, Upwork, Shopee): anh xác minh một lần. Bị chặn lặp lại thì có phương án thay ở bước 4, hoặc báo anh cho các trang khác.
- **Bot làm quá lời dặn "chạy thử":** kiểm ngay sau mỗi lượt. Vi phạm thì dừng, hạ bot đó xuống **Approve for me**, rồi báo anh.
