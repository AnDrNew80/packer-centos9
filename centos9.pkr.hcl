packer {
  required_plugins {
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = "~> 1"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

source "virtualbox-iso" "centos9" {
  vm_name                = "packer-centos9-stream2"
  iso_url                = "https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso"
  iso_checksum           = "sha256:f1db7874a591d59ded57a5dffa3175f9967f7b3b69ce2352ff51914f6aee2180"
  guest_os_type          = "RedHat_64"
  disk_size              = 20000
  memory                 = 1024
  cpus                   = 1
  headless               = false
  http_directory         = "http"
  http_port_min          = 9000
  http_port_max          = 9090
  output_directory       = "D:/packer_output/centos9new"
  ssh_username           = "vagrant"
  ssh_password           = "YOURPASSWORD"
  ssh_timeout            = "240m"
  ssh_handshake_attempts = 200
  shutdown_command       = "echo 'vagrant' | sudo -S shutdown -P now"
  boot_wait              = "15s"

  boot_command = [
    "<tab><wait>",
	"inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter>"
    #if option above will not work try: "inst.text inst.ks=http://YOURLOCALIP:{{ .HTTPPort }}/ks.cfg<enter>"
  ]

  vboxmanage = [
	["modifyvm", "{{ .Name }}", "--nic1", "nat"],
    ["modifyvm", "{{.Name}}", "--nic1", "bridged"],
    ["modifyvm", "{{.Name}}", "--bridgeadapter1", "Realtek PCIe GbE Family Controller"]
  ]
}

build {
  sources = ["source.virtualbox-iso.centos9"]

  provisioner "shell" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y openssh-server openssh-clients sudo curl wget net-tools rsync",
      "sudo systemctl enable --now sshd",
      "sudo usermod -aG wheel vagrant",
      "echo 'vagrant ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/vagrant > /dev/null",
      "sudo chmod 0440 /etc/sudoers.d/vagrant",
      "sudo dnf clean all",
      "sudo rm -rf /tmp/* /var/cache/* /var/lib/cloud/instances/*",
      "sudo rm -f /var/log/wtmp /var/log/lastlog /etc/ssh/ssh_host_*",
      "sudo find /var/log -type f -name '*.log' -exec truncate -s 0 {} +",
      "history -c"
    ]
  }

  post-processor "vagrant" {
    output = "centos9-stream-base.box"
  }
}
