import SwiftUI

struct RecipeDetailsSheet: View {
    let recipe: Recipe
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Title header
            Text(recipe.title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(UIColor.systemBackground))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    recipeInfo
                    ingredientsSection
                    instructionsSection
                    nutritionSection
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
        }
    }
    
    private var recipeInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Label("\(recipe.cookingTime) min", systemImage: "clock")
                Label(recipe.cuisineType, systemImage: "fork.knife")
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            
            Text(recipe.recipeDescription)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.headline)
            
            ForEach(recipe.ingredients, id: \.self) { ingredient in
                HStack(alignment: .top) {
                    Text("•")
                        .foregroundColor(.gray)
                    Text(ingredient)
                }
                .font(.body)
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.headline)
            
            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1).")
                        .foregroundColor(.gray)
                        .frame(width: 24, alignment: .leading)
                    Text(step)
                }
                .font(.body)
            }
        }
    }
    
    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition")
                .font(.headline)
            
            if let calories = recipe.calories {
                nutritionRow(label: "Calories", value: "\(calories) kcal")
            }
            if let protein = recipe.protein {
                nutritionRow(label: "Protein", value: "\(protein)g")
            }
            if let carbs = recipe.carbs {
                nutritionRow(label: "Carbs", value: "\(carbs)g")
            }
            if let fat = recipe.fat {
                nutritionRow(label: "Fat", value: "\(fat)g")
            }
        }
    }
    
    private func nutritionRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
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
        Color.black.edgesIgnoringSafeArea(.all)
        RecipeDetailsSheet(
            recipe: Recipe(
                title: "Test Recipe",
                description: "A delicious test recipe that's perfect for testing the UI.",
                cookingTime: 30,
                cuisineType: "Italian",
                ingredients: ["2 cups flour", "1 cup sugar", "3 eggs", "1 cup milk"],
                steps: [
                    "Mix dry ingredients",
                    "Add wet ingredients",
                    "Stir until combined",
                    "Bake at 350°F for 25 minutes"
                ],
                videoURL: "",
                thumbnailURL: ""
            ),
            isPresented: .constant(true)
        )
    }
}
