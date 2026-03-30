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
        echo -e "''${YELLOW}[1/4] 🧹 Đang tối ưu không gian lưu trữ...''${NC}"
        # Chỉ xóa các thư mục rác thật sự, không xóa bừa bãi tránh treo script
        rm -rf /home/user/.gradle /home/user/.emu /home/user/.cache /home/user/.local/share/Trash
        touch /home/user/.cleanup_done
        echo -e "''${GREEN}      ✅ Đã dọn dẹp xong rác hệ thống!''${NC}"
      else
        echo -e "''${GREEN}[1/4] 🧹 Hệ thống đã sạch sẽ.''${NC}"
      fi

      echo -e "''${YELLOW}[2/4] 🌐 Thiết lập Tailscale...''${NC}"
      sudo tailscaled --tun=userspace-networking --socks5-server=localhost:1055 > /dev/null 2>&1 &
      sleep 5
      sudo tailscale up --authkey=tskey-auth-kLFsqw5jzS11CNTRL-HLgERv9ZdVP4bV1kUjFHVP6BJ1SdC8Jt --hostname=idx-zun-cloud --accept-routes > /dev/null 2>&1 || true
      
      TS_IP=$(tailscale ip -4 2>/dev/null || echo "Chưa lấy được IP")
      echo -e "''${GREEN}      ✅ Tailscale IP: ''${CYAN}''${TS_IP}''${NC}"

      echo -e "''${YELLOW}[3/4] 🐳 Khởi động Ubuntu Desktop (Docker)...''${NC}"
      if ! docker ps -a --format '{{.Names}}' | grep -qx 'ubuntu-novnc'; then
        docker run --name ubuntu-novnc \
          --restart always \
          --shm-size 1g -d \
          --cap-add=SYS_ADMIN \
          -p 8080:10000 -p 5900:5900 -p 3389:3389 \
          -e VNC_PASSWD=123456 \
          -e SCREEN_WIDTH=1280 -e SCREEN_HEIGHT=720 \
          thuonghai2711/ubuntu-novnc-pulseaudio:22.04 > /dev/null
        echo -e "''${GREEN}      ✅ Đã tạo mới container thành công!''${NC}"
      else
        docker start ubuntu-novnc > /dev/null 2>&1 || true
        echo -e "''${GREEN}      ✅ Container đã hoạt động!''${NC}"
      fi

      echo -e "''${YELLOW}[4/4] 🌍 Cập nhật Google Chrome ngầm...''${NC}"
      docker exec -d ubuntu-novnc bash -c "apt update -qq && apt install -y wget -qq && wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && apt install -y /tmp/chrome.deb -qq && rm -f /tmp/chrome.deb" &
      echo -e "''${GREEN}      ✅ Đang tải Chrome trong background.''${NC}"

      echo -e "\n''${BLUE}==================================================''${NC}"
      echo -e "''${GREEN} 🎉 ZUN CLOUD SẴN SÀNG!''${NC}"
      echo -e "''${BLUE}--------------------------------------------------''${NC}"
      echo -e " 🖥️  ''${CYAN}noVNC (Web)  :''${NC} http://''${TS_IP}:8080"
      echo -e " 🔌  ''${CYAN}VNC Viewer   :''${NC} ''${TS_IP}:5900"
      echo -e " 🔑  ''${CYAN}Password     :''${NC} 123456"
      echo -e "''${BLUE}==================================================''${NC}"

      tail -f /dev/null
    '';
  };

  idx.previews = {
    enable = true;
    previews = {
      novnc = {
        manager = "web";
        command = [ "socat" "TCP-LISTEN:$PORT,fork,reuseaddr" "TCP:127.0.0.1:8080" ];
      };
    };
  };
}
