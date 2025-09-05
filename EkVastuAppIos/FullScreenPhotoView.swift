import SwiftUI

struct FullScreenPhotoView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Navigation bar with title and close button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Photo")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Spacer to balance layout
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.clear)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                
                // Image preview with pinch to zoom and double tap to zoom
                GeometryReader { geometry in
                    ZoomableScrollView {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width)
                    }
                }
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        VStack {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20))
                            Text("Back")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .frame(width: 80)
                        .padding(.vertical, 10)
                        .background(Color.gray)
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        // Close photo preview and camera view
                        presentationMode.wrappedValue.dismiss()
                        // We need to notify the parent view to dismiss itself
                        NotificationCenter.default.post(name: NSNotification.Name("DismissCameraView"), object: nil)
                    }) {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Done")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .frame(width: 80)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
            }
        }
    }
}

// Zoomable scroll view for pinch-to-zoom functionality
struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        // Set up the UIScrollView
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        // Create a UIHostingController to hold our SwiftUI content
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the hosting view to the scroll view
        scrollView.addSubview(hostedView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostedView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        
        // Add double-tap gesture for zooming
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // Update the hosting controller's SwiftUI content
        context.coordinator.hostingController.rootView = content
        
        // Make sure we update the size of the content
        context.coordinator.updateContentSize(for: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(hostingController: UIHostingController(rootView: content))
    }
    
    // Coordinator handles the UIScrollViewDelegate methods and holds the hosting controller
    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>
        
        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
            super.init()
        }
        
        func updateContentSize(for scrollView: UIScrollView) {
            // Update the content size of the scroll view
            scrollView.contentSize = hostingController.view.intrinsicContentSize
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            
            if scrollView.zoomScale > scrollView.minimumZoomScale {
                // If already zoomed in, zoom out
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                // Zoom in to where the user tapped
                let location = gesture.location(in: scrollView)
                let zoomRect = CGRect(
                    x: location.x - (scrollView.bounds.width / 4),
                    y: location.y - (scrollView.bounds.height / 4),
                    width: scrollView.bounds.width / 2,
                    height: scrollView.bounds.height / 2
                )
                scrollView.zoom(to: zoomRect, animated: true)
            }
        }
    }
}
