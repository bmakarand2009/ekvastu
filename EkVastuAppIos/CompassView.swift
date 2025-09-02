import SwiftUI

struct CompassView: View {
    @StateObject private var compassService = CompassService.shared
    @State private var isActive = false
    
    var body: some View {
        VStack {
            Text("Direction: \(compassService.direction)")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(Color.customBrown.opacity(0.3), lineWidth: 4)
                    .frame(width: 250, height: 250)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 240, height: 240)
                    .shadow(radius: 4)
                
                // Compass directions
                ForEach(["N", "E", "S", "W"], id: \.self) { direction in
                    CompassDirectionView(direction: direction)
                }
                
                // Compass needle
                VStack {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 4, height: 105)
                    
                    Spacer()
                        .frame(height: 105)
                }
                .rotationEffect(.degrees(compassService.heading))
                
                // Center pin
                Circle()
                    .fill(Color.customBrown)
                    .frame(width: 20, height: 20)
                
                if compassService.isCalibrating {
                    Text("Calibrating...")
                        .foregroundColor(.red)
                        .background(Color.white.opacity(0.7))
                        .padding(8)
                }
            }
            
            Text("\(Int(compassService.heading))°")
                .font(.title)
                .padding()
            
            Toggle("Activate Compass", isOn: $isActive)
                .padding()
                .onChange(of: isActive) { newValue in
                    if newValue {
                        compassService.startUpdates()
                    } else {
                        compassService.stopUpdates()
                    }
                }
        }
        .padding()
        .onAppear {
            if isActive {
                compassService.startUpdates()
            }
        }
        .onDisappear {
            compassService.stopUpdates()
        }
    }
}

struct CompassDirectionView: View {
    let direction: String
    
    var body: some View {
        VStack {
            Text(direction)
                .font(.headline)
                .foregroundColor(Color.customBrown)
            
            Spacer()
        }
        .frame(width: 220, height: 220)
        .rotationEffect(angle(for: direction))
    }
    
    private func angle(for direction: String) -> Angle {
        switch direction {
        case "N": return .degrees(0)
        case "E": return .degrees(90)
        case "S": return .degrees(180)
        case "W": return .degrees(270)
        default: return .degrees(0)
        }
    }
}

struct CompassView_Previews: PreviewProvider {
    static var previews: some View {
        CompassView()
    }
}
