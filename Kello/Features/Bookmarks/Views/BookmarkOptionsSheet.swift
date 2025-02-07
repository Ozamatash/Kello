import SwiftUI

struct BookmarkOptionsSheet: View {
    let recipe: Recipe
    @ObservedObject var viewModel: BookmarksViewModel
    @Binding var isPresented: Bool
    @State private var showingNewCollection = false
    @State private var newCollectionName = ""
    @State private var newCollectionDescription = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                Text("Save to Collection")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                Divider()
                
                // Create New Collection Button
                Button(action: { showingNewCollection = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.title3)
                        
                        Text("Create New Collection")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                
                Divider()
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if viewModel.collections.isEmpty {
                    VStack(spacing: 12) {
                        Text("No Collections Yet")
                            .font(.headline)
                        Text("Create your first collection to start saving recipes")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    // Existing Collections List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.collections) { collection in
                                Button(action: {
                                    viewModel.addRecipeToCollection(recipeId: recipe.id, collectionId: collection.id)
                                    isPresented = false
                                }) {
                                    HStack {
                                        // Collection Thumbnail
                                        if let thumbnailURL = collection.thumbnailURL {
                                            AsyncImage(url: URL(string: thumbnailURL)) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                Color.gray.opacity(0.3)
                                            }
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(8)
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 60, height: 60)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(collection.name)
                                                .font(.headline)
                                            
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
                                        .padding(.leading, 8)
                                        
                                        Spacer()
                                    }
                                    .padding()
                                }
                                
                                Divider()
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewCollection) {
                NavigationView {
                    Form {
                        Section {
                            TextField("Collection Name", text: $newCollectionName)
                            TextField("Description (Optional)", text: $newCollectionDescription)
                        }
                    }
                    .navigationTitle("New Collection")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingNewCollection = false
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Create") {
                                viewModel.createCollection(
                                    name: newCollectionName,
                                    description: newCollectionDescription.isEmpty ? nil : newCollectionDescription
                                )
                                showingNewCollection = false
                                newCollectionName = ""
                                newCollectionDescription = ""
                            }
                            .disabled(newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            viewModel.loadCollections()
        }
    }
}

#Preview {
    BookmarkOptionsSheet(
        recipe: Recipe(
            id: "test",
            title: "Test Recipe",
            description: "Test description",
            cookingTime: 30,
            cuisineType: "Italian",
            ingredients: [],
            steps: [],
            videoURL: "",
            thumbnailURL: ""
        ),
        viewModel: BookmarksViewModel(),
        isPresented: .constant(true)
    )
} 