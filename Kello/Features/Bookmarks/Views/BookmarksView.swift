import SwiftUI

struct BookmarksView: View {
    @StateObject private var viewModel = BookmarksViewModel()
    @State private var showingNewCollection = false
    @State private var selectedCollection: BookmarkCollection?
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 40)
            } else if viewModel.collections.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bookmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Collections Yet")
                        .font(.headline)
                    
                    Text("Create your first collection to start organizing your favorite recipes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: { showingNewCollection = true }) {
                        Label("Create Collection", systemImage: "plus.circle.fill")
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.collections) { collection in
                        NavigationLink {
                            BookmarkCollectionDetailView(collection: collection)
                        } label: {
                            CollectionCard(collection: collection)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Collections")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewCollection = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewCollection) {
            NewCollectionSheet(
                viewModel: viewModel,
                isPresented: $showingNewCollection
            )
        }
        .task {
            viewModel.loadCollections()
        }
    }
}

// MARK: - Supporting Views

private struct NewCollectionSheet: View {
    @ObservedObject var viewModel: BookmarksViewModel
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Collection Name", text: $name)
                    TextField("Description (Optional)", text: $description)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.createCollection(
                            name: name,
                            description: description.isEmpty ? nil : description
                        )
                        isPresented = false
                        name = ""
                        description = ""
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    BookmarksView()
} 