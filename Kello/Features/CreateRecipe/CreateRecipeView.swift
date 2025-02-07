import SwiftUI

struct CreateRecipeView: View {
    @StateObject private var viewModel = CreateRecipeViewModel()
    @State private var selectedVideoURL: URL?
    @State private var showingVideoPicker = false
    
    // Form fields
    @State private var title = ""
    @State private var description = ""
    @State private var cookingTime = 30
    @State private var selectedCuisineType = "Italian"
    @State private var selectedMealType = "Dinner"
    @State private var ingredients: [String] = [""]
    @State private var steps: [String] = [""]
    
    // Constants
    private let cuisineTypes = [
        "Italian", "Chinese", "Japanese", "Mexican", "Indian",
        "Thai", "French", "American", "Mediterranean", "Korean",
        "Vietnamese", "Spanish", "Greek", "Middle Eastern"
    ]
    
    private let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack", "Dessert"]
    
    private func clearForm() {
        title = ""
        description = ""
        cookingTime = 30
        selectedCuisineType = "Italian"
        selectedMealType = "Dinner"
        ingredients = [""]
        steps = [""]
        selectedVideoURL = nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    // Basic Information Section
                    Section("Basic Information") {
                        TextField("Recipe Title", text: $title)
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                        
                        Picker("Cuisine Type", selection: $selectedCuisineType) {
                            ForEach(cuisineTypes, id: \.self) { cuisine in
                                Text(cuisine).tag(cuisine)
                            }
                        }
                        
                        Picker("Meal Type", selection: $selectedMealType) {
                            ForEach(mealTypes, id: \.self) { meal in
                                Text(meal).tag(meal)
                            }
                        }
                        
                        Stepper("Cooking Time: \(cookingTime) min", value: $cookingTime, in: 5...240, step: 5)
                    }
                    
                    // Video Upload Section
                    Section("Recipe Video") {
                        if let videoURL = selectedVideoURL {
                            HStack {
                                Image(systemName: "video.fill")
                                    .foregroundColor(.green)
                                Text("Video selected")
                                Spacer()
                                Button("Remove") {
                                    selectedVideoURL = nil
                                }
                                .foregroundColor(.red)
                            }
                        } else {
                            Button {
                                showingVideoPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "video.badge.plus")
                                    Text("Add Video")
                                }
                            }
                        }
                    }
                    
                    // Ingredients Section
                    Section(header: Text("Ingredients")) {
                        ForEach($ingredients.indices, id: \.self) { index in
                            HStack {
                                TextField("Ingredient \(index + 1)", text: $ingredients[index])
                                
                                if ingredients.count > 1 {
                                    Button {
                                        ingredients.remove(at: index)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        
                        Button {
                            ingredients.append("")
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Ingredient")
                            }
                        }
                    }
                    
                    // Steps Section
                    Section(header: Text("Steps")) {
                        ForEach($steps.indices, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Step \(index + 1)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(alignment: .top) {
                                    TextField("Describe this step", text: $steps[index], axis: .vertical)
                                        .lineLimit(2...4)
                                    
                                    if steps.count > 1 {
                                        Button {
                                            steps.remove(at: index)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                                .frame(width: 24, height: 24)
                                        }
                                        .padding(.leading, 4)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Button {
                            steps.append("")
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Step")
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .navigationTitle("Create Recipe")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Create") {
                            Task {
                                await viewModel.createRecipe(
                                    title: title,
                                    description: description,
                                    cookingTime: cookingTime,
                                    cuisineType: selectedCuisineType,
                                    mealType: selectedMealType,
                                    ingredients: ingredients.filter { !$0.isEmpty },
                                    steps: steps.filter { !$0.isEmpty },
                                    videoURL: selectedVideoURL
                                )
                                
                                // Clear form if recipe was created successfully
                                if !viewModel.showError {
                                    clearForm()
                                }
                            }
                        }
                        .disabled(!viewModel.canCreateRecipe(
                            title: title,
                            description: description,
                            ingredients: ingredients,
                            steps: steps,
                            videoURL: selectedVideoURL
                        ) || viewModel.isLoading)
                    }
                }
                .alert("Error", isPresented: $viewModel.showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage ?? "An unknown error occurred")
                }
                .sheet(isPresented: $showingVideoPicker) {
                    VideoPicker(selectedURL: $selectedVideoURL)
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .overlay {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Creating recipe...")
                                    .font(.headline)
                            }
                            .padding(24)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 10)
                        }
                        .allowsHitTesting(true)
                }
            }
        }
    }
}

#Preview {
    CreateRecipeView()
} 
