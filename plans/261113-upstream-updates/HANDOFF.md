# HANDOFF — lên lịch cập nhật upstream

Cập nhật13/11/2026 — Codex chốt từ transcript và Git, tối tiếp khi anh giao.

- Nhánh làm tiếp: `claude/tiktok-image-channel-bc6ab9`; nhánh lịch sử `claude/schedule-upstream-updates-884c71` đã được gộp và xóa. Source app giữ base `f1d49b252`, chưa có implementation hoặc lịch.
- Nguồn: `agent-digest bdd4f059-c32f-4898-977d-57ed7c3bb07a` trong repo; tin cuốiClaude nói chưa đặt lịch do cần anh chọn phạm vi/chu kỳ/giờ.
- Tiếp: anh chọn báo cáo commitupstream mới hay ghép vào nhánh riêng/mởPR, tần suất và giờ (Asia/Ho_Chi_Minh). Hằng tuần merge+PR và hằng ngày chỉbáo cáo là đềxuấtClaude, chưa đượcchốt. Khi cóyêu cầu lịch cụ thể dùng công cụ automation của app, không viết chỉ thị lịch raw; chưa tạo automation trong lượt này.
- Ràng buộc: remote `origin` là fork của anh, `upstream` là repo gốc; không push upstream, không tự merge/push main, không force/tag/release/deploy. Kiểm workflow và conflict trước hành động tương lai.
- Đã thử, thất bại: không có thao tác lịch hay merge được ghi nhận; chưa kiểm automation thật. Không coi session đang mở là đã có lịch.
- Dở chưa commit: chỉ checkpoint HANDOFF được commit/push trong lượt bàn giao; không source app dở ở lần kiểm.
- Máy nhà: fetch rồi checkout `claude/tiktok-image-channel-bc6ab9`, đọc `HANDOFF.md` ở gốc checkout và mục Lịch cập nhật repo gốc. Bàn giao này giữ nội dung lịch upstream đã gom; ảnh nguồn/login không ở Git. Dòng 6 bot cũ: [bàn giao](../261112-2342-cho-6-bot-chay-that-tren-mausbot/HANDOFF.md).
- Anh giao lưu và push nhánh để tối làm tiếp, **không deploy**; không tạo lịch hoặc thao tác production từ quyền này.

Biên nhận lưu chuyển máy: commit và push riêng nhánh này theo lệnh anh; không deploy, không push main.
