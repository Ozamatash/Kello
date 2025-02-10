import SwiftUI
import AVFoundation

struct RecipeAssistantView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RecipeAssistantViewModel
    @State private var completedSteps: Set<Int> = []
    @State private var selectedTab = 0
    
    init(recipe: Recipe) {
        self.recipe = recipe
        _viewModel = StateObject(wrappedValue: RecipeAssistantViewModel(recipe: recipe))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top section with recipe info
                recipeInfoSection
                    .padding()
                    .background(Color(.systemBackground))
                
                // Tab view for steps and ingredients
                Picker("View", selection: $selectedTab) {
                    Text("Steps").tag(0)
                    Text("Ingredients").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                TabView(selection: $selectedTab) {
                    // Steps tab
                    ScrollView {
                        stepsSection
                            .padding()
                    }
                    .tag(0)
                    
                    // Ingredients tab
                    ScrollView {
                        ingredientsSection
                            .padding()
                    }
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                Divider()
                
                // Assistant Interface
                VStack(spacing: 0) {
                    if !viewModel.messages.isEmpty {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                }
                            }
                            .padding()
                        }
                        .frame(maxHeight: 200)
                        .background(Color(.systemGroupedBackground))
                    }
                    
                    // Recording interface
                    recordingInterface
                }
            }
            .navigationTitle("Cooking Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var recipeInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(recipe.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(recipe.recipeDescription)
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                Label("\(recipe.cookingTime)m", systemImage: "clock")
                Label(recipe.cuisineType, systemImage: "fork.knife")
                Label(recipe.mealType, systemImage: "sun.max")
            }
            .foregroundColor(.secondary)
            .font(.subheadline)
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
                .font(.title3)
                .fontWeight(.semibold)
            
            ForEach(recipe.ingredients, id: \.self) { ingredient in
                HStack(alignment: .top) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .padding(.top, 8)
                    
                    Text(ingredient)
                        .font(.body)
                }
                .foregroundColor(.primary)
            }
        }
    }
    
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Steps")
                .font(.title3)
                .fontWeight(.semibold)
            
            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Button {
                        if completedSteps.contains(index) {
                            completedSteps.remove(index)
                        } else {
                            completedSteps.insert(index)
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    } label: {
                        Image(systemName: completedSteps.contains(index) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(completedSteps.contains(index) ? .green : .secondary)
                            .font(.title3)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    
                    Text(step)
                        .strikethrough(completedSteps.contains(index))
                        .foregroundColor(completedSteps.contains(index) ? .secondary : .primary)
                }
            }
        }
    }
    
    private var recordingInterface: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    viewModel.isRecording ? viewModel.stopRecording() : viewModel.startRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(viewModel.isRecording ? Color.red : Color.blue)
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                if viewModel.isRecording {
                    HStack(spacing: 4) {
                        ForEach(0..<3) { _ in
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                                .opacity(0.8)
                        }
                    }
                    .transition(.opacity)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(),
                        value: viewModel.isRecording
                    )
                } else {
                    Text("Tap to ask a question")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct MessageBubble: View {
    let message: AssistantMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.isUser ? "You" : "Assistant")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

// Preview
#Preview {
    RecipeAssistantView(
        recipe: Recipe(
            id: "test",
            title: "Spaghetti Carbonara",
            description: "Classic Italian pasta dish",
            cookingTime: 30,
            cuisineType: "Italian",
            mealType: "Dinner",
            ingredients: ["Pasta", "Eggs", "Pecorino"],
            steps: [
                "Boil the pasta",
                "Mix eggs and cheese",
                "Combine and serve"
            ],
            videoURL: "example.com",
            thumbnailURL: "example.com",
            calories: 600,
            protein: 20,
            carbs: 70,
            fat: 25
        )
    )
} 