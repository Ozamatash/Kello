import SwiftUI

struct CollectionCard: View {
    let collection: BookmarkCollection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            if let thumbnailURL = collection.thumbnailURL {
                AsyncImage(url: URL(string: thumbnailURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
                    .overlay {
                        Image(systemName: "bookmark")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
            }
            
            // Collection Info
            VStack(alignment: .leading, spacing: 6) {
                Text(collection.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let description = collection.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Text("\(collection.recipeIds.count) recipes")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    CollectionCard(
        collection: BookmarkCollection(
            id: "test",
            userId: "user1",
            name: "Italian Favorites",
            description: "My favorite Italian recipes that I've collected over the years. Perfect for family dinners!",
            recipeIds: ["1", "2", "3"]
        )
    )
    .padding()
    .previewLayout(.sizeThatFits)
} 