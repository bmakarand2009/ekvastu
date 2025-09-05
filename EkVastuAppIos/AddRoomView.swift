import SwiftUI

struct AddRoomView: View {
    @ObservedObject var roomPhotoManager: RoomPhotoManager
    @State private var selectedRoomType: String = ""
    @State private var isDropdownOpen = false
    
    // Helper computed properties to break up complex expressions
    private var headerView: some View {
        Text("Add Another Room")
            .font(.headline)
            .foregroundColor(Color(hex: "#4A2511"))
            .padding(.horizontal)
    }
    
    private var dropdownButtonView: some View {
        Button(action: {
            withAnimation {
                isDropdownOpen.toggle()
            }
        }) {
            HStack {
                Text(selectedRoomType.isEmpty ? "Select room type" : selectedRoomType)
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
                    .rotationEffect(isDropdownOpen ? .degrees(180) : .degrees(0))
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dropdownMenuView: some View {
        Group {
            if isDropdownOpen {
                let availableRoomTypes = roomPhotoManager.getAvailableRoomTypes()
                
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(availableRoomTypes, id: \.self) { roomType in
                        Button(action: {
                            selectedRoomType = roomType
                            isDropdownOpen = false
                        }) {
                            Text(roomType)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.white)
                        }
                        Divider()
                    }
                }
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .offset(y: 50)
                .zIndex(1)
            }
        }
    }
    
    private var addRoomButtonView: some View {
        Button(action: {
            if !selectedRoomType.isEmpty {
                roomPhotoManager.addRoom(roomType: selectedRoomType)
                selectedRoomType = ""
            }
        }) {
            Text("Add Room")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(!selectedRoomType.isEmpty ? Color(hex: "#4A2511") : Color.gray)
                .cornerRadius(8)
        }
        .disabled(selectedRoomType.isEmpty)
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            headerView
            
            // Room type dropdown
            ZStack {
                dropdownButtonView
                dropdownMenuView
            }
            .padding(.horizontal)
            
            addRoomButtonView
        }
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}
