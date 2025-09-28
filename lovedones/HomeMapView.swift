import SwiftUI
import MapKit
import CoreLocation

// MARK: - 🗺️ HOME MAP VIEW
struct HomeMapView: View {
    // Home location: 120 Piedmont Ave NE, Atlanta, GA 30303
    private let homeLocation = CLLocationCoordinate2D(latitude: 33.7540, longitude: -84.3855)
    private let homeAddress = "120 Piedmont Ave NE, Atlanta, GA 30303"
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 33.7540, longitude: -84.3855),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        VStack(spacing: LovedOnesDesignSystem.spaceM) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Home Location")
                        .font(LovedOnesDesignSystem.headingFont)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Your safe place")
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                }
                
                Spacer()
                
                // Home Icon
                ZStack {
                    Circle()
                        .fill(LovedOnesDesignSystem.primaryRed)
                        .frame(width: 40, height: 40)
                        .shadow(
                            color: LovedOnesDesignSystem.primaryRed.opacity(0.3),
                            radius: 6,
                            x: 0,
                            y: 3
                        )
                    
                    Image(systemName: "house.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, LovedOnesDesignSystem.spaceL)
            .padding(.top, LovedOnesDesignSystem.spaceL)
            
            // Map View (Clickable)
            Button(action: {
                openInAppleMaps()
            }) {
                Map(coordinateRegion: $region, annotationItems: [HomeAnnotation(coordinate: homeLocation)]) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(LovedOnesDesignSystem.primaryRed)
                                    .frame(width: 30, height: 30)
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: "house.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Home")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(LovedOnesDesignSystem.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                )
                        }
                    }
                }
                .frame(height: 200)
                .cornerRadius(LovedOnesDesignSystem.radiusL)
                .overlay(
                    RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusL)
                        .stroke(LovedOnesDesignSystem.lightGray, lineWidth: 1)
                )
                .overlay(
                    // Tap indicator
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                    .font(.caption)
                                Text("Tap for directions")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(LovedOnesDesignSystem.primaryRed.opacity(0.9))
                            )
                            .padding(.trailing, 8)
                            .padding(.bottom, 8)
                        }
                    }
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, LovedOnesDesignSystem.spaceL)
            
            // Address Info
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(LovedOnesDesignSystem.primaryRed)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Home Address")
                        .font(LovedOnesDesignSystem.captionFont)
                        .foregroundColor(LovedOnesDesignSystem.darkGray)
                    
                    Text(homeAddress)
                        .font(LovedOnesDesignSystem.bodyFont)
                        .foregroundColor(LovedOnesDesignSystem.textPrimary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(.horizontal, LovedOnesDesignSystem.spaceL)
            .padding(.bottom, LovedOnesDesignSystem.spaceL)
        }
        .background(
            RoundedRectangle(cornerRadius: LovedOnesDesignSystem.radiusL)
                .fill(Color.white)
                .shadow(
                    color: LovedOnesDesignSystem.shadowLight.color,
                    radius: LovedOnesDesignSystem.shadowLight.radius,
                    x: LovedOnesDesignSystem.shadowLight.x,
                    y: LovedOnesDesignSystem.shadowLight.y
                )
        )
        .padding(.horizontal, LovedOnesDesignSystem.spaceL)
    }
    
    private func openInAppleMaps() {
        print("🏠 Opening Apple Maps with coordinates: \(homeLocation.latitude), \(homeLocation.longitude)")
        
        // Try multiple approaches for better compatibility
        let approaches: [() -> Bool] = [
            // Approach 1: Native MapKit with directions
            {
                let placemark = MKPlacemark(coordinate: self.homeLocation)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = "Home"
                return mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
            },
            
            // Approach 2: Native MapKit without directions
            {
                let placemark = MKPlacemark(coordinate: self.homeLocation)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = "Home"
                return mapItem.openInMaps()
            },
            
            // Approach 3: Web URL (most reliable in simulator)
            {
                let webURLString = "https://maps.apple.com/?daddr=\(self.homeLocation.latitude),\(self.homeLocation.longitude)&dirflg=d"
                if let webURL = URL(string: webURLString) {
                    print("🌐 Opening web Apple Maps: \(webURLString)")
                    UIApplication.shared.open(webURL)
                    return true
                }
                return false
            },
            
            // Approach 4: Google Maps fallback
            {
                let googleURLString = "https://www.google.com/maps/dir/?api=1&destination=\(self.homeLocation.latitude),\(self.homeLocation.longitude)"
                if let googleURL = URL(string: googleURLString) {
                    print("🗺️ Opening Google Maps: \(googleURLString)")
                    UIApplication.shared.open(googleURL)
                    return true
                }
                return false
            }
        ]
        
        for (index, approach) in approaches.enumerated() {
            if approach() {
                print("✅ Successfully opened maps with approach \(index + 1)")
                return
            } else {
                print("❌ Approach \(index + 1) failed")
            }
        }
        
        print("❌ All approaches failed - no maps app available")
    }
}

// MARK: - 🏠 HOME ANNOTATION
struct HomeAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    HomeMapView()
}
