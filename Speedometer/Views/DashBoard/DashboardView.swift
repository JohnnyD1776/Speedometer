//
//  ContentView.swift
//  Speedometer
//
//  Created by John Durcan on 03/06/2025.
//

import SwiftUI
import CoreLocation

struct DashboardView: View {
  @ObservedObject var vm: DashbordViewModel
  let style: GForceMeterStyle

  init(viewModel: DashbordViewModel, style: GForceMeterStyle = DefaultGForceMeterStyle()) {
    self.vm = viewModel
    self.style = style
  }

  var body: some View {
    VStack {
      header
      UnitDisplayToggle(type: $vm.type)
      speedometer
      gMeter
    }
    .padding()
  }
}


#Preview {
  DashboardView(viewModel:
                  DashbordViewModel(
                    locationManager: LocationManager(isSimulating: true)
                  )
  )
}
