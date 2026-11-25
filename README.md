<div align="center">

# Pterodactyl VPS Egg

**Cloudflare-free fork by max-v1be.** The [original author](https://github.com/ysdragon) is ysdragon.

[![License](https://img.shields.io/github/license/max-v1be/Pterodactyl-VPS-Egg?style=for-the-badge)](https://github.com/max-v1be/Pterodactyl-VPS-Egg/blob/main/LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/max-v1be/Pterodactyl-VPS-Egg?style=for-the-badge)](https://github.com/max-v1be/Pterodactyl-VPS-Egg/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/max-v1be/Pterodactyl-VPS-Egg?style=for-the-badge)](https://github.com/max-v1be/Pterodactyl-VPS-Egg/issues)

**A powerful and lightweight Virtual Private Server (VPS) egg for Pterodactyl Panel**

*Linux guests on AMD64, ARM64, and RISCV64*

[📋 Quick Start](#-quick-start) • [🔧 Commands](#-available-custom-commands) • [🔐 SSH Setup](#-ssh-configuration) • [🖥️ GUI/VNC Setup](#%EF%B8%8F-guiremote-desktop-configuration) • [🤝 Contributing](#-contributing)

</div>

---

## ✨ Features

- 🚀 **Easy Deployment** - One-click installation and setup
- 🔧 **Customizable** - Flexible configurations for various use cases
- 🏗️ **Multi-Architecture** - Support for AMD64, ARM64, and RISCV64
- 🐧 **Linux guests** - The installer lists releases for the server architecture
- 🔌 **Port Management** - TCP/UDP support with dynamic port mapping
- 🖥️ **GUI/Remote Desktop** - VNC server with browser access via noVNC

## 🏗️ Supported Architectures

| Architecture | Status | Notes |
|-------------|--------|-------|
| amd64 | ✅ Full Support | Recommended for most users |
| arm64 | ✅ Full Support | Ideal for ARM-based servers |
| riscv64 | ✅ Full Support | Ideal for RISCV-based servers |

> [!NOTE]
> This egg supports most rootfs images for the `riscv64` architecture, including native support for Chimera Linux.

## <img width="20" height="20" src="https://www.kernel.org/theme/images/logos/favicon.png" /> Available Linux Distributions
- <img width="16" height="16" src="https://rockylinux.org/favicon.png" /> Rocky Linux
- <img width="16" height="16" src="https://almalinux.org/fav/favicon.ico" /> AlmaLinux
- <img width="16" height="16" src="https://www.centos.org/assets/img/favicon.png" /> CentOS
- <img width="16" height="16" src="https://www.oracle.com/asset/web/favicons/favicon-32.png" /> Oracle Linux
- <img width="16" height="16" src="https://netplan.readthedocs.io/en/latest/_static/favicon.png" /> Ubuntu
- <img width="16" height="16" src="https://www.debian.org/favicon.ico" /> Debian
- <img width="16" height="16" src="https://github.com/bin456789/reinstall/assets/7548515/f74b3d5b-085f-4df3-bcc9-8a9bd80bb16d" /> Kali Linux
- <img width="16" height="16" src="https://www.devuan.org/ui/img/favicon.ico" /> Devuan Linux
- <img width="16" height="16" src="https://www.alpinelinux.org/alpine-logo.ico" /> Alpine Linux
- <img width="16" height="16" src="https://archlinux.org/static/favicon.png" /> Arch Linux
- <img width="16" height="16" src="https://www.gentoo.org/assets/img/logo/gentoo-g.png" /> Gentoo Linux
- <img width="16" height="16" src="https://voidlinux.org/assets/img/favicon.png" /> Void Linux
- <img width="16" height="16" src="http://www.slackware.com/favicon.ico" /> Slackware Linux
- <img width="16" height="16" src="https://static.opensuse.org/favicon.ico" /> openSUSE
- <img width="16" height="16" src="https://fedoraproject.org/favicon.ico" /> Fedora
- <img width="16" height="16" src="https://chimera-linux.org/assets/icons/favicon48.png" /> Chimera Linux
- <img width="16" height="16" src="https://aws.amazon.com/favicon.ico" /> Amazon Linux
- <img width="16" height="16" src="https://www.plamolinux.org/images/garland_logo.jpg" /> Plamo Linux
- <img width="16" height="16" src="https://linuxmint.com/web/img/favicon.ico" /> Linux Mint
- <img width="16" height="16" src="https://en.altlinux.org/favicon.svg" /> Alt Linux
- <img width="16" height="16" src="https://www.funtoo.org/images/8/88/Latest-funtoo.png" /> Funtoo Linux
- <img width="16" height="16" src="https://www.openeuler.org/favicon.ico" /> openEuler
- <img width="16" height="16" src="https://springdale.math.ias.edu/chrome/site/puias-springdale.png" /> Springdale Linux

## 🚀 Quick Start

### 📥 Installation

Build the runtime image from this checkout and push it to a registry your Pterodactyl node can access. Replace the example image address with your own registry and tag.

```sh
docker build -t registry.example.com/your-account/pterodactyl-vps-egg:cloudflare-free .
docker push registry.example.com/your-account/pterodactyl-vps-egg:cloudflare-free
```

1. **Download the Egg**
   - Open [`egg-vps.json`](egg-vps.json) in this branch or release and use **Download raw file** on GitHub.

2. **Import to Pterodactyl**
   - Navigate to your Pterodactyl Admin Panel
   - Go to **Nests** > **Import Egg**
   - Upload the `egg-vps.json` file
   - Add your published runtime image to the egg's Docker image list

3. **Deploy Your VPS**
   - Create a new server using the VPS egg
   - Select your published runtime image. The preset image addresses in the export point to upstream builds.
   - Configure system resources (RAM, CPU, Disk, etc.)
   - Start your instance

Existing installs load the new console after an image update and restart. Put persistent startup commands in `/autorun.sh`. Available Linux releases depend on the architecture and the [Linux Containers image catalog](https://images.linuxcontainers.org/images/).

### 🖥️ First Steps

Once your VPS is running:

1. **Access the Console** - Use the Pterodactyl web console to interact with your VPS
2. **Run `help`** - View all available custom commands
3. **Customize Settings** - Configure your environment as needed

## 🔧 Available Custom Commands

The VPS egg includes several built-in commands to help you manage your server:

| Command | Description | Usage |
|---------|-------------|-------|
| `help` | Display available commands | `help` |
| `clear` / `cls` | Clear the screen | `clear` or `cls` |
| `exit` | Shutdown the server | `exit` |
| `history` | Show command history | `history` |
| `reinstall` | Reinstall the operating system | `reinstall` |
| `install-ssh` | Install the custom SSH server | `install-ssh` |
| `status` | Show the OS release, kernel, architecture, and system status | `status` |
| `backup` | Create a system backup | `backup` |
| `restore` | Restore a system backup | `restore <backup_file>` |
| `install-gui` | Install desktop environment + VNC server | `install-gui` |
| `reinstall-gui` | Reinstall the desktop environment and VNC | `reinstall-gui` |
| `start-vnc` | Start the VNC server | `start-vnc` |
| `stop-vnc` | Stop the VNC server | `stop-vnc` |
| `start-novnc` | Start noVNC for browser access | `start-novnc` |
| `stop-novnc` | Stop noVNC | `stop-novnc` |
| `gui-status` | Show GUI server status | `gui-status` |

> [!NOTE]
> All commands are available immediately after the server starts. Use `help` to view this list anytime.

> [!WARNING]
> The `reinstall` command will completely wipe all data on the server. Use with caution.

## 🔐 SSH Configuration

### Install the Custom SSH Server:
   - After installing the desired distro, use the `install-ssh` command to install our custom SSH server.

### Configuration Options

The configuration file is located at `/ssh_config.yml` and supports the following options:

### SSH Options

| Option | Description | Default |
|--------|-------------|---------|
| `port` | Port number for SSH server | `2222` |
| `user` | Username for SSH authentication | `root` |
| `password` | Password for SSH authentication (supports plain text, bcrypt hash, or argon2 hash) | `password` |
| `timeout` | Connection timeout in seconds (comment out or set to 0 to disable) | `300` |

### SFTP Options

| Option | Description | Default |
|--------|-------------|---------|
| `enable` | Enable or disable SFTP support | `true` |

> [!NOTE] 
> The `timeout` setting is optional and can be omitted from the configuration.

> [!WARNING]
> The default password "password" is insecure and **MUST** be changed immediately after installation for security reasons.

### Example `/ssh_config.yml` Configuration

Here is an example configuration file:

```yml
ssh:
  port: "2222"
  user: "root"
  password: "password"
  # timeout: 30

sftp:
  enable: true
```

## 🖥️ GUI/Remote Desktop Configuration

The VPS egg supports full GUI/remote desktop functionality with VNC server and browser-based access via noVNC.

### Install the Desktop Environment:
   - After installing the desired distro, use the `install-gui` command to install a desktop environment and VNC server.

### Available Desktop Environments

| Desktop Environment | Description | Approximate Size |
|---------------------|-------------|------------------|
| XFCE4 | Lightweight and full-featured | ~200MB |
| LXDE | Very lightweight | ~100MB |
| LXQt | Modern lightweight Qt-based | ~150MB |
| MATE | Traditional desktop experience | ~300MB |

### Supported Distributions for GUI

| Distribution | Status |
|-------------|--------|
| Debian/Ubuntu/Kali/Devuan/Linux Mint | ✅ Full Support |
| Alpine/Chimera | ✅ Full Support |
| Arch Linux | ✅ Full Support |
| Fedora | ✅ Full Support |
| Void Linux | ✅ Full Support |
| CentOS/Rocky/AlmaLinux/Oracle Linux | ❌ Not Supported |
| openSUSE | ❌ Not Supported |

### Configuration Options

The configuration file is located at `/gui_config.yml` and is automatically created during installation:

### Desktop Options

| Option | Description | Default |
|--------|-------------|---------|
| `environment` | Selected desktop environment | User selected |
| `startup_command` | Command to start the DE | Auto-detected |

### VNC Options

| Option | Description | Default |
|--------|-------------|---------|
| `port` | Port number for VNC server | `5901` |
| `password` | Password for VNC authentication | User defined |
| `resolution` | Screen resolution | `1280x720` |
| `depth` | Color depth | `24` |

### noVNC Options

| Option | Description | Default |
|--------|-------------|---------|
| `enable` | Enable noVNC web access | `true` |
| `port` | Port number for noVNC web interface | `6080` |

> [!NOTE]
> Assign the port you plan to access as a Pterodactyl allocation. For an additional allocation, enter the corresponding port number in one of the egg's `PORT 2`–`PORT 20` startup variables. Use the same port number in `/gui_config.yml`.

> [!WARNING]
> The default VNC password should be changed immediately after installation for security reasons.

### Example `/gui_config.yml` Configuration

Here is an example configuration file:

```yml
desktop:
  environment: "xfce4"
  startup_command: "startxfce4"

vnc:
  port: "5901"
  password: "your_secure_password"
  resolution: "1280x720"
  depth: "24"

novnc:
  enable: true
  port: "6080"
```

### Accessing Your Desktop

1. For a VNC client, run `start-vnc` and connect to the address and VNC port assigned by your hosting provider.
2. For browser access, run `start-novnc` and open `http://<server-ip>:<novnc_port>/vnc.html`. The guest needs the noVNC web files and `websockify`.

Browser access requires a reachable noVNC allocation. The VNC port can remain internal when you only use noVNC.

## 🤝 Contributing

Contributions are welcome! If you have any suggestions, improvements, or bug fixes, feel free to submit a pull request or open an issue.

### How to Contribute
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License
This project is open-source and available under the MIT License. See the [LICENSE](LICENSE) file for more details.
