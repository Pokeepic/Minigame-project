# Profile System Implementation

## Overview
The Manhwa System now supports multiple user profiles with isolated save data. Each profile maintains its own:
- Player stats (level, XP, coins)
- Daily quest progress
- Upgrades (XP boost, coin boost)
- Streak data
- Title system progress
- System logs

## Architecture

### 1. Data Model (`lib/models/profile.dart`)
```dart
class UserProfile {
  final String id;          // Unique identifier
  final String name;         // Display name
  final int createdAt;       // Timestamp (epoch ms)
}
```

### 2. Storage Layer (`lib/services/system_repository.dart`)
**Key Namespacing:**
- All profile-specific data uses the pattern: `p:{profileId}:{key}`
- Profile list stored in: `profiles_json`
- Active profile ID stored in: `active_profile`

**Helper Method:**
```dart
String _k(String profileId, String key) => 'p:$profileId:$key';
```

**Profile CRUD:**
- `getProfiles()` / `setProfiles()` - Manage profile list
- `getActiveProfileId()` / `setActiveProfileId()` - Track active profile
- All existing methods now accept `String pid` parameter

### 3. Controller Layer (`lib/services/system_controller.dart`)
**Profile State:**
- `List<UserProfile> profiles` - All available profiles
- `String activeProfileId` - Currently active profile

**Profile Management:**
- `createProfile(String name)` - Creates new profile and switches to it
- `switchProfile(String profileId)` - Loads state for different profile
- `deleteProfile(String profileId)` - Removes profile (cannot delete active or last)

**Initialization:**
1. Load profiles from storage
2. If no profiles exist, create default "Profile 1"
3. Load game state for active profile using `_loadStateFor(profileId)`

### 4. UI (`lib/ui/pages/profile_picker_page.dart`)
**Features:**
- List all profiles with visual indicators for active profile
- Switch between profiles
- Create new profiles with custom names
- Delete profiles (with confirmation dialog)
- Prevents deleting active or last profile

**Access:**
- Profile button (person icon) in main page AppBar

## Usage Flow

1. **First Launch:**
   - System creates default "Profile 1"
   - Loads game state for this profile

2. **Creating New Profile:**
   - Click profile button → "New Profile"
   - Enter name → System creates profile with fresh save data
   - Automatically switches to new profile

3. **Switching Profiles:**
   - Click profile button → Select different profile
   - System saves current profile state
   - Loads selected profile's state

4. **Deleting Profile:**
   - Click delete icon on non-active profile
   - Confirm deletion
   - Profile and all associated data are removed

## Technical Details

### Save Data Isolation
Each profile's data is completely isolated using key prefixing:
```
Profile 1: p:1:level, p:1:xp, p:1:coins, etc.
Profile 2: p:2:level, p:2:xp, p:2:coins, etc.
```

### State Management
- Controller maintains single active state in memory
- When switching profiles, controller:
  1. Saves current profile state
  2. Loads new profile state
  3. Triggers UI rebuild

### Persistence
All profile operations use SharedPreferences:
- Profile list as JSON array
- Active profile ID as simple string
- Game state with namespaced keys

## Constants
Added to `lib/utils/constants.dart`:
```dart
const String kProfilesKey = 'profiles_json';
const String kActiveProfileIdKey = 'active_profile';
```

## Files Modified/Created
- **Created:** `lib/models/profile.dart`
- **Created:** `lib/ui/pages/profile_picker_page.dart`
- **Modified:** `lib/services/system_repository.dart` - Added profile namespacing
- **Modified:** `lib/services/system_controller.dart` - Added profile management
- **Modified:** `lib/ui/pages/system_home_page.dart` - Added profile button
- **Modified:** `lib/utils/constants.dart` - Added profile constants

## Future Enhancements
- Profile avatars/icons
- Profile import/export
- Cloud sync
- Profile statistics comparison
- Rename profile functionality
