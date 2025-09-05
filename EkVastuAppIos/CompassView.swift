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
                
                // Compass rose (directions) - rotates opposite to heading
                ZStack {
                    // North
                    Text("N")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                        .offset(y: -100)
                    
                    // East
                    Text("E")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color.customBrown)
                        .offset(x: 100)
                    
                    // South
                    Text("S")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color.customBrown)
                        .offset(y: 100)
                    
                    // West
                    Text("W")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color.customBrown)
                        .offset(x: -100)
                    
                    // Additional directions
                    Text("NE")
                        .font(.system(size: 14))
                        .foregroundColor(Color.customBrown.opacity(0.7))
                        .offset(x: 70, y: -70)
                    
                    Text("SE")
                        .font(.system(size: 14))
                        .foregroundColor(Color.customBrown.opacity(0.7))
                        .offset(x: 70, y: 70)
                    
                    Text("SW")
                        .font(.system(size: 14))
                        .foregroundColor(Color.customBrown.opacity(0.7))
                        .offset(x: -70, y: 70)
                    
                    Text("NW")
                        .font(.system(size: 14))
                        .foregroundColor(Color.customBrown.opacity(0.7))
                        .offset(x: -70, y: -70)
                    
                    // Degree markers (every 10 degrees)
                    ForEach(0..<36) { i in
                        Rectangle()
                            .fill(Color.customBrown.opacity(i % 3 == 0 ? 0.5 : 0.3))
                            .frame(width: i % 3 == 0 ? 2 : 1,
                                   height: i % 3 == 0 ? 10 : 5)
                            .offset(y: -110)
                            .rotationEffect(.degrees(Double(i * 10)))
                    }
                }
                .rotationEffect(.degrees(360 - compassService.heading))
                .animation(.easeInOut(duration: 0.3), value: compassService.heading)
                
                // Fixed needle pointing up (North)
                ZStack {
                    // North part of needle (red)
                    Triangle()
                        .fill(Color.red)
                        .frame(width: 30, height: 80)
                        .offset(y: -40)
                    
                    // South part of needle (white/gray)
                    Triangle()
                        .fill(Color.gray.opacity(0.7))
                        .frame(width: 30, height: 80)
                        .rotationEffect(.degrees(180))
                        .offset(y: 40)
                    
                    // Needle line
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 2, height: 160)
                }
                
                // Center pin
                Circle()
                    .fill(Color.customBrown)
                    .frame(width: 20, height: 20)
                    .shadow(radius: 2)
                
                if compassService.isCalibrating {
                    Text("Calibrating...")
                        .foregroundColor(.red)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .padding(8)
                }
            }
            
            HStack(spacing: 20) {
                VStack {
                    Text("Heading")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(Int(compassService.heading))°")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                VStack {
                    Text("Direction")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(compassService.direction)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
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

// Triangle shape for the needle
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct CompassView_Previews: PreviewProvider {
    static var previews: some View {
        CompassView()
    }
}
