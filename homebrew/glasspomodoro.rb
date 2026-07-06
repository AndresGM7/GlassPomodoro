cask "glasspomodoro" do
  version "1.0.0"
  sha256 "050622a86ac69055bd71e963f2bcb0f1aa46d3c1051ffeb1ad0f8775438f11a3"

  url "https://github.com/AndresGM7/GlassPomodoro/releases/download/v#{version}/GlassPomodoro.zip"
  name "GlassPomodoro"
  desc "Pomodoro glassmorphism para macOS — GroovinApps"
  homepage "https://github.com/AndresGM7/GlassPomodoro"

  depends_on macos: ">= :sonoma"

  app "GlassPomodoro.app"

  # La app está firmada ad-hoc (sin notarización Apple).
  # Esto le quita la quarantine flag para que abra sin fricción:
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/GlassPomodoro.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Preferences/com.andresgm.glasspomodoro.plist",
  ]
end
