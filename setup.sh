#!/bin/bash

# URL trỏ đến file znq-rejoin.py (phiên bản GitHub) trên kho của bạn
# BẠN PHẢI THAY THẾ URL NÀY BẰNG LINK RAW CỦA BẠN
TOOL_URL="https://raw.githubusercontent.com/YourUsername/YourRepo/main/znq-rejoin.py"

echo "============================================="
echo " ZNQ TOOL - SCRIPT CÀI ĐẶT & BẢO MẬT "
echo "============================================="
echo

# Cập nhật danh sách gói của Termux
echo "[*] Đang cập nhật Termux..."
pkg update -y > /dev/null 2>&1

# Cài đặt Python và các gói cần thiết
echo "[*] Đang cài đặt Python và các gói cần thiết..."
pkg install python git -y > /dev/null 2>&1

# Cài đặt các thư viện Python, bao gồm cả công cụ làm rối mã (pyarmor)
echo "[*] Đang cài đặt các thư viện (requests, psutil, pyarmor)..."
pip install requests psutil pyarmor > /dev/null 2>&1

# Tải file tool 1.py gốc về với một tên tạm
echo "[*] Đang tải tool ZNQ..."
curl -sL "$TOOL_URL" -o "tool_source.py"

# Kiểm tra xem file đã được tải về chưa
if [ ! -f "tool_source.py" ]; then
    echo
    echo "❌ LỖI: Không thể tải tool về. Vui lòng kiểm tra lại kết nối mạng hoặc URL."
    exit 1
fi

# Làm rối mã (obfuscate) file tool gốc
echo "[*] Đang tiến hành bảo mật mã nguồn..."
pyarmor obfuscate --output "znq_tool" tool_source.py > /dev/null 2>&1

# Xóa file tool gốc để không ai có thể xem được
echo "[*] Đang dọn dẹp file tạm..."
rm tool_source.py

# Kiểm tra xem quá trình bảo mật có thành công không
if [ -d "znq_tool" ]; then
    echo
    echo "✅ CÀI ĐẶT VÀ BẢO MẬT HOÀN TẤT!"
    echo "============================================="
    echo "Bây giờ, bạn có thể chạy tool bằng lệnh:"
    echo "python znq_tool/znq-rejoin.py"
    echo "============================================="
else
    echo
    echo "❌ LỖI: Không thể bảo mật tool. Vui lòng thử lại."
fi
