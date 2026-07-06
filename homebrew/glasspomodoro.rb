cask "glasspomodoro" do
  version "1.0.0"
  sha256 "REEMPLAZAR_CON_SHA256_DEL_ZIP"

  url "https://github.com/TUUSUARIO/GlassPomodoro/releases/download/v#{version}/GlassPomodoro.zip"
  name "GlassPomodoro"
  desc "Pomodoro glassmorphism para macOS — GroovinApps"
  homepage "https://github.com/TUUSUARIO/GlassPomodoro"

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
