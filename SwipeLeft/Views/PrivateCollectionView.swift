import SwiftUI

struct PrivateCollectionView: View {
    var body: some View {
        NavigationStack {
            Text("Private Collection")
                .navigationTitle("My Collection")
        }
    }
}

#Preview {
    PrivateCollectionView()
} 