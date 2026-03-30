{ pkgs, ... }: {
  channel = "stable-24.11";

  packages = [
    pkgs.docker
    pkgs.tailscale
    pkgs.socat
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.unzip
    pkgs.curl
    pkgs.wget
  ];

  services.docker.enable = true;

  idx.workspace.onStart = {
    boot-sequence = ''
      set -e

      GREEN='\033[0;32m'
      BLUE='\033[0;34m'
      YELLOW='\033[1;33m'
      CYAN='\033[0;36m'
      NC='\033[0m'

      echo -e "''${BLUE}==================================================''${NC}"
      echo -e "''${CYAN}         🚀 KHỞI ĐỘNG HỆ THỐNG ZUN CLOUD 🚀         ''${NC}"
      echo -e "''${BLUE}==================================================''${NC}"

      if [ ! -f /home/user/.cleanup_done ]; then
        echo -e "''${YELLOW}[1/4] 🧹 Đang tiến hành dọn dẹp không gian lưu trữ lần đầu...''${NC}"
        rm -rf /home/user/.gradle /home/user/.emu
        find /home/user -mindepth 1 -maxdepth 1 ! -name '.*' -exec rm -rf {} +
        touch /home/user/.cleanup_done
        echo -e "''${GREEN}      ✅ Dọn dẹp hoàn tất. Đã bảo vệ cấu hình hệ thống!''${NC}"
      else
        echo -e "''${GREEN}[1/4] 🧹 Hệ thống đã được tối ưu từ trước. Bỏ qua dọn dẹp.''${NC}"
      fi

      echo -e "''${YELLOW}[2/4] 🌐 Đang thiết lập mạng riêng ảo Tailscale...''${NC}"
      sudo tailscaled --tun=userspace-networking --socks5-server=localhost:1055 > /dev/null 2>&1 &
      sleep 3
      sudo tailscale up --authkey=tskey-auth-kLFsqw5jzS11CNTRL-HLgERv9ZdVP4bV1kUjFHVP6BJ1SdC8Jt --hostname=idx-zun-cloud --accept-routes > /dev/null 2>&1 || true
      
      TS_IP=$(tailscale ip -4 2>/dev/null || echo "Đang lấy IP...")
      echo -e "''${GREEN}      ✅ Đã kết nối Tailscale! IP nội bộ: ''${CYAN}''${TS_IP}''${NC}"

      echo -e "''${YELLOW}[3/4] 🐳 Kiểm tra trạng thái Ubuntu Desktop (noVNC)...''${NC}"
      if ! docker ps -a --format '{{.Names}}' | grep -qx 'ubuntu-novnc'; then
        echo -e "''${YELLOW}      ⏳ Đang khởi tạo và cấu hình container mới...''${NC}"
        docker run --name ubuntu-novnc \
          --restart always \
          --shm-size 1g -d \
          --cap-add=SYS_ADMIN \
          -p 8080:10000 \
          -p 5900:5900 \
          -p 3389:3389 \
          -e VNC_PASSWD=123456 \
          -e SCREEN_WIDTH=1280 \
          -e SCREEN_HEIGHT=720 \
          thuonghai2711/ubuntu-novnc-pulseaudio:22.04 > /dev/null
        echo -e "''${GREEN}      ✅ Đã tạo và khởi chạy container thành công!''${NC}"
      else
        echo -e "''${YELLOW}      ⏳ Container đã tồn tại, đang kiểm tra tiến trình...''${NC}"
        docker start ubuntu-novnc > /dev/null 2>&1 || true
        docker update --restart always ubuntu-novnc > /dev/null 2>&1
        echo -e "''${GREEN}      ✅ Container đang hoạt động ổn định!''${NC}"
      fi

      echo -e "''${YELLOW}[4/4] 🌍 Đang kiểm tra cập nhật Google Chrome bên trong máy ảo...''${NC}"
      docker exec -d ubuntu-novnc bash -c "
        apt update -qq && 
        apt install -y wget -qq && 
        wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && 
        apt install -y /tmp/chrome.deb -qq && 
        rm -f /tmp/chrome.deb
      "
      echo -e "''${GREEN}      ✅ Tiến trình cập nhật Chrome đang chạy ngầm.''${NC}"

      echo -e "\n''${BLUE}==================================================''${NC}"
      echo -e "''${GREEN} 🎉 HỆ THỐNG ĐÃ SẴN SÀNG! Dưới đây là thông tin kết nối:''${NC}"
      echo -e "''${BLUE}--------------------------------------------------''${NC}"
      echo -e " 🖥️  ''${CYAN}Trình duyệt (noVNC) :''${NC} http://''${TS_IP}:8080"
      echo -e " 🔌  ''${CYAN}VNC Viewer          :''${NC} ''${TS_IP}:5900"
      echo -e " 🪟  ''${CYAN}Remote Desktop (RDP):''${NC} ''${TS_IP}:3389"
      echo -e " 🔑  ''${CYAN}Mật khẩu chung      :''${NC} 123456"
      echo -e "''${BLUE}==================================================''${NC}"

      tail -f /dev/null
    '';
  };

  idx.previews = {
    enable = true;
    previews = {
      novnc = {
        manager = "web";
        command = [
          "socat" "TCP-LISTEN:$PORT,fork,reuseaddr" "TCP:127.0.0.1:8080"
        ];
      };
    };
  };
}
