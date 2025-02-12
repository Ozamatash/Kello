# Kello

Kello is a native iOS application designed as a cooking-focused social video platform. With a TikTok-inspired vertical video feed, intuitive filtering, bookmarking, and engagement features, Kello empowers home cooks to discover, share, and interact with recipe videos—all in one place.

---

## Overview

Kello is designed for culinary enthusiasts who want to explore recipe videos in a fun, swipe-driven interface. The platform combines social video features with powerful AI-driven assistance to create a comprehensive cooking companion app.

---

## Features

### Core Video Experience
- **Vertical Swiping:** Swipe between recipe videos with smooth transitions
- **Auto-Playback:** Videos auto-play as they enter the user's view, with minimal buffering
- **Engagement Metrics:** Each video displays likes, comments, shares, and recipe details
- **Infinite Scrolling & Pagination:** Efficient loading and recycling of video cards to maintain performance

### AI-Powered Features
- **Smart Recipe Assistant:**
  - Real-time voice-controlled cooking guidance
  - Step-by-step instructions with hands-free navigation
  - Ingredient substitution suggestions
  - Cooking technique explanations
  - Interactive Q&A during cooking
- **AI Nutritional Analysis:**
  - Automatic nutritional information generation
  - Per-serving calculations for calories, protein, carbs, and fat
  - Smart portion size estimation
  - Detailed nutritional breakdown for each recipe
- **Semantic Search & Discovery:**
  - Natural language recipe search
  - Intelligent ingredient-based matching
  - Context-aware recipe recommendations
  - Vector-based similarity search

### Recipe Creation & Management
- **Video Upload & Processing:**
  - Direct video upload from device
  - Background video processing
  - Automatic thumbnail generation
  - Progress tracking and status updates
- **Recipe Details:**
  - Comprehensive recipe information input
  - Dynamic ingredient and step management
  - Cuisine and meal type categorization
  - Cooking time and difficulty settings
- **Form Validation:** Real-time validation ensures all required information is provided
- **Progress Feedback:** Visual feedback during the upload process

### Content Discovery
- **Smart Filtering:** Filter by cooking time, cuisine type, meal type, and nutritional preferences
- **Grid-Based Discovery:** Modern grid layout with dynamic filter chips
- **Personalized Recommendations:** Based on user preferences and interaction history

### Recipe Details & Organization
- **Interactive Recipe View:**
  - Step-by-step instructions
  - Ingredient checklist
  - AI-generated nutritional information
  - Voice-controlled navigation
- **Smart Bookmarking:**
  - Like-based recipe saving
  - Custom collections
  - Offline access to saved recipes
- **Local Data Management:** SwiftData integration for efficient caching

### Community Features
- **User Authentication:** Seamless Firebase Authentication integration
- **Social Interaction:**
  - Rich commenting system
  - Recipe ratings and reviews
  - User profiles and following
- **Content Sharing:** Share recipes across social platforms

---

## Technology Stack

- **Mobile Development:**  
  - **Language:** Swift  
  - **Framework:** SwiftUI  
  - **Architecture:** MVVM with clean architecture principles

- **AI & Machine Learning:**
  - **OpenAI Integration:** For recipe assistance and nutritional analysis
  - **Natural Language Processing:** For voice commands and semantic search
  - **Vector Search:** For intelligent recipe discovery

- **Local Data:**  
  - **SwiftData:** Efficient local data persistence
  - **AVFoundation:** Video processing and playback

- **Backend Services:**
  - **Firebase Authentication:** User management
  - **Cloud Firestore:** Real-time database
  - **Firebase Storage:** Media file hosting
  - **Firebase Functions:** Serverless operations
  - **Vector Search:** Semantic recipe search

---

## Setup & Installation

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/Ozamatash/Kello.git
   cd Kello
   ```

2. **Configuration Files:**
   - Add `GoogleService-Info.plist` for Firebase configuration
   - Add `OpenAI-Info.plist` with your OpenAI API key

3. **Open & Run:**
   - Open `Kello.xcodeproj` in Xcode
   - Select your target device/simulator
   - Build and run the application

---