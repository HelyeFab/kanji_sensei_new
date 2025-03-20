# Kanji Sensei

A Flutter application for learning Japanese kanji characters.

## Features

### Improved JLPT Kanji Retrieval System

The app features an optimized kanji retrieval system for JLPT levels with:

- **Two-Phase Loading**: Initial quick loading of the first batch (20 kanji) followed by background loading of all remaining kanji
- **Pagination**: Easy navigation through large sets of kanji with prev/next controls
- **Caching**: Efficient storage of kanji data for faster subsequent access
- **Background Processing**: Continuous loading in the background while users interact with the initial results
- **Progress Indicators**: Visual feedback showing loading status

### Technical Implementation

- **State Management**: Uses BLoC pattern with custom events for initial loading, background loading, and pagination
- **Caching Strategy**: Implements Hive for persistent storage of kanji data and JLPT level sets
- **Local Data Integration**: Uses bundled JSON files for reliable JLPT level kanji data
- **API Integration**: Optimized KanjiAPI service with specialized methods for different loading scenarios
- **Fallback Mechanism**: Gracefully falls back to API if local data fails
- **Clean Architecture**: Follows repository pattern with clear separation of concerns

## Getting Started

### Local Kanji Data Integration

The app now uses local JSON data files for JLPT level kanji retrieval, providing several benefits:

- **Reliability**: No dependency on external API availability for core JLPT level data
- **Performance**: Faster loading times with bundled data
- **Accuracy**: Guaranteed correct JLPT level assignments
- **Offline First**: Works without internet connection for JLPT level browsing
- **Fallback Mechanism**: Gracefully falls back to API if local data fails

The local data is organized by JLPT level in the `lib/assets/kanji_data/` directory, with each level having its own JSON file containing the complete set of kanji for that level.

### Kanji Flashcards Flutter App Development Plan

### Overview

Create a Kanji study app tailored for individual learners at beginner, intermediate, and advanced levels, leveraging Flutter, Clean Architecture, Firebase, and Bloc for state management. The app targets iOS, Android, and future web/desktop expansions.

## Feature List

### Core Features

#### Flashcards

- Automatic creation of flashcards from Kanji API data:

  - Kanji character
  - Readings (on'yomi and kun'yomi)
  - Meanings
  - Stroke count
  - Radicals
  - Example sentences
- Manual flashcard creation by users (fields above customizable)
- Categorization of flashcards into decks by JLPT levels and user-created folders

#### Quizzes and Spaced Repetition

- Interactive quizzes to test user knowledge
- Spaced repetition algorithm to reinforce learning

#### Progress Tracking

- User dashboards to view progress, statistics, and milestones

#### Offline Mode

- Local caching of flashcards and Kanji API responses
- Synchronization when connection resumes

## Technical Specifications

### Architecture (Clean Architecture)

#### Presentation Layer
- Flutter UI components
- Bloc state management

#### Domain Layer
- Business logic entities
- Use cases (flashcard management, quizzes, progress tracking)

#### Data Layer
- Repositories to abstract data sources
- API service for KanjiAPI
- Firebase Firestore integration
- Local caching (Hive)

#### Core Layer
- Shared utilities (network checker, caching handler, error handling)

### State Management
- Bloc Pattern
- Structured, testable state management

### UI/UX Design
- Custom-styled Flutter UI for enhanced user experience
- Dynamic theming (light/dark mode)
- System theme respect with manual toggle option

### Firebase Integration

#### Authentication
- Email/password, Google Sign-in, Apple Sign-in

#### Firestore
- Storage for user-generated flashcards and progress data

### API Integration

#### KanjiAPI
- Retrieve kanji by JLPT level or individual search
- Optimized background loading for complete JLPT level sets
- Caching retrieved data locally
- Graceful handling of API downtime (fallback to local cache)

### Testing and Monitoring

#### Automated testing from project start
- Unit tests
- Widget tests
- Integration tests

#### Firebase Analytics and Crashlytics for
- User interaction monitoring
- Stability monitoring and reporting

## Project Structure

```
/lib
 ├── core
 │   ├── utils
 │   └── constants
 ├── data
 │   ├── api
 │   ├── repositories
 │   └── models
 ├── domain
 │   ├── entities
 │   └── repositories
 ├── presentation
 │   ├── blocs
 │   ├── screens
 │   └── widgets
 └── main.dart
```

## Implementation Roadmap

### Phase 1: Project Setup ✅
- Flutter project initialization
- Clean Architecture folder structure setup
- API integration basic setup

### Phase 2: Core Functionalities ✅
- Fetching and caching data from KanjiAPI
- Improved JLPT kanji retrieval system
- Background loading and pagination

### Phase 3: Authentication & Database 🔄
- Implement Firebase Authentication
- Setup Firestore structure

### Phase 4: Additional Features 🔄
- Flashcard creation (auto/manual)
- Decks and categorization
- Quizzes and spaced repetition
- Progress tracking dashboard
- Offline capabilities

### Phase 5: UI & UX Refinement 🔄
- Implement custom designs
- Dark/light theming
- Comprehensive accessibility considerations

### Phase 6: Testing & Monitoring 🔄
- Implement comprehensive automated tests
- Integrate Firebase Analytics and Crashlytics

## Firebase Integration Work Plan (from Keyra)

This work plan outlines the steps to integrate Firebase features from the Keyra app into the kanji_sensei app.

### 1. Authentication Implementation

#### Step 1: Set up Authentication Service
- Create an auth service similar to Keyra's `AuthService` in `lib/core/auth/auth_service.dart`
- Implement email/password authentication, sign-in, sign-up, sign-out, and password reset

#### Step 2: Create Authentication UI
- Implement login/register screen with tab controller similar to Keyra's `AuthPage`
- Create login form with email, password fields, and forgot password functionality
- Create register form with name, email, and password fields
- Add social sign-in buttons (Google, Apple) if needed

#### Step 3: Implement Authentication BLoC
- Create auth bloc with events and states for authentication flow
- Implement authentication state listening for automatic sign-in
- Handle authentication errors and display appropriate messages

### 2. User Profile Implementation

#### Step 1: Create Profile Screen
- Implement profile screen similar to Keyra's `ProfilePage`
- Display user information (name, email, profile picture)
- Add settings section for theme, notifications, and language
- Add information section for app version, acknowledgments, etc.

#### Step 2: User Stats Repository
- Create a repository for tracking user statistics
- Implement methods for getting, updating, and streaming user stats
- Track saved words count, streaks, and other relevant metrics

#### Step 3: User Stats Model
- Create a model for user statistics similar to Keyra's `UserStats`
- Include fields for saved words, streaks, and other metrics
- Implement methods for checking if streak is active

### 3. Word Collection Implementation

#### Step 1: Create Saved Words Repository
- Implement a repository similar to Keyra's `SavedWordsRepository`
- Add methods for saving, removing, updating, and retrieving words
- Implement Firebase Firestore integration for storing words

#### Step 2: Create Saved Word Model
- Create a model for saved words similar to Keyra's `SavedWord`
- Include fields for word, definition, examples, progress, etc.
- Implement methods for converting to/from Firestore

#### Step 3: Create Word Collection UI
- Implement UI for displaying saved words
- Add functionality for adding words to collection
- Create UI for organizing words into categories or decks

### 4. Flashcard Implementation

#### Step 1: Create Flashcard Widget
- Implement a flashcard widget similar to Keyra's `Flashcard`
- Add front and back card designs
- Include functionality for displaying kanji information

#### Step 2: Create Study Session
- Implement study session page similar to Keyra's `StudySessionPage`
- Add functionality for flipping cards and marking difficulty
- Implement spaced repetition algorithm for scheduling reviews

#### Step 3: Create Study Progress Tracking
- Implement progress tracking for study sessions
- Add UI for displaying progress statistics
- Create functionality for tracking streaks and achievements

### 5. Authentication Flow and Navigation

#### Step 1: Implement Authentication Flow
- Create navigation logic to restrict app access to authenticated users
- Redirect unauthenticated users to login/register screen
- Implement automatic sign-in for returning users

#### Step 2: Create Main Navigation
- Implement main navigation with bottom navigation bar
- Add routes for kanji search, dictionary, study, and profile screens
- Implement navigation guards based on authentication state

### 6. Integration and Testing

#### Step 1: Integrate All Components
- Connect authentication, profile, word collection, and flashcard features
- Ensure data flows correctly between components
- Implement proper error handling and loading states

#### Step 2: Test Authentication Flow
- Test sign-up, sign-in, and sign-out functionality
- Verify password reset works correctly
- Test social sign-in if implemented

#### Step 3: Test Word Collection and Flashcards
- Test saving, updating, and removing words
- Verify flashcard functionality works correctly
- Test spaced repetition algorithm for scheduling reviews

#### Step 4: Test User Stats and Streaks
- Verify user stats are updated correctly
- Test streak calculation and tracking
- Ensure profile page displays correct information
