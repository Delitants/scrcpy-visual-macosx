import AppKit
import Foundation
import SwiftUI

private enum Palette {
    static let background = Color(red: 0.08, green: 0.11, blue: 0.13)
    static let panel = Color(red: 0.14, green: 0.19, blue: 0.21)
    static let button = Color(red: 0.22, green: 0.28, blue: 0.29)
    static let accent = Color(red: 1.0, green: 0.64, blue: 0.24)
}

final class RemoteController: ObservableObject {
    @Published var host = UserDefaults.standard.string(forKey: "host") ?? ""
    @Published var status = "Enter your Fire TV address to connect."
    @Published var connected = false

    private let work = DispatchQueue(label: "com.delitants.FireTVRemoteMac.adb")
    private let serverPort = "5038"
    private var endpoint = ""
    private var mirrorProcess: Process?

    private var resourceDirectory: URL {
        Bundle.main.resourceURL ?? URL(fileURLWithPath: "/")
    }

    private var adbURL: URL? {
        let candidates = [
            resourceDirectory.appendingPathComponent("scrcpy/adb"),
            URL(fileURLWithPath: "/opt/homebrew/bin/adb"),
            URL(fileURLWithPath: "/usr/local/bin/adb")
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    private var environment: [String: String] {
        var values = ProcessInfo.processInfo.environment
        values["ADB_SERVER_PORT"] = serverPort
        let privateHome = resourceDirectory.appendingPathComponent("Private/home")
        let key = privateHome.appendingPathComponent(".android/adbkey")
        if FileManager.default.fileExists(atPath: key.path) {
            values["HOME"] = privateHome.path
            values["ADB_VENDOR_KEYS"] = key.path
        }
        return values
    }

    private func runADB(_ arguments: [String]) -> (Int32, String) {
        guard let adb = adbURL else {
            return (-1, "ADB is missing. Rebuild with the official scrcpy archive.")
        }
        let process = Process()
        let pipe = Pipe()
        process.executableURL = adb
        process.arguments = arguments
        process.environment = environment
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let output = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            return (process.terminationStatus, output)
        } catch {
            return (-1, error.localizedDescription)
        }
    }

    func connect() {
        let address = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else {
            status = "Enter a device address first."
            return
        }
        let target = address.contains(":") ? address : "\(address):5555"
        connected = false
        status = "Connecting to \(target)..."
        UserDefaults.standard.set(address, forKey: "host")
        work.async { [self] in
            let result = runADB(["connect", target])
            let state = runADB(["-s", target, "get-state"])
            DispatchQueue.main.async {
                if state.0 == 0 && state.1 == "device" {
                    self.endpoint = target
                    self.connected = true
                    self.status = "Connected to \(target)"
                } else {
                    self.status = result.1.isEmpty ? state.1 : result.1
                }
            }
        }
    }

    func send(_ keycode: Int) {
        guard connected else { return }
        let target = endpoint
        work.async { [self] in
            let result = runADB(["-s", target, "shell", "input", "keyevent", String(keycode)])
            if result.0 != 0 {
                DispatchQueue.main.async {
                    self.status = result.1.isEmpty ? "Key command failed." : result.1
                }
            }
        }
    }

    func openMirror() {
        guard connected else { return }
        let folder = resourceDirectory.appendingPathComponent("scrcpy")
        let executable = folder.appendingPathComponent("scrcpy")
        guard FileManager.default.isExecutableFile(atPath: executable.path) else {
            status = "scrcpy is missing from this app bundle."
            return
        }
        if mirrorProcess?.isRunning == true {
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let process = Process()
        process.executableURL = executable
        process.currentDirectoryURL = folder
        process.arguments = ["--serial", endpoint, "--no-audio", "--window-title", "Fire TV Mirror"]
        var values = environment
        values["ADB"] = folder.appendingPathComponent("adb").path
        values["SCRCPY_SERVER_PATH"] = folder.appendingPathComponent("scrcpy-server").path
        process.environment = values
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            mirrorProcess = process
            status = "Opened scrcpy mirror window."
        } catch {
            status = "Could not open scrcpy: \(error.localizedDescription)"
        }
    }
}

private struct RemoteKeyButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 19, weight: .semibold))
                Text(label).font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.white)
            .frame(width: 86, height: 68)
            .background(Palette.button, in: RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
        .help(label)
    }
}

private struct RemoteView: View {
    @ObservedObject var remote: RemoteController

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FIRE TV").font(.system(size: 14, weight: .bold, design: .rounded)).tracking(4)
                    Text("REMOTE").font(.system(size: 33, weight: .black, design: .rounded)).tracking(1)
                }
                Spacer()
                Circle()
                    .fill(remote.connected ? Color.green : Palette.accent)
                    .frame(width: 12, height: 12)
                    .help(remote.connected ? "Connected" : "Disconnected")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("DEVICE ADDRESS").font(.system(size: 11, weight: .bold)).tracking(2)
                HStack {
                    TextField("192.168.1.10", text: $remote.host)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { remote.connect() }
                    Button("Connect") { remote.connect() }
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.accent)
                }
                Text(remote.status)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Palette.panel, in: RoundedRectangle(cornerRadius: 18))

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    RemoteKeyButton(symbol: "house.fill", label: "Home") { remote.send(3) }
                    RemoteKeyButton(symbol: "arrow.uturn.backward", label: "Back") { remote.send(4) }
                    RemoteKeyButton(symbol: "line.3.horizontal", label: "Menu") { remote.send(82) }
                }

                HStack(spacing: 10) {
                    Spacer().frame(width: 86, height: 68)
                    RemoteKeyButton(symbol: "chevron.up", label: "Up") { remote.send(19) }
                    Spacer().frame(width: 86, height: 68)
                }
                HStack(spacing: 10) {
                    RemoteKeyButton(symbol: "chevron.left", label: "Left") { remote.send(21) }
                    RemoteKeyButton(symbol: "circle.inset.filled", label: "Select") { remote.send(23) }
                    RemoteKeyButton(symbol: "chevron.right", label: "Right") { remote.send(22) }
                }
                HStack(spacing: 10) {
                    Spacer().frame(width: 86, height: 68)
                    RemoteKeyButton(symbol: "chevron.down", label: "Down") { remote.send(20) }
                    Spacer().frame(width: 86, height: 68)
                }

                HStack(spacing: 10) {
                    RemoteKeyButton(symbol: "speaker.minus.fill", label: "Volume -") { remote.send(25) }
                    RemoteKeyButton(symbol: "playpause.fill", label: "Play/Pause") { remote.send(85) }
                    RemoteKeyButton(symbol: "speaker.plus.fill", label: "Volume +") { remote.send(24) }
                }
            }
            .disabled(!remote.connected)
            .opacity(remote.connected ? 1 : 0.48)

            Button(action: remote.openMirror) {
                Label("Open screen mirror", systemImage: "rectangle.on.rectangle")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Palette.accent)
            .disabled(!remote.connected)

            Text("Authorized ADB required  |  No key is in the public build")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(24)
        .frame(width: 380)
        .foregroundStyle(.white)
        .background(Palette.background)
        .onAppear {
            if !remote.host.isEmpty { remote.connect() }
        }
    }
}

@main
struct FireTVRemoteApp: App {
    @StateObject private var remote = RemoteController()

    var body: some Scene {
        WindowGroup("Fire TV Remote") {
            RemoteView(remote: remote)
        }
        .windowResizability(.contentSize)
    }
}
