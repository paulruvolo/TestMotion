//
//  ContentView.swift
//  TestMotion
//
//  Created by Paul Ruvolo on 2/24/22.
//

import SwiftUI
import MetaWear
import MetaWearCpp

class SensorManager: ObservableObject {
    @Published var accelData: [Float] = [0.0, 0.0, 0.0]
    
    init() {
        MetaWearScanner.shared.startScan(allowDuplicates: true) { (device) in
            // We found a MetaWear board, see if it is close
            if device.rssi > -100 {
                // Hooray! We found a MetaWear board, so stop scanning for more
                MetaWearScanner.shared.stopScan()
                // Connect to the board we found
                device.connectAndSetup().continueWith { t in
                    if let error = t.error {
                        // Sorry we couldn't connect
                        print(error)
                    } else {
                        // Hooray! We connected to a MetaWear board, so flash its LED!
                        var pattern = MblMwLedPattern()
                        mbl_mw_led_load_preset_pattern(&pattern, MBL_MW_LED_PRESET_PULSE)
                        mbl_mw_led_stop_and_clear(device.board)
                        mbl_mw_led_write_pattern(device.board, &pattern, MBL_MW_LED_COLOR_GREEN)
                        mbl_mw_led_play(device.board)
                        self.streamAccel(device: device)
                    }
                }
            }
        }
    }
    
    func streamAccel(device: MetaWear) {
        let board = device.board
        guard mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_ACCELEROMETER) != MODULE_TYPE_NA else {
            print("No accelerometer")
            return
        }
        let signal = mbl_mw_acc_get_acceleration_data_signal(board)
        mbl_mw_datasignal_subscribe(signal, bridge(obj: self)) { (context, data) in
            let _self: SensorManager = bridge(ptr: context!)
            let obj: MblMwCartesianFloat = data!.pointee.valueAs()
            _self.accelData = [obj.x, obj.y, obj.z]
        }
        mbl_mw_acc_enable_acceleration_sampling(board)
        mbl_mw_acc_start(board)
    }
}

struct ContentView: View {
    @ObservedObject var sensorManager = SensorManager()
    var body: some View {
        Text("Hello, world! \(sensorManager.accelData.map({String($0)}).joined(separator: ", "))")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
