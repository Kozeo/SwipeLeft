import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Text("Profile")
                .navigationTitle("My Profile")
        }
    }
}

#Preview {
    ProfileView()
} 