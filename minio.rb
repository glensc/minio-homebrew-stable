class Minio < Formula
  desc "Amazon S3 compatible object storage server"
  homepage "https://github.com/minio/minio"
  url "https://github.com/minio/minio.git"
  version "20171122195546Z"
  revision 1

  url "https://dl.minio.io/server/minio/release/darwin-amd64/minio"
  sha256 "d19e4345fe87d5d254c6aefa079e9b425b7e4cc3def141b27dcdfe55e777f860"

  bottle :unneeded
  depends_on :arch => :x86_64

  def install
    bin.install "minio"
  end

  def post_install
    (var/"minio").mkpath
    (var/"log/minio").mkpath
    (etc/"minio").mkpath
  end

  plist_options :manual => "minio server"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <true/>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_bin}/minio</string>
        <string>server</string>
        <string>--config-dir=#{etc}/minio</string>
        <string>--address=:9000</string>
        <string>#{var}/minio</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>KeepAlive</key>
      <true/>
      <key>WorkingDirectory</key>
      <string>#{HOMEBREW_PREFIX}</string>
      <key>StandardErrorPath</key>
      <string>#{var}/log/minio/output.log</string>
      <key>StandardOutPath</key>
      <string>#{var}/log/minio/output.log</string>
      <key>RunAtLoad</key>
      <true/>
    </dict>
    </plist>
    EOS
  end

  test do
    (testpath/"config.json").write <<-EOS.undent
{
        "version": "14",
        "credential": {
                "accessKey": "minio",
                "secretKey": "minio123"
        },
        "region": "us-east-1",
        "browser": "on",
        "logger": {
                "console": {
                        "level": "error",
                        "enable": true
                },
                "file": {
                        "level": "error",
                        "enable": false,
                        "filename": ""
                }
        },
        "notify": {
                "redis": {
                        "1": {
                                "enable": true,
                                "address": "127.0.0.1:6379",
                                "password": "",
                                "key": "minio_events"
                        }
                }
        }
}
EOS
    minio_io = IO.popen("#{bin}/minio --config-dir #{testpath} server #{testpath}/export", :err=>[:child, :out])
    sleep 1
    Process.kill("INT", minio_io.pid)
    assert_match("getsockopt: connection refused", minio_io.read)
  end
end
