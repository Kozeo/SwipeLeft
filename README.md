I'll create a detailed prompt for Cursor to build your photo swiping app using the architecture we've discussed. Here's a comprehensive guide that you can use:

# Swift Photo Swipe App - Implementation Guide for Cursor

## Project Overview

Create a modern iOS photo swiping application using Swift and SwiftUI for iOS 17+. The app allows users to swipe through photos on their device with specific actions:
- Swipe left: Ignore photo
- Swipe right: Save to private collection
- Swipe up: Upload to public feed

## Architectural Pattern

Implement a clean architecture pattern based on MVVM with distinct layers:
1. Presentation Layer (SwiftUI Views + ViewModels)
2. Domain Layer (Business Logic + Use Cases)
3. Data Layer (Repositories + Data Sources)
4. Core Layer (Common Utilities + Extensions)

## Technology Requirements

- Swift 5.9+
- SwiftUI
- iOS 17+
- Async/await for concurrency
- PhotoKit for accessing device photos
- Modern SwiftUI navigation patterns (NavigationStack)

## Implementation Details

### 1. Project Setup and Configuration

- Create a new iOS app with SwiftUI interface
- Set deployment target to iOS 17.0
- Configure Info.plist with proper photo library usage descriptions
- Set up the app folder structure following the architecture layers
- Configure SwiftUI lifecycle with App protocol

### 2. Core Layer Implementation

- Create dependency injection container for managing dependencies
- Implement networking service with async/await
- Create local storage service for tracking photo statuses
- Develop utilities for photo manipulation and caching

### 3. Data Layer Implementation

- Create repositories:
  - PhotoLibraryRepository: Access device photo library using PhotoKit
  - PhotoStorageRepository: Store processing status locally
  - PhotoUploadRepository: Handle API calls for photo uploads

- Implement concrete repository implementations with proper error handling

### 4. Domain Layer Implementation

- Create domain entities:
  - Photo: Represent a photo with status (unprocessed, ignored, saved, uploaded)
  - User: Basic user profile information
  
- Implement use cases:
  - PhotoBrowserUseCase: Accessing and loading photos
  - PhotoActionUseCase: Handling swipe actions
  - PublicFeedUseCase: Fetching and interacting with public feed

### 5. Presentation Layer Implementation

#### ViewModels

- Create the following ViewModels:
  - PhotoCardViewModel: Handle single photo display and swipe actions
  - PhotoBrowserViewModel: Manage photo loading and browsing
  - PrivateCollectionViewModel: Display saved photos
  - PublicFeedViewModel: Display and interact with public feed
  - ProfileViewModel: Manage user profile

#### Views

- Implement the following SwiftUI views:
  - MainTabView: Container with tabs for browse, collections, and profile
  - PhotoBrowserView: Main view for swiping photos
  - PhotoCardView: Individual photo card with swipe gestures
  - PrivateCollectionView: Grid view of saved photos
  - PublicFeedView: Scroll view of public photos
  - ProfileView: User profile management
  - SwipeActionIndicatorView: Visual indicator showing swipe action result

### 6. Gesture Implementation

- Create a custom SwipeGestureHandler for detecting directional swipes
- Implement smooth animations for swipe actions
- Add visual feedback for each swipe direction (e.g., overlays or labels)
- Use spring animations for card movement

### 7. UI/UX Design

- Create a minimalist interface focusing on one photo at a time
- Implement Gen Z-friendly gradients and bold colors
- Use smooth transitions between screens
- Create visual cues for swipe directions and actions
- Implement haptic feedback for successful swipes

### 8. API Integration

- Create API endpoints for:
  - User authentication
  - Private photo collection management
  - Public feed uploading and retrieval
  - Photo interaction (likes, comments)

### 9. Local Storage

- Implement persistent storage for:
  - User authentication state
  - Photo processing status
  - App settings and preferences

### 10. Photo Library Access

- Request and handle photo library permissions
- Efficiently load and display photos using PhotoKit
- Implement pagination for large photo libraries
- Create thumbnail loading for performance

### 11. Testing

- Implement unit tests for all use cases
- Create UI tests for critical user flows
- Test edge cases like permission denial

## Detailed Implementation Steps

1. First, set up the project structure with all necessary files
2. Implement the Core layer services
3. Create the domain entities and repository interfaces
4. Implement the repository implementations
5. Create the use cases for business logic
6. Build the ViewModels connecting use cases to the UI
7. Implement the SwiftUI views with gesture support
8. Add animations and visual feedback for gestures
9. Connect all layers through dependency injection
10. Test and refine the implementation

## Key Features to Implement

1. **Photo Card UI with Gesture Recognition**
   - Implement drag gestures with directional detection
   - Create spring animations for card movement
   - Add rotation during swipe for natural feel

2. **Photo Loading and Caching**
   - Implement efficient photo loading from PhotoKit
   - Create thumbnail caching for performance
   - Implement pagination for smooth browsing

3. **Visual Feedback**
   - Add status overlays during swipes
   - Implement color changes based on swipe direction
   - Create subtle animations for action confirmation

4. **Photo Collections**
   - Create grid view for private collection
   - Implement masonry layout for public feed
   - Add pull-to-refresh for updates

5. **User Authentication**
   - Implement secure token storage
   - Create login/signup flows
   - Handle user profile management

## Performance Considerations

- Implement lazy loading for photos
- Use async/await for background operations
- Optimize image resizing for different screen sizes
- Implement memory management for large photo libraries
- Use prefetching for smooth browsing experience

## Implementation Priorities

1. Core photo browsing with swipe functionality
2. Local storage of swipe actions
3. Private collection management
4. Public feed integration
5. User profile and settings

Follow this guide to implement a clean, maintainable, and performant photo swiping app using Swift and SwiftUI for iOS 17+.
