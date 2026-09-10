//
//  DeviceService.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 24/10/2024.
//

import Combine
import CoreBluetooth
import OrderedCollections
import OSLog

enum DevicesState {
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn

    init(_ state: CBManagerState) {
        switch state {
        case .unknown: self = .unknown
        case .resetting: self = .resetting
        case .unsupported: self = .unsupported
        case .unauthorized: self = .unauthorized
        case .poweredOff: self = .poweredOff
        case .poweredOn: self = .poweredOn
        default: self = .unknown
        }
    }
}

struct Device: Identifiable {
    enum State {
        case connecting
        case connected
        case disconnecting
        case readyToPair
        case pairing
        case error
    }

    struct AdvertisementData {
        typealias ProtocolVersion = UInt8

        struct Tag21OptionSet: OptionSet {
            let rawValue: UInt8

            static let wirelessPowerOnEnabled = Tag21OptionSet(rawValue: 0x80)
            static let cameraOn = Tag21OptionSet(rawValue: 0x40)
            static let wifiHandoverSupported = Tag21OptionSet(rawValue: 0x20)
            static let wifiHandoverEnabled = Tag21OptionSet(rawValue: 0x10)
        }

        struct Tag22OptionSet: OptionSet {
            let rawValue: UInt8

            static let pairingSupported = Tag22OptionSet(rawValue: 0x80)
            static let pairingEnabled = Tag22OptionSet(rawValue: 0x40)
            static let locationSupported = Tag22OptionSet(rawValue: 0x20)
            static let locationEnabled = Tag22OptionSet(rawValue: 0x10)
            static let remoteControlEnabled = Tag22OptionSet(rawValue: 0x04)
            static let poweredOn = Tag22OptionSet(rawValue: 0x01)
        }

        struct Tag23OptionSet: OptionSet {
            let rawValue: UInt8
        }

        var isProtocolCompatible: Bool {
            [0x64, 0x65].contains(protocolVersion)
        }

        var isPoweredOn: Bool {
            tag22.contains(.poweredOn)
        }

        var isRemoteControlEnabled: Bool {
            tag22.contains(.remoteControlEnabled)
        }

        var isPairingSupported: Bool {
            tag22.contains(.pairingSupported)
        }

        var isPairingEnabled: Bool {
            tag22.contains(.pairingEnabled)
        }

        var isLocationSupported: Bool {
            tag22.contains(.locationSupported)
        }

        var isLocationEnabled: Bool {
            tag22.contains(.locationEnabled)
        }

        let isSony: Bool
        let isCamera: Bool
        let protocolVersion: ProtocolVersion
        private let tag21: Tag21OptionSet
        private let tag22: Tag22OptionSet
        private let tag23: Tag22OptionSet
        private let data: Data

        init?(from data: Data?) {
            guard let data, data.count == 22 else { return nil }

            isSony = data.subdata(in: 0 ..< 2) == Data([0x2D, 0x01])
            isCamera = data.subdata(in: 2 ..< 4) == Data([0x03, 0x00])
            protocolVersion = data[4]

            tag21 = if let index = data.dropFirst(8).firstIndex(of: 0x21) {
                Tag21OptionSet(rawValue: data[index.advanced(by: 1)])
            } else {
                Tag21OptionSet(rawValue: 0)
            }
            tag22 = if let index = data.dropFirst(8).firstIndex(of: 0x22) {
                Tag22OptionSet(rawValue: data[index.advanced(by: 1)])
            } else {
                Tag22OptionSet(rawValue: 0)
            }
            tag23 = if let index = data.dropFirst(8).firstIndex(of: 0x23) {
                Tag22OptionSet(rawValue: data[index.advanced(by: 1)])
            } else {
                Tag22OptionSet(rawValue: 0)
            }

            self.data = data
        }
    }

    var id: UUID { identifier }

    let identifier: UUID
    var advertisementData: AdvertisementData?
    var name: String?
    var displayName: String?
    var state: State
    var batteryLevel: UInt8?
    var locationInfoLinkEnabledInSession: Bool?

    init(peripheral: CBPeripheral,
         advertisementData: AdvertisementData?,
         state: State,
         batteryLevel: UInt8? = nil,
         locationInfoLinkEnabledInSession: Bool? = nil)
    {
        self.init(identifier: peripheral.identifier,
                  advertisementData: advertisementData,
                  name: peripheral.name,
                  displayName: peripheral.displayName,
                  state: state,
                  batteryLevel: batteryLevel,
                  locationInfoLinkEnabledInSession: locationInfoLinkEnabledInSession)
    }

    init(identifier: UUID,
         advertisementData: AdvertisementData?,
         name: String?,
         displayName: String?,
         state: State,
         batteryLevel: UInt8? = nil,
         locationInfoLinkEnabledInSession: Bool? = nil)
    {
        self.identifier = identifier
        self.advertisementData = advertisementData
        self.name = name
        self.displayName = displayName
        self.state = state
        self.batteryLevel = batteryLevel
        self.locationInfoLinkEnabledInSession = locationInfoLinkEnabledInSession
    }
}

@MainActor class DeviceService: NSObject, ObservableObject {
    private let logger = Logger(category: "DeviceService")

    private static let restoreIdentifier = "com.bc.locationalpha.cb"

    @Published private(set) var state: DevicesState = .unknown
    @Published private(set) var devices: OrderedDictionary<CBPeripheral, Device> = [:]
    @Published private(set) var knownDevices: OrderedDictionary<CBPeripheral, KnownDevice> = [:]

    var connected: AnyPublisher<Device, Never> {
        _connected.eraseToAnyPublisher()
    }

    var disconnected: AnyPublisher<Device, Never> {
        _disconnected.eraseToAnyPublisher()
    }

    private var _connected: PassthroughSubject<Device, Never> = .init()
    private var _disconnected: PassthroughSubject<Device, Never> = .init()

    private var centralManager: CBCentralManager?
    private var restoredPeripherals: [CBPeripheral] = []

    private let database: Database

    init(database: Database) {
        self.database = database
    }

    func start() {
        restoredPeripherals = []

        centralManager = CBCentralManager(delegate: self,
                                          queue: .main,
                                          options: [CBCentralManagerOptionRestoreIdentifierKey: DeviceService.restoreIdentifier])
    }

    func stop() {
        centralManager?.stopScan()

        for (peripheral, _) in devices {
            devices.update(peripheral) {
                $0.state = .disconnecting
            }
            centralManager?.cancelPeripheralConnection(peripheral)
        }

        if devices.isEmpty {
            for (peripheral, _) in knownDevices {
                centralManager?.cancelPeripheralConnection(peripheral)
            }
            knownDevices.removeAll()
            for peripheral in restoredPeripherals {
                centralManager?.cancelPeripheralConnection(peripheral)
            }
            restoredPeripherals.removeAll()
            centralManager = nil
        }
    }

    func preconnect() {
        guard let centralManager else {
            return
        }

        preconnect(centralManager)
    }

    func connectAndPair(device: Device) {
        let element = devices.first { $0.value.identifier == device.identifier }

        guard let peripheral = element?.key,
              let device = element?.value,
              device.state == .readyToPair,
              peripheral.state == .disconnected
        else {
            return
        }

        devices.update(peripheral) {
            $0.state = .pairing
        }

        centralManager?.connect(peripheral, options: nil)
    }

    func write(location: Location, date: Date, timeZone: TimeZone) {
        logger.info("Sending location...")

        for (peripheral, device) in devices {
            guard device.state == .connected,
                  peripheral.state == .connected
            else {
                logger.warning("Not ready to receive location data from \(peripheral.identifier, privacy: .public)")
                continue
            }

            let locationData = CameraLocationData(latitude: location.latitude,
                                                  longitude: location.longitude,
                                                  date: date,
                                                  timeZone: timeZone).data

            guard let locationCharacteristic = peripheral.locationServiceWriteLocationCharacteristic else {
                logger.warning("Receiving location data not supported for \(peripheral.identifier, privacy: .public)")
                continue
            }

            peripheral.writeValue(locationData, for: locationCharacteristic, type: .withResponse)
        }

        logger.info("Sending location complete")
    }

    func readBatteryLevel() {
        logger.info("Reading battery level...")

        for (peripheral, device) in devices {
            guard device.state == .connected,
                  peripheral.state == .connected
            else {
                logger.warning("Not ready to read battery level from \(peripheral.identifier, privacy: .public)")
                continue
            }

            guard let statusCharacteristic = peripheral.controlServiceBatteryLevelReadCharacteristic else {
                logger.info("Reading battery level not supported for \(peripheral.identifier, privacy: .public)")
                continue
            }

            peripheral.readValue(for: statusCharacteristic)
        }

        logger.info("Reading battery level complete")
    }
}

private extension DeviceService {
    func scan(_ central: CBCentralManager) {
        central.scanForPeripherals(withServices: [.generalAccessUuid])
        logger.info("Scanning...")
    }

    func preconnect(_ central: CBCentralManager) {
        for (peripheral, _) in knownDevices where peripheral.state == .connecting {
            central.cancelPeripheralConnection(peripheral)
        }

        knownDevices.removeAll()

        let knownDevices = try! database.read(predicate: #Predicate { $0.quickConnect == true })
        let peripherals = central.retrievePeripherals(withIdentifiers: knownDevices.map(\.identifier))

        logger.info("Preconnecting...")

        for knownDevice in knownDevices {
            let peripheral = peripherals.first { $0.identifier == knownDevice.identifier }
            guard let peripheral else {
                continue
            }

            self.knownDevices[peripheral] = knownDevice

            central.connect(peripheral)

            logger.info("Preconnecting \(knownDevice.name ?? "-", privacy: .public), \(peripheral.identifier, privacy: .public)...")
        }
    }
}

extension DeviceService: @preconcurrency CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            logger.info("Powered on")
            preconnect(central)
            scan(central)
        case .poweredOff:
            logger.warning("Powered off")
        case .resetting:
            logger.warning("Resetting...")
        case .unauthorized:
            logger.warning("Unauthorized")
        case .unsupported:
            logger.warning("Unsupported")
        case .unknown:
            logger.warning("Unknown")
        @unknown default:
            logger.info("Unknown other")
        }

        state = .init(central.state)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi _: NSNumber) {
        guard let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
              let advertisementData = Device.AdvertisementData(from: data),
              advertisementData.isSony,
              advertisementData.isCamera
        else {
            return
        }

        logger.info("Encountered \(peripheral.name ?? "-", privacy: .public), \(peripheral.identifier, privacy: .public) with data \(data.hexString)")

        devices.update(peripheral) {
            $0.advertisementData = advertisementData
        }

        let allow = switch devices[peripheral]?.state {
        case .readyToPair, .none: true
        case .pairing, .connecting, .connected, .disconnecting, .error: false
        }

        guard allow else {
            logger.info("\(peripheral.identifier, privacy: .public) already in the list...")
            return
        }

        guard advertisementData.isProtocolCompatible else {
            logger.info("\(peripheral.identifier, privacy: .public) is incompatible")
            return
        }

        guard advertisementData.isPoweredOn else {
            logger.info("\(peripheral.identifier, privacy: .public) is powered off")
            return
        }

        if advertisementData.isPairingSupported, advertisementData.isPairingEnabled {
            logger.info("\(peripheral.identifier, privacy: .public) is ready to pair")
            devices.updateOrAppend(peripheral, advertising: advertisementData, state: .readyToPair)
        } else {
            logger.info("\(peripheral.identifier, privacy: .public) is ready to connect")
            devices.updateOrAppend(peripheral, advertising: advertisementData, state: .connecting)
            central.connect(peripheral)
        }
    }

    func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("Connected to \(peripheral.identifier, privacy: .public)")

        if devices[peripheral] == nil, knownDevices[peripheral] != nil {
            devices.updateOrAppend(peripheral, advertising: nil, state: .connecting)
        }

        restoredPeripherals.removeAll(where: { $0.identifier == peripheral.identifier })

        peripheral.delegate = self
        peripheral.discoverServices([
            .controlServiceUuid,
            .locationServiceUuid,
            .pairingServiceUuid,
            .remoteControlServiceUuid,
        ])
    }

    func centralManager(_: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        logger.error("Failed to connect to \(peripheral.identifier, privacy: .public) with error \(String(describing: error), privacy: .public)")

        devices.removeAll(withPeripheral: peripheral)
        restoredPeripherals.removeAll(where: { $0.identifier == peripheral.identifier })
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        if devices[peripheral]?.state == .pairing {
            try! database.upsert(.init(peripheral: peripheral)) {
                $0.lastSeen = .now
            }
            preconnect(central)
        }

        if let device = devices[peripheral], device.state == .connected {
            _disconnected.send(device)
            preconnect(central)
        }

        restoredPeripherals.removeAll(where: { $0.identifier == peripheral.identifier })

        logger.info("Disconnected from \(peripheral.identifier, privacy: .public) with error: \(String(describing: error), privacy: .public)")

        peripheral.delegate = nil
        devices.removeAll(withPeripheral: peripheral)

        if !central.isScanning, devices.isEmpty {
            for (peripheral, _) in knownDevices {
                centralManager?.cancelPeripheralConnection(peripheral)
            }
            knownDevices.removeAll()
            for peripheral in restoredPeripherals {
                centralManager?.cancelPeripheralConnection(peripheral)
            }
            restoredPeripherals.removeAll()
            centralManager = nil
        }
    }

    func centralManager(_: CBCentralManager, willRestoreState dict: [String: Any]) {
        logger.info("Restoring state...")

        let restoredPeripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []

        for peripheral in restoredPeripherals {
            logger.info("Restoring connection to  \(peripheral.name ?? "-", privacy: .public), \(peripheral.identifier, privacy: .public)...")
            peripheral.delegate = self
        }

        self.restoredPeripherals = restoredPeripherals
    }
}

extension DeviceService: @preconcurrency CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        logger.info("Discovered services for \(peripheral.identifier, privacy: .public)")

        guard error == nil else {
            logger.error("Error discovering services for \(peripheral.identifier.uuidString): \(String(describing: error), privacy: .public)")
            devices.update(peripheral) {
                $0.state = .error
            }
            centralManager?.cancelPeripheralConnection(peripheral)
            return
        }

        guard let controlService = peripheral.controlService,
              let locationService = peripheral.locationService,
              let pairingService = peripheral.pairingService,
              let remoteControlService = peripheral.remoteControlService
        else {
            logger.error("\(peripheral.identifier, privacy: .public) does not support necessary services")
            devices.update(peripheral) {
                $0.state = .error
            }
            centralManager?.cancelPeripheralConnection(peripheral)
            return
        }

        peripheral.discoverCharacteristics([
            .controlServiceBatteryLevelReadCharacteristicUuid,
        ],
        for: controlService)

        peripheral.discoverCharacteristics([
            .locationServiceNotifyStatusCharacteristicUuid,
            .locationServiceReadStatusCharacteristicUuid,
            .locationServiceWriteLocationCharacteristicUuid,
            .locationServiceReadWriteControlCharacteristicUuid,
            .locationServiceReadWriteLocationSyncCharacteristicUuid,
            .locationServiceReadWriteTimeSyncCharacteristicUuid,
            .locationServiceReadWriteAreaSyncCharacteristicUuid,
        ],
        for: locationService)

        peripheral.discoverCharacteristics([
            .pairingServiceWriteCommandCharacteristicUuid,
        ],
        for: pairingService)

        peripheral.discoverCharacteristics([
            .remoteControlServiceNotifyCharacteristicUuid,
        ],
        for: remoteControlService)
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        logger.info("\(peripheral.identifier, privacy: .public) invalidated \(invalidatedServices.count, privacy: .public) services")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        logger.info("Discovered characteristics for \(peripheral.identifier, privacy: .public) service: \(service.uuid, privacy: .public) with error \(String(describing: error), privacy: .public)")

        guard error == nil else {
            logger.error("Error while discoring characteristics for \(peripheral.identifier.uuidString): \(String(describing: error), privacy: .public)")
            devices.update(peripheral) {
                $0.state = .error
            }
            centralManager?.cancelPeripheralConnection(peripheral)
            return
        }

        switch service {
        case peripheral.controlService:
            break
        case peripheral.locationService:
            guard devices[peripheral]?.state == .connecting else {
                return
            }

            guard peripheral.locationServiceNotifyStatusCharacteristic != nil,
                  peripheral.locationServiceReadStatusCharacteristic != nil,
                  peripheral.locationServiceWriteLocationCharacteristic != nil
            else {
                logger.error("\(peripheral.identifier, privacy: .public) does not support location service")
                devices.update(peripheral) {
                    $0.state = .error
                }
                centralManager?.cancelPeripheralConnection(peripheral)
                return
            }

            if let locationServiceReadStatusCharacteristic = peripheral.locationServiceReadStatusCharacteristic {
                peripheral.readValue(for: locationServiceReadStatusCharacteristic)
            }
        case peripheral.pairingService:
            guard devices[peripheral]?.state == .pairing else {
                return
            }

            guard peripheral.pairingServiceWriteCommandCharacteristic != nil else {
                logger.error("\(peripheral.identifier, privacy: .public) does not support pairing service")
                devices.update(peripheral) {
                    $0.state = .error
                }
                centralManager?.cancelPeripheralConnection(peripheral)
                return
            }

            if let pairingWrite = peripheral.pairingServiceWriteCommandCharacteristic {
                peripheral.writeValue(CameraPairingData(withDisconnect: false).data, for: pairingWrite, type: .withResponse)
            }

            return
        case peripheral.remoteControlService:
            guard devices[peripheral]?.state == .connecting else {
                return
            }

            guard peripheral.remoteControlServiceNotifyCharacteristic != nil else {
                logger.error("\(peripheral.identifier, privacy: .public) does not support remote control service")
                devices.update(peripheral) {
                    $0.state = .error
                }
                centralManager?.cancelPeripheralConnection(peripheral)
                return
            }
        default:
            logger.error("Discovered unknown service \(service.uuid, privacy: .public) on \(peripheral.identifier, privacy: .public)")
            devices.update(peripheral) {
                $0.state = .error
            }
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard error == nil else {
            logger.error("Error while updating notification state value for \(peripheral.identifier, privacy: .public), characteristic \(characteristic.uuid, privacy: .public): \(String(describing: error), privacy: .public)")
            devices.update(peripheral) {
                $0.state = .error
            }
            centralManager?.cancelPeripheralConnection(peripheral)
            return
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if characteristic == peripheral.pairingServiceWriteCommandCharacteristic, devices[peripheral]?.state == .pairing {
            logger.info("Pairing request sent to \(peripheral.identifier, privacy: .public) with error \(String(describing: error), privacy: .public)")
            centralManager?.cancelPeripheralConnection(peripheral)
            return
        }

        guard error == nil else {
            logger.error("Error while writing value to \(peripheral.identifier, privacy: .public) characteristic \(characteristic.uuid, privacy: .public): \(String(describing: error), privacy: .public)")
            devices.update(peripheral) {
                $0.state = .error
            }
            centralManager?.cancelPeripheralConnection(peripheral)
            return
        }

        logger.info("Recived value from \(peripheral.identifier, privacy: .public) characteristic: \(characteristic.uuid, privacy: .public) with error \(String(describing: error), privacy: .public)")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard error == nil else {
            logger.error("Error while updating value for \(peripheral.identifier, privacy: .public) on characteristic: \(characteristic.uuid, privacy: .public): \(String(describing: error), privacy: .public)")
            devices.update(peripheral) {
                $0.state = .error
            }
            centralManager?.cancelPeripheralConnection(peripheral)
            return
        }

        switch characteristic {
        case peripheral.controlServiceBatteryLevelReadCharacteristic:
            guard let data = characteristic.value else {
                return
            }

            devices.update(peripheral) {
                $0.batteryLevel = data[13]
            }
        case peripheral.locationServiceNotifyStatusCharacteristic:
            guard let data = characteristic.value else {
                return
            }

            devices.update(peripheral) {
                let appBasedControlActive = data[2].optionSet.contains(.bit0)
                let cameraBasedControlEnabled = data[2].optionSet.contains(.bit1)
                let appBasedControlEnabled = data[2].optionSet.contains(.bit2)
                let locationInfoLink = data[3].optionSet.contains(.bit0)

                if appBasedControlActive {
                    if appBasedControlEnabled {
                        $0.locationInfoLinkEnabledInSession = !locationInfoLink
                    } else if cameraBasedControlEnabled {
                        $0.locationInfoLinkEnabledInSession = !locationInfoLink
                    } else {
                        $0.locationInfoLinkEnabledInSession = nil
                    }
                } else {
                    if cameraBasedControlEnabled {
                        $0.locationInfoLinkEnabledInSession = locationInfoLink
                    } else {
                        $0.locationInfoLinkEnabledInSession = nil
                    }
                }
            }
        case peripheral.locationServiceReadStatusCharacteristic:
            guard let device = devices[peripheral], device.state == .connecting else {
                return
            }

            devices.update(peripheral) {
                $0.state = .connected
            }

            _connected.send(device)

            try! database.upsert(.init(peripheral: peripheral)) {
                $0.lastSeen = .now
            }

            if let locationServiceNotifyStatusCharacteristicUuid = peripheral.locationServiceNotifyStatusCharacteristic {
                peripheral.setNotifyValue(true, for: locationServiceNotifyStatusCharacteristicUuid)
            }

            guard let controlCharacteristicService = peripheral.locationServiceReadWriteControlCharacteristic,
                  let locationSyncCharacteristic = peripheral.locationServiceReadWriteLocationSyncCharacteristic,
                  let timeSyncCharacteristic = peripheral.locationServiceReadWriteTimeSyncCharacteristic,
                  let areaSyncCharacteristic = peripheral.locationServiceReadWriteAreaSyncCharacteristic
            else {
                logger.info("\(peripheral.identifier, privacy: .public) needs to enable location services on camera")
                return
            }

            peripheral.writeBool(true, for: controlCharacteristicService, type: .withResponse)
            peripheral.writeBool(true, for: locationSyncCharacteristic, type: .withResponse)
            peripheral.writeBool(true, for: timeSyncCharacteristic, type: .withResponse)
            peripheral.writeBool(true, for: areaSyncCharacteristic, type: .withResponse)
        default:
            break
        }
    }
}

@MainActor private extension CBUUID {
    static let generalAccessUuid = CBUUID(string: "1800")
    static let controlServiceUuid = CBUUID(string: "8000CC00-CC00-FFFF-FFFF-FFFFFFFFFFFF")
    static let controlServiceBatteryLevelReadCharacteristicUuid = CBUUID(string: "0xCC10")
    static let locationServiceUuid = CBUUID(string: "8000DD00-DD00-FFFF-FFFF-FFFFFFFFFFFF")
    static let locationServiceNotifyStatusCharacteristicUuid = CBUUID(string: "0xDD01")
    static let locationServiceWriteLocationCharacteristicUuid = CBUUID(string: "0xDD11")
    static let locationServiceReadStatusCharacteristicUuid = CBUUID(string: "0xDD21")
    static let locationServiceReadWriteControlCharacteristicUuid = CBUUID(string: "0xDD30")
    static let locationServiceReadWriteLocationSyncCharacteristicUuid = CBUUID(string: "0xDD31")
    static let locationServiceReadWriteTimeSyncCharacteristicUuid = CBUUID(string: "0xDD32")
    static let locationServiceReadWriteAreaSyncCharacteristicUuid = CBUUID(string: "0xDD33")
    static let pairingServiceUuid = CBUUID(string: "8000EE00-EE00-FFFF-FFFF-FFFFFFFFFFFF")
    static let pairingServiceWriteCommandCharacteristicUuid = CBUUID(string: "0xEE01")
    static let remoteControlServiceUuid = CBUUID(string: "8000FF00-FF00-FFFF-FFFF-FFFFFFFFFFFF")
    static let remoteControlServiceCommandCharacteristicUuid = CBUUID(string: "0xFF01")
    static let remoteControlServiceNotifyCharacteristicUuid = CBUUID(string: "0xFF02")
}

@MainActor private extension CBPeripheral {
    var controlService: CBService? {
        services?.first { $0.uuid == .controlServiceUuid }
    }

    var locationService: CBService? {
        services?.first { $0.uuid == .locationServiceUuid }
    }

    var pairingService: CBService? {
        services?.first { $0.uuid == .pairingServiceUuid }
    }

    var remoteControlService: CBService? {
        services?.first { $0.uuid == .remoteControlServiceUuid }
    }
}

@MainActor private extension CBPeripheral {
    var controlServiceBatteryLevelReadCharacteristic: CBCharacteristic? {
        controlService?.characteristics?.first { $0.uuid == .controlServiceBatteryLevelReadCharacteristicUuid }
    }

    var locationServiceNotifyStatusCharacteristic: CBCharacteristic? {
        locationService?.characteristics?.first { $0.uuid == .locationServiceNotifyStatusCharacteristicUuid }
    }

    var locationServiceReadStatusCharacteristic: CBCharacteristic? {
        locationService?.characteristics?.first { $0.uuid == .locationServiceReadStatusCharacteristicUuid }
    }

    var locationServiceWriteLocationCharacteristic: CBCharacteristic? {
        locationService?.characteristics?.first { $0.uuid == .locationServiceWriteLocationCharacteristicUuid }
    }

    var locationServiceReadWriteControlCharacteristic: CBCharacteristic? {
        locationService?.characteristics?.first { $0.uuid == .locationServiceReadWriteControlCharacteristicUuid }
    }

    var locationServiceReadWriteLocationSyncCharacteristic: CBCharacteristic? {
        locationService?.characteristics?.first { $0.uuid == .locationServiceReadWriteLocationSyncCharacteristicUuid }
    }

    var locationServiceReadWriteTimeSyncCharacteristic: CBCharacteristic? {
        locationService?.characteristics?.first { $0.uuid == .locationServiceReadWriteTimeSyncCharacteristicUuid }
    }

    var locationServiceReadWriteAreaSyncCharacteristic: CBCharacteristic? {
        locationService?.characteristics?.first { $0.uuid == .locationServiceReadWriteAreaSyncCharacteristicUuid }
    }

    var pairingServiceWriteCommandCharacteristic: CBCharacteristic? {
        pairingService?.characteristics?.first { $0.uuid == .pairingServiceWriteCommandCharacteristicUuid }
    }

    var remoteControlServiceCommandCharacteristic: CBCharacteristic? {
        remoteControlService?.characteristics?.first { $0.uuid == .remoteControlServiceCommandCharacteristicUuid }
    }

    var remoteControlServiceNotifyCharacteristic: CBCharacteristic? {
        remoteControlService?.characteristics?.first { $0.uuid == .remoteControlServiceNotifyCharacteristicUuid }
    }
}

private extension CBPeripheral {
    func writeBool(_ value: Bool, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        writeValue(value ? Data([0x01]) : Data([0x00]), for: characteristic, type: type)
    }
}

private extension KnownDevice {
    convenience init(peripheral: CBPeripheral, quickReconnect: Bool = true) {
        self.init(identifier: peripheral.identifier,
                  name: peripheral.name,
                  displayName: peripheral.displayName,
                  quickConnect: quickReconnect,
                  lastSeen: .now)
    }
}

private extension OrderedDictionary where Key == CBPeripheral, Value == Device {
    @discardableResult mutating func updateOrAppend(_ peripheral: CBPeripheral,
                                                    advertising advertisementData: Device.AdvertisementData?,
                                                    state: Device.State) -> Bool
    {
        guard !update(peripheral, updateHandler: { $0.state = state }) else {
            return true
        }
        self[peripheral] = .init(peripheral: peripheral, advertisementData: advertisementData, state: state)
        return false
    }

    @discardableResult mutating func update(_ peripheral: CBPeripheral, updateHandler: (inout Device) -> Void) -> Bool {
        guard var device = self[peripheral] else {
            return false
        }

        updateHandler(&device)
        self[peripheral] = device
        return true
    }

    mutating func removeAll(withPeripheral peripheral: CBPeripheral) {
        removeValue(forKey: peripheral)
    }
}
