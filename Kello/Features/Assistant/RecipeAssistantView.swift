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
                
                // Recording Interface
                recordingInterface
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
        ZStack {
            // Processing animation (centered)
            if viewModel.isProcessing {
                GradientBallView()
                    .transition(.opacity.combined(with: .scale))
            }
            
            HStack {
                // Record button
                Button {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(viewModel.isRecording ? Color.blue : Color(.systemGray4))
                            .frame(width: 48, height: 48)
                        
                        if viewModel.isRecording {
                            // Recording animation
                            TimelineView(.animation(minimumInterval: 0.1)) { _ in
                                Canvas { context, size in
                                    let width = size.width * 0.6
                                    let height = size.height * 0.6
                                    let centerX = size.width / 2
                                    let centerY = size.height / 2
                                    
                                    for i in 0..<8 {
                                        let angle = Double(i) * .pi / 4
                                        let x = centerX + cos(angle) * width / 2
                                        let y = centerY + sin(angle) * height / 2
                                        
                                        var path = Path()
                                        path.addEllipse(in: CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3))
                                        
                                        context.fill(
                                            path,
                                            with: .color(.white.opacity(
                                                sin(Date().timeIntervalSinceReferenceDate * 2 + Double(i)) * 0.5 + 0.5
                                            ))
                                        )
                                    }
                                }
                            }
                            .frame(width: 48, height: 48)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(.systemGray))
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
                
                Spacer()
                
                // Close button
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray4))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(Color(.systemGray))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}

struct GradientBallView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Gradient background
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.blue,
                            Color.blue.opacity(0.7),
                            Color.white,
                            Color.blue.opacity(0.7),
                            Color.blue
                        ]),
                        center: .center,
                        startAngle: .degrees(rotation),
                        endAngle: .degrees(rotation + 360)
                    )
                )
                .frame(width: 80, height: 80)
                .blur(radius: 15)
            
            // Overlay to create depth
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 80, height: 80)
                .blur(radius: 1)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 80) // Position it above the buttons
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotation = 360
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