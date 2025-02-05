Below is an implementation plan outlining the steps to integrate semantic search using the Firestore Vector Search extension into Kello. This plan is adapted from the guide you found, with adjustments for our recipe-based feature.

---

## Implementation Plan for Ingredient-based Semantic Search

### 1. Install and Configure the Firestore Vector Search Extension

- **Access the Firebase Console:**
  - Navigate to your Firestore console and select the **Extensions** tab.
  - Search for **"Vector Search with Firestore extension"** and click **Install**.

- **Configure the Extension:**
  - **Project:** Choose your existing Kello project.
  - **Collection Path:** Use `recipes` (instead of `notes`) so that the extension processes our recipe documents.
  - **Default Query Limit:** Set a value (e.g., 3–5) per our expected search result size.
  - **Input Field Name:** Select a field that contains searchable text. You might combine fields (e.g., a dedicated `ingredientsText` field or even `recipeDescription`) that represent the ingredients and the recipe details.
  - **Output Field Name:** Use `embedding` (this is where the computed vector will be stored).
  - **Status Field Name:** Use the default (for example, `status`).
  - Check **Embed existing documents** and **Update existing documents**.
  - Set the Cloud Function location (typically `us-central1`).

- **Allow the Extension to Process Your Data:**
  - After installation, monitor your Firestore console until each recipe document has an `embedding` field (a vector of length 768) added alongside a status field.

---

### 2. Set Up Firestore Indexes

- **Verify Document Embeddings:**
  - In your Firestore console, inspect a few documents in the `recipes` collection to ensure they now include an `embedding` field.

- **Create the Required Composite Index (if using prefilters):**
  - If you wish to restrict results (for example, by a user ID if your recipes are user-specific), run a composite index command. For example:
  
  ```bash
  gcloud alpha firestore indexes composite create --project=YOUR_PROJECT_ID --collection-group=recipes --query-scope=COLLECTION --field-config=order=ASCENDING,field-path=userId --field-config=vector-config='{"dimension":"768","flat": "{}"}',field-path=embedding
  ```
  - Replace `YOUR_PROJECT_ID` with your actual project id.

---

### 3. Create a Semantic Search Service

- **New Swift File:** Create a file named `RecipeSearchService.swift` in the `Kello/Core/Services/` directory.

- **Define Structures & Callable Function:**
  - Create data structures to encode the search query (`QueryRequest`), any filters (`QueryFilter`), and decode the response (`QueryResponse`).
  - Instantiate a callable Cloud Function using Firebase’s Functions SDK.
  
```swift:Kello/Core/Services/RecipeSearchService.swift
import Foundation
import FirebaseFunctions
import FirebaseAuth

// Query input structure for the semantic search
private struct QueryRequest: Codable {
    var query: String
    var limit: Int?
    var prefilters: [QueryFilter]?
}

// Used to optionally pre-filter the documents. For example, you can filter by the recipe's userId.
private struct QueryFilter: Codable {
    var field: String
    var `operator`: String
    var value: String
}

// Expected response structure from the Cloud Function
private struct QueryResponse: Codable {
    var ids: [String]
}

class RecipeSearchService {
    private let functions = Functions.functions()
    
    // Set up the callable function for semantic search
    private lazy var vectorSearchQueryCallable: Callable<QueryRequest, QueryResponse> = {
        functions.httpsCallable("ext-firestore-vector-search-queryCallable")
    }()
    
    /// Returns the current authenticated user (if any) for prefiltering.
    private var currentUserUID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    /// Calls the semantic search function with the provided search term.
    func performQuery(searchTerm: String) async -> [String] {
        // Set up prefilters if you want to restrict results to the current user's recipes.
        // If your recipe data is global, you might simply pass an empty array or omit the property.
        let prefilters: [QueryFilter]? = {
            if let uid = currentUserUID {
                return [QueryFilter(field: "userId", operator: "==", value: uid)]
            }
            return nil
        }()
        
        let queryRequest = QueryRequest(query: searchTerm, limit: 5, prefilters: prefilters)
        
        do {
            let result = try await vectorSearchQueryCallable(queryRequest)
            print("Semantic search result IDs: \(result.ids)")
            return result.ids
        } catch {
            print("Semantic search failed: \(error.localizedDescription)")
            return []
        }
    }
}
```

---

### 4. Integrate Semantic Search with the UI

- **Modifying the Discover/Search View:**
  - Add a search bar to your recipe discovery screen (for instance, in `DiscoverView.swift`) using SwiftUI’s `searchable` modifier.
  - Use the `.task` view modifier with a debounce mechanism to invoke the semantic search method when the user stops typing.

```swift:Kello/Features/Discover/DiscoverView.swift
import SwiftUI

struct DiscoverView: View {
    @State private var searchTerm: String = ""
    @State private var recipeIDs: [String] = []
    
    // Instantiate the recipe search service
    private let searchService = RecipeSearchService()
    
    var body: some View {
        NavigationView {
            VStack {
                // Display a list based on returned recipe IDs.
                // In a production app, use these IDs to query and load full Recipe objects.
                List(recipeIDs, id: \.self) { id in
                    Text("Recipe ID: \(id)")
                }
            }
            .searchable(text: $searchTerm, prompt: "Search recipes by ingredients")
            .task(id: searchTerm, debounce: .milliseconds(800)) {
                guard !searchTerm.isEmpty else { return }
                let ids = await searchService.performQuery(searchTerm: searchTerm)
                await MainActor.run {
                    self.recipeIDs = ids
                }
            }
            .navigationTitle("Discover Recipes")
        }
    }
}
```

---

### 5. Testing and Debugging

- **Firestore Console Verification:**
  - Add some sample recipe documents (ensure they include rich text on ingredients or description).  
  - Verify that after a short period, each document in the `recipes` collection contains an `embedding` field.

- **Local Testing:**
  - Run the app in the iOS Simulator.
  - Verify that the search bar appears and that input triggers the semantic search call.
  - Monitor Xcode’s console/logs to check for any errors (for example, data format issues).

- **Adjust & Iterate:**
  - If you see errors like "Expected object, received string", compare your data structures with the extension’s expected parameters and adjust your `QueryRequest` accordingly.
  
---

### 6. Refinement and Future Enhancements

- **UI Improvements:**
  - Instead of showing raw recipe IDs, integrate your existing data-fetching logic to load the complete recipe details.
  
- **Advanced Filters:**
  - Consider combining the semantic search with traditional filters (e.g., cooking time, cuisine type) to further refine the user results.

- **Caching & Performance Optimizations:**
  - Look into caching popular queries or optimizing the debounce duration based on user testing.

- **Documentation:**
  - Update internal documentation (e.g., in `.notes` files) with details about this feature, known issues, and future plans.

- **User Feedback:**
  - Gather feedback from early users to fine-tune the semantic search experience and iterate as needed.

---

### 7. Deployment

- **Merge the Feature:**
  - Once tested, merge the semantic search feature into your main branch following your CI/CD workflow.
  
- **Monitor in Production:**
  - Keep an eye on Firebase function logs and user reports to ensure the feature works reliably in production.

---

By following this plan, you’ll integrate a powerful semantic search feature into Kello that leverages vector similarity search on Firestore, allowing users to find recipes based on natural language ingredient queries. This approach not only aligns with our long-term AI integration goals but also boosts the user experience with intuitive, context-aware search results.
