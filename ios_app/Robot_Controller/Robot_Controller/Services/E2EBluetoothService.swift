import Foundation
import Network

/// TCP-based service for E2E testing: connects to e2e-bridge on the host
/// and receives R: P: Y: telemetry; sends Command as text lines.
@Observable
final class E2EBluetoothService {

    // MARK: - BluetoothServiceProtocol

    private(set) var state: DeviceState = .disconnected
    var onAttitudeReceived: ((Attitude) -> Void)?
    var onTelemetryReceived: ((Telemetry) -> Void)?

    // MARK: - Private

    private let host: String
    private let port: UInt16
    private var connection: NWConnection?
    private var receiveBuffer = ""
    private let queue = DispatchQueue(label: "E2EBluetoothService")

    init(host: String = "127.0.0.1", port: UInt16 = 9001) {
        self.host = host
        self.port = port
    }

    // MARK: - E2E-specific

    /// Connect to the e2e-bridge TCP server (call from "Connect to E2E Bridge").
    func connect() {
        guard connection == nil else { return }
        state = .connecting
        let conn = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port), using: .tcp)
        connection = conn
        conn.stateUpdateHandler = { [weak self] newState in
            DispatchQueue.main.async {
                guard let self else { return }
                switch newState {
                case .ready:
                    self.state = .connected
                    self.scheduleReceive()
                case .failed(let err):
                    self.connection = nil
                    self.state = .error(err.localizedDescription)
                case .cancelled:
                    self.connection = nil
                    self.state = .disconnected
                case .waiting(let err):
                    self.state = .error("Waiting: \(err.localizedDescription)")
                default:
                    break
                }
            }
        }
        conn.start(queue: queue)
    }

    // MARK: - BluetoothServiceProtocol

    func send(_ command: Command) {
        guard let conn = connection, conn.state == .ready else { return }
        let data = command.data
        conn.send(content: data, completion: .contentProcessed { _ in })
    }

    func startStreaming() {
        guard let conn = connection, conn.state == .ready else { return }
        let data = Data("START\n".utf8)
        conn.send(content: data, completion: .contentProcessed { _ in })
    }

    func stopStreaming() {
        guard let conn = connection, conn.state == .ready else { return }
        let data = Data("STOP\n".utf8)
        conn.send(content: data, completion: .contentProcessed { _ in })
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
        state = .disconnected
    }

    // MARK: - Receive loop

    private func scheduleReceive() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let data = data, !data.isEmpty, let s = String(data: data, encoding: .utf8) {
                    self.receiveBuffer += s
                    self.processBuffer()
                }
                if isComplete || error != nil {
                    self.connection = nil
                    self.state = .disconnected
                    return
                }
                if self.connection != nil {
                    self.scheduleReceive()
                }
            }
        }
    }

    private func processBuffer() {
        while let idx = receiveBuffer.firstIndex(of: "\n") {
            let line = String(receiveBuffer[..<idx])
            receiveBuffer = String(receiveBuffer[receiveBuffer.index(after: idx)...])
            if let telemetry = TelemetryParser.parse(line) {
                onTelemetryReceived?(telemetry)
                onAttitudeReceived?(telemetry.attitude)
            } else if let att = AttitudeParser.parse(line) {
                onAttitudeReceived?(att)
            }
        }
    }
}

extension E2EBluetoothService: BluetoothServiceProtocol {}
