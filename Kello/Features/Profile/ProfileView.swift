import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var likedRecipes: [Recipe] = []
    @State private var isLoading = false
    @State private var error: Error?
    private let firebaseService = FirebaseService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text(authViewModel.userProfile?.email ?? "User")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical)
                    
                    // Stats
                    HStack(spacing: 40) {
                        VStack {
                            Text("\(likedRecipes.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Liked")
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(authViewModel.userProfile?.bookmarkedRecipes.count ?? 0)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Saved")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom)
                    
                    // Liked Recipes Grid
                    VStack(alignment: .leading) {
                        Text("Liked Recipes")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView("Loading recipes...")
                                .padding(.top, 40)
                        } else if let error = error {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                Text("Error loading recipes")
                                    .font(.headline)
                                Text(error.localizedDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding()
                            .padding(.top, 40)
                        } else if likedRecipes.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "heart.slash")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No liked recipes yet")
                                    .font(.headline)
                                Text("Like some recipes to see them here")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .padding(.top, 40)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                ForEach(likedRecipes) { recipe in
                                    RecipeCard(recipe: recipe)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.primary)
                    }
                }
            }
            .task {
                await loadLikedRecipes()
            }
            .refreshable {
                await loadLikedRecipes()
            }
        }
    }
    
    private func loadLikedRecipes() async {
        guard let likedIds = authViewModel.userProfile?.likedRecipes else { return }
        
        isLoading = true
        do {
            var recipes: [Recipe] = []
            // Load recipes in batches to avoid hitting Firestore limits
            let batchSize = 10
            for i in stride(from: 0, to: likedIds.count, by: batchSize) {
                let end = min(i + batchSize, likedIds.count)
                let batch = Array(likedIds[i..<end])
                let batchRecipes = try await firebaseService.fetchRecipesByIds(batch)
                recipes.append(contentsOf: batchRecipes)
            }
            await MainActor.run {
                self.likedRecipes = recipes
                self.error = nil
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
        await MainActor.run {
            isLoading = false
        }
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
} 