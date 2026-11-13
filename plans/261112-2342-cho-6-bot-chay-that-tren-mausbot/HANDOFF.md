# HANDOFF
Cập nhật lần cuối: 2026-11-13 09:15 — Claude Code (Mac)

## Cho 6 bot chạy thật trên MausBot · phụ trách: Claude Code + anh Phong · nhánh: `main` · cập nhật: 2026-11-13
- Mục tiêu: đưa 6 bot từ máy cũ sang server MausBot (`bot.onehand.space`), chạy routine thật mà không gửi hay đăng gì ngoài ý anh.
- Chặng hiện tại: phase 1–3 xong. Phase 4 đang dở, lượt chạy thử 1 chưa đạt vì trình duyệt riêng của bot chưa có phiên đăng nhập. Phase 5 chưa bắt đầu. Cả 18 routine vẫn **tắt**. Chi tiết nằm ở mục "Nhật ký thực thi" trong [plan.md](plan.md).
- Dở dang chưa commit: không (thư mục plan được commit cùng lúc với file này).
- Tiếp theo:
  1. **Anh đăng nhập lại** trong app, ở danh sách bot **Online** (không phải bot của máy tính). Mở từng bot, bấm nút màn hình, chọn tab **Trình duyệt**:
     - Gia Huy - ECOM: Shopee Seller Center, TikTok Seller Center VN, Stella, Zalo Web (quét QR), Google;
     - Tiêu Băng - CONTENT: Instagram và Threads. Gửi thêm 2–3 ảnh vào chat với Tiêu Băng;
     - Như Phương - SALE: mở chat chạy thử mới nhất, bấm thẻ đăng nhập Upwork, qua bước Cloudflare rồi bấm **Done**. Bot sẽ tự làm tiếp.
  2. **Agent chạy thử lượt 2**, chỉ khi anh báo đã đăng nhập xong: mở chat mới bằng `POST /api/bots/<id>/tasks` (body `{}`), rồi gửi câu dặn "CHẠY THỬ" qua `POST /api/bots/<id>/messages` với `{text, threadId}`. Đọc kết quả bằng `GET /api/threads/<threadId>/messages?limit=40` và `/job`. Câu dặn và tiêu chí kiểm nằm ở [phase-04](phase-04-dang-nhap-trinh-duyet.md), nhưng thay "Python" bằng Node (`exceljs`, `sharp`).
  3. Đạt thì chạy `ck plan check 4`, rồi sang [phase-05](phase-05-bat-routine-theo-nhom.md): bật routine theo nhóm A→E. Từ nhóm B trở đi, mỗi nhóm cần anh duyệt. Nhóm D cần anh chỉ định nhóm Zalo để thử.
- Blocker: phiên đăng nhập trên server (cần anh làm). Upwork có thể bị Cloudflare chặn lặp lại. Nếu vậy, anh chọn một trong hai: chỉ làm Upwork khi anh tự nhắn (bot dùng máy cho mượn), hoặc tạm bỏ nhóm Upwork.
- Ràng buộc/không được đụng:
  - Agent không đăng nhập, không nhập mật khẩu, OTP hay QR.
  - Không bật routine ngoài phase 5. Không dùng **Run now** để thử, vì nút này chạy prompt thật.
  - Repo này **public**. Không ghi vào repo soul, prompt, luật nghiệp vụ, tên nhóm Zalo, tài khoản, IP hay ID bot/hạ tầng.
  - Push cần anh cho phép riêng mỗi lần.
  - Toàn bộ luật nằm ở mục "Hướng dẫn cho agent thực thi" trong [plan.md](plan.md).
- Đã thử, thất bại:
  - Gửi tin vào một `threadId` tự tạo thì server trả 409 "the bot switched tasks…". Phải tạo chat bằng `/tasks` trước.
  - `GET /api/threads` và `GET /api/bots/<id>/tasks` không có route.
  - Trình duyệt trong app không tải được file. Bản chụp đang nằm trên server ở `/data/.openmausbot/attachments/` (UUID ghi trong ghi chú riêng của phiên trên Mac). Có rủi ro bị dọn, nên anh nên **Export backup** từ app.
  - Server không có `python3` hay `uv`, nên dùng Node. Lệnh npm phải dùng cache riêng cho từng thư mục, vì `/data/.npm` lỗi quyền.
- Kiểm tra:
  - Đã chạy lượt thử 1 lúc 13/11 09:05. Cả 3 bot không gửi, không đăng, không sửa gì.
  - Gia Huy đọc được sheet giá (57 dòng), nhưng gặp trang đăng nhập Shopee.
  - Tiêu Băng gặp form đăng nhập Instagram, Threads trả 429.
  - Như Phương bị Cloudflare chặn.
  - **Chưa kiểm:** tạo Excel, WebP từ ảnh thật, log Upwork, TikTok, Stella, Zalo.
- Task: phase 4 và 5 trong [plan.md](plan.md). Các câu hỏi còn mở nằm ở mục "Câu hỏi còn mở": skill "UI UX Pro Max" cho UX UI, nhóm Zalo để thử, Export backup.
