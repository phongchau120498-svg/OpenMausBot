# HANDOFF — OpenMausBot

Cập nhật: 13/11/2026 — Codex kiểm transcript và Git để chuyển máy; tối tiếp khi anh giao.

## Ảnh TikTok từ tư liệu có sẵn · Claude · nhánh `claude/tiktok-image-channel-bc6ab9`

- Mục tiêu: tiếp tục phép thử ảnh có chữ từ tư liệu anh cung cấp, xem chất lượng trước khi nối phần đăng bài. Chủ đề, copy và tư liệu riêng giữ ngoài repo public.
- Chặng hiện tại: source app không đổi so với `f1d49b252`. Claude làm script và ảnh thử ngoài repo; snapshot script được giữ tại [assets/tiktok-anh.sh](plans/261113-tiktok-image-channel/assets/tiktok-anh.sh). Đây là bản thử chưa tích hợp, không phải tính năng đã phát hành.
- Bằng chứng nguồn: transcript Claude `58b1c7c2-ccd5-44ee-97ec-06b9762c2bed`, cập nhật16:56 ngày13/11. Claude báo đã thử trích khung, chữ tiếng Việt và ghép bộ ảnh; Codex chỉ xác minh file/script tồn tại và lưu nguyên bản, chưa chạy lại ảnh/video hay xác nhận chất lượng. Claude nói đang chuẩn bị tạo Tuyết Nhi cho Tiêu Băng, sau đó bị lỗi403 Cloudflare/API; chưa có biên nhận tạo nhân viên thành công, không tạo trùng khi tiếp.
- Tư liệu ngoài Git trên máy hiện tại: `~/tiktok-anh/nguon/` (nguồn), `~/tiktok-anh/ra/` (ảnh thử), `~/tiktok-anh/tools/tiktok-anh.sh` (script gốc). Tối dùng lại nguồnDrive anh đã cấp trong tài khoản của anh hoặc chuyển riêng các thư mục này. Git chỉ mang script/bàn giao; không mang ảnh, video, phiên trình duyệt hay thông tin đăng nhập. Không ghi link Drive riêng, copy sản phẩm hoặc prompt bot vào repo public.
- Máy nhà: fetch rồi checkout nhánh ở đầu mục, đọc HANDOFF ở gốc checkout. Không cần đường worktree hoặc transcript Linux để đọc bàn giao này. Script giả định cấu trúc `tools/`, `nguon/`, `ra/` bên ngoài repo; sao chép bản lưu vào `~/tiktok-anh/tools/` rồi mới dùng, tránh sinh ảnh riêng vào checkout public. Cần FFmpeg/ffprobe, ImageMagick7 (`magick`), Bash/GNUstat và font Noto Sans hỗ trợ tiếng Việt; macOS chưa kiểm và đường font/stat có thể phải đổi.
- Tiếp theo: (1) đọc lại cấu hình thật bằng chức năng hiện có, xác minh đã có nhân viên được yêu cầu chưa; không thử mutation vào app thật để làm bằng chứng. (2) Khôi phục tư liệu riêng và mở bộ ảnh thử cho anh chọn; lấy chữ/brief của anh, không tự dựng lời hứa sản phẩm. (3) Kiểm chữ tràn/cắt và metadata bằng ảnh có EXIF thật trước khi báo đạt; ghi log kiểm thực. (4) Anh duyệt chất lượng rồi mới bàn nối phần đăng; chưa có quyền đăng thật từ checkpoint này.
- Đã thử, thất bại: trình duyệt từng không có phiên đăng nhập, đường nhận file từ browser bị chặn gọi về local; sau đóClaude báo cóảnh và đã đăng nhậpMausBot nhưng lời cuối vẫn403 Cloudflare/API. Không suy lỗi này là mật khẩu sai hoặc server hỏng. Lượtmetadata đầu không chứng minh được vì ảnh mẫu không cóEXIF; Claude nói thử lại nhưng Codex chưa đọc bằng chứng cuối. Dòng chữ dài từng tràn; chưa khóa thành quy tắc sản phẩm, cần xemảnh thật.
- Dở chưa commit: checkpoint HANDOFF + script thử được commit/push trong lượt bàn giao này; không có patch app dở đượcGit ghi nhận. Trước sửa luôn đọc HEAD/status mới vì Claude có thể tiếp tục. Không đụng `.claude/launch.json` của main.
- Kiểm tra lượt này: `bash -n` cho bảnscript lưu và `git diff --check`; không chạy app fixture, model, bot, tảiDrive, gửi hay đăng. Khi sửa app phải đọc [AGENTS.md](AGENTS.md) và [Verification](docs/verification/README.md), dùng fixture cô lập.

## Lịch cập nhật repo gốc · nhánh `claude/schedule-upstream-updates-884c71`

- Bàn giao đầy đủ nằm ở HANDOFF của nhánh này. Chưa có lịch được tạo. Anh chưa chọn phạm vi công việc, chu kỳ và giờ; đừng tự lên lịch hoặc tự merge upstream.
- Hai hướng Claude mới đề xuất: báo cáo upstream hoặc nhánh cập nhật+PR; đây chưa phải lựa chọn đãduyệt.

## Sáu bot đang vận hành

- Dòng việc cũ giữ tại [bàn giao riêng](plans/261112-2342-cho-6-bot-chay-that-tren-mausbot/HANDOFF.md). Đọc trạng thái mới trước vận hành; không bật routine, đăng nhập hoặc chạy tác vụ thật từ yêu cầu lưu/pushbàn giao này.

## Quyền lượt bàn giao

Anh giao commit/push để tối đổi máy, **không deploy**. Chỉ push nhánh riêng, không main/tag/release/workflowdispatch, không đổi cấu hình production. Repo public: không commit secret, PII, phiênđăng nhập, soul/prompt/luật nghiệp vụ riêng hoặc ảnh nguồn.

Biên nhận lưu chuyển máy: commit và push riêng nhánh này theo lệnh anh; không deploy, không push main.
