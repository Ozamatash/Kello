# Kello

Kello is a native iOS application designed as a cooking-focused social video platform. With a TikTok-inspired vertical video feed, intuitive filtering, bookmarking, and engagement features, Kello empowers home cooks to discover, share, and interact with recipe videos—all in one place.

---

## Overview

Kello is designed for culinary enthusiasts who want to explore recipe videos in a fun, swipe-driven interface. Initially focusing on a seamless video feed and robust discovery tools, the platform provides the foundation for community engagement and advanced AI-powered features in later phases.

---

## Features

### Core Video Feed
- **Vertical Swiping:** Swipe between recipe videos with smooth transitions.
- **Auto-Playback:** Videos auto-play as they enter the user’s view, with minimal buffering.
- **Engagement Metrics:** Each video displays likes, comments, shares, and recipe details.
- **Infinite Scrolling & Pagination:** Efficient loading and recycling of video cards to maintain performance.

### Content Filtering & Discovery
- **Filter Recipes:** Users can filter videos by cooking time ranges (e.g., under 15 min, 15–30 min, etc.), cuisine types, and meal types.
- **Semantic Search:** Natural language search capability leveraging vector search (based on cosine similarity) across recipe data.
- **Grid-Based Discovery:** Modern grid layout for exploring recipes with dynamic filter chips and clear visual feedback for active filters.

### Recipe Details & Bookmarking
- **Detailed Recipe View:** Comprehensive recipe information including ingredients, step-by-step instructions, nutritional info, and more.
- **Like-Based Bookmarking:** Easily save and organize your favorite recipes. Liked recipes persist across app sessions and are accessible through the profile tab.
- **Local Data Management:** SwiftData integration for caching and offline support.

### Community Engagement
- **User Authentication:** Seamless sign-up, sign-in, and password reset via Firebase Authentication.
- **Comments & Ratings:** Allow users to comment on and rate videos to foster community interaction.
- **Social Sharing:** Share recipes to external social platforms with ease.

---

## Technology Stack

- **Mobile Development:**  
  - **Language:** Swift  
  - **Framework:** SwiftUI  
  - **Architecture:** MVVM (Model-View-ViewModel); clean separation of concerns for UI, business logic, and data operations.  

- **Local Data Persistence:**  
  - **SwiftData:** For efficient, local storage of user and recipe data.

- **Backend & Cloud Services (Firebase):**  
  - **Firebase Authentication:** Secure user authentication and session management.
  - **Cloud Firestore:** Real-time database for recipe data, filtering, and community features.
  - **Firebase Storage:** Hosting video files and recipe thumbnails.
  - **Firebase Functions & VectorSearch :** For semantic search

---

## Setup & Installation

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/Ozamatash/Kello.git
   cd Kello
   ```

2. **Open the Project:**
   - Open `Kello.xcodeproj` in Xcode.

3. **Firebase Setup:**
   - Ensure you have a valid Firebase project.
   - Place your `GoogleService-Info.plist` in the project’s Resources (it is already handled in the `.gitignore`).
   - The Firebase configuration is handled in `FirebaseConfig.swift`.

4. **Build & Run:**
   - Select the appropriate target (simulator or device) and run the application.

---