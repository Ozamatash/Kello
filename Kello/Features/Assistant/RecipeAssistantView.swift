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
        ZStack(alignment: .bottom) {
            NavigationView {
                VStack(spacing: 0) {
                    // Title header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 16) {
                            Label("\(recipe.cookingTime) min", systemImage: "clock")
                            Label(recipe.cuisineType, systemImage: "fork.knife")
                            Label(recipe.mealType, systemImage: "sun.max")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    
                    Divider()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Picker for steps/ingredients
                            Picker("View", selection: $selectedTab) {
                                Text("Steps").tag(0)
                                Text("Ingredients").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            // Content based on selection
                            if selectedTab == 0 {
                                stepsCard
                            } else {
                                ingredientsCard
                            }
                        }
                        .padding(.vertical)
                        .padding(.bottom, 100)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        EmptyView()
                    }
                }
            }
            
            // Recording Interface
            recordingInterface
                .ignoresSafeArea()
        }
        .alert("Assistant Unavailable", isPresented: $viewModel.showError) {
            if viewModel.canRetry {
                Button("Try Again", role: .none) {
                    viewModel.retryLastRequest()
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "basket.fill")
                    .foregroundStyle(.green)
                Text("Ingredients")
                    .font(.headline)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        
                        Text(ingredient)
                            .font(.body)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "list.number")
                    .foregroundStyle(.blue)
                Text("Steps")
                    .font(.headline)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 16) {
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
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private var recordingInterface: some View {
        ZStack {
            // Processing animation (centered)
            if viewModel.isProcessing {
                GradientBallView()
                    .transition(.opacity.combined(with: .scale))
            }
            
            // Main content
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
                        // Outer glow when recording
                        if viewModel.isRecording {
                            // Outer blue portal glow
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .blur(radius: 12)
                            
                            // Inner bright portal effect
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            .white,
                                            .white.opacity(0.8),
                                            .blue.opacity(0.3),
                                            .clear
                                        ]),
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: 35
                                    )
                                )
                                .frame(width: 72, height: 72)
                                .blur(radius: 3)
                        }
                        
                        // Main button background
                        Circle()
                            .fill(viewModel.isRecording ? .white : Color(UIColor.secondarySystemGroupedBackground))
                            .frame(width: 60, height: 60)
                            .overlay {
                                // Pulse animation when recording
                                if viewModel.isRecording {
                                    Circle()
                                        .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                        .scaleEffect(1.5)
                                        .opacity(0)
                                        .animation(
                                            .easeOut(duration: 1)
                                            .repeatForever(autoreverses: false),
                                            value: viewModel.isRecording
                                        )
                                }
                            }
                        
                        // Microphone icon with animation
                        Image(systemName: "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(viewModel.isRecording ? .blue : .primary)
                            .scaleEffect(viewModel.isRecording ? 1.1 : 1.0)
                            .shadow(color: viewModel.isRecording ? .white.opacity(0.5) : .clear, 
                                    radius: 4, x: 0, y: 0)
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.isRecording)
                }
                .opacity(viewModel.isProcessing ? 0 : 1)
                .animation(.easeInOut, value: viewModel.isProcessing)
                
                Spacer()
                
                // Close button
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(maxHeight: viewModel.isProcessing ? 120 : 80)
        .background(
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
        )
    }
}

struct GradientBallView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Bright outer glow
            Circle()
                .fill(.white)
                .frame(width: 90, height: 90)
                .blur(radius: 20)
                .opacity(0.3)
            
            // Gradient background
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .white,
                            Color.blue.opacity(0.7),
                            .white,
                            Color.blue.opacity(0.7),
                            .white
                        ]),
                        center: .center,
                        startAngle: .degrees(rotation),
                        endAngle: .degrees(rotation + 360)
                    )
                )
                .frame(width: 80, height: 80)
                .blur(radius: 12)
            
            // Inner bright core
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            .white,
                            .white.opacity(0.8),
                            .clear
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 30
                    )
                )
                .frame(width: 60, height: 60)
                .blur(radius: 3)
            
            // Overlay to create depth
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 80, height: 80)
                .opacity(0.5)
        }
        .frame(width: 80, height: 80)
        .padding(.bottom, 8)
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