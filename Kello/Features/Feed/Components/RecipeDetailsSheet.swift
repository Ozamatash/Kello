import SwiftUI

struct RecipeDetailsSheet: View {
    let recipe: Recipe
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
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
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Description
                    Text(recipe.recipeDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Nutrition Card
                    if recipe.servings != nil || recipe.calories != nil || recipe.caloriesPerServing != nil {
                        nutritionCard
                    }
                    
                    // Ingredients Card
                    ingredientsCard
                    
                    // Instructions Card
                    instructionsCard
                }
                .padding(.vertical)
            }
        }
    }
    
    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                Text("Nutrition")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .imageScale(.small)
                    Text("AI-generated")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            // Content
            VStack(spacing: 12) {
                if let servings = recipe.servings {
                    nutritionRow(
                        icon: "person.2.fill",
                        color: .purple,
                        label: "Servings",
                        value: "\(servings)"
                    )
                }
                
                if let calories = recipe.calories {
                    nutritionRow(
                        icon: "flame.fill",
                        color: .orange,
                        label: "Total calories",
                        value: "\(calories) kcal"
                    )
                }
                
                if let caloriesPerServing = recipe.caloriesPerServing {
                    nutritionRow(
                        icon: "flame.fill",
                        color: .orange,
                        label: "Calories per serving",
                        value: "\(caloriesPerServing) kcal"
                    )
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                if let protein = recipe.protein {
                    nutritionRow(
                        icon: "circle.fill",
                        color: .red,
                        label: "Protein per serving",
                        value: "\(Int(protein))g"
                    )
                }
                
                if let carbs = recipe.carbs {
                    nutritionRow(
                        icon: "circle.fill",
                        color: .green,
                        label: "Carbs per serving",
                        value: "\(Int(carbs))g"
                    )
                }
                
                if let fat = recipe.fat {
                    nutritionRow(
                        icon: "circle.fill",
                        color: .yellow,
                        label: "Fat per serving",
                        value: "\(Int(fat))g"
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
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
    
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "list.number")
                    .foregroundStyle(.blue)
                Text("Instructions")
                    .font(.headline)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 16) {
                        Text("\(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.blue)
                            .clipShape(Circle())
                        
                        Text(step)
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
    
    private func nutritionRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// Add corner radius modifier for specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                              cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    ZStack {
        Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
        RecipeDetailsSheet(
            recipe: Recipe(
                title: "Homemade Margherita Pizza",
                description: "A classic Italian pizza with fresh mozzarella, tomatoes, and basil. Perfect for a family dinner or entertaining guests.",
                cookingTime: 45,
                cuisineType: "Italian",
                ingredients: [
                    "3 cups all-purpose flour",
                    "1 cup warm water",
                    "2 tbsp olive oil",
                    "Fresh mozzarella",
                    "San Marzano tomatoes",
                    "Fresh basil leaves",
                    "Salt and pepper to taste"
                ],
                steps: [
                    "Mix flour, water, and yeast to make the dough",
                    "Let the dough rise for 1 hour",
                    "Stretch the dough into a circle",
                    "Add tomato sauce and toppings",
                    "Bake at 450°F for 15 minutes"
                ],
                videoURL: "",
                thumbnailURL: "",
                calories: 1200,
                protein: 45,
                carbs: 140,
                fat: 38,
                servings: 4,
                caloriesPerServing: 300
            ),
            isPresented: .constant(true)
        )
    }
}
