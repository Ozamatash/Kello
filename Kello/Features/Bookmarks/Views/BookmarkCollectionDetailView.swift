import SwiftUI

struct BookmarkCollectionDetailView: View {
    let collection: BookmarkCollection
    @StateObject private var viewModel = BookmarksViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var editedName = ""
    @State private var editedDescription = ""
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 40)
            } else if viewModel.recipesInCollection.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Recipes Yet")
                        .font(.headline)
                    
                    Text("Save some recipes to this collection")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.recipesInCollection) { recipe in
                        CollectionRecipeCard(
                            recipe: recipe,
                            onRemovePressed: {
                                viewModel.removeRecipeFromCollection(
                                    recipeId: recipe.id,
                                    collectionId: collection.id
                                )
                            },
                            showRemoveButton: true
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            Menu {
                Button(action: { showingEditSheet = true }) {
                    Label("Edit Collection", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                    Label("Delete Collection", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                Form {
                    Section {
                        TextField("Collection Name", text: $editedName)
                        TextField("Description (Optional)", text: $editedDescription)
                    }
                }
                .navigationTitle("Edit Collection")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingEditSheet = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            let updatedCollection = BookmarkCollection(
                                id: collection.id,
                                userId: collection.userId,
                                name: editedName,
                                description: editedDescription.isEmpty ? nil : editedDescription,
                                recipeIds: collection.recipeIds,
                                thumbnailURL: collection.thumbnailURL
                            )
                            viewModel.updateCollection(updatedCollection)
                            showingEditSheet = false
                        }
                        .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDragIndicator(.visible)
        }
        .alert("Delete Collection?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteCollection(collection.id)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .task {
            editedName = collection.name
            editedDescription = collection.description ?? ""
            viewModel.selectCollection(collection)
        }
    }
}

#Preview {
    NavigationStack {
        BookmarkCollectionDetailView(
            collection: BookmarkCollection(
                id: "test",
                userId: "user1",
                name: "Test Collection",
                description: "A test collection",
                recipeIds: []
            )
        )
    }
} 