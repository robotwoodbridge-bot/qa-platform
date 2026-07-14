# Mobile Runner (Android now, iOS deferred)

Android: emulator + Appium server via budtmo/docker-android, driven by a
separate Robot Framework + AppiumLibrary client container.

Caveats:
- Needs /dev/kvm on the host for real acceleration (var.enable_kvm). Works
  on a Linux host or a cloud VM with nested virtualization. Apple Silicon
  Mac hosts running Docker Desktop generally do NOT expose KVM to Linux
  containers — expect this to be slow or unreliable there.
- iOS is not scaffolded: Xcode/Simulator only run on macOS, not in a Linux
  container. Requires an external macOS runner when you're ready to add it.
