# BookSwap App - Technical Design Summary

## 1. Database Schema (Firestore)

### Collections and Documents

#### `listings` Collection
```typescript
{
  id: string;              // Auto-generated document ID
  ownerId: string;         // UID of user who posted the book
  title: string;           // Book title
  author: string;          // Book author
  condition: string;       // 'new', 'like_new', 'good', 'used'
  imageUrl?: string;       // Optional cover image URL
  pending: boolean;        // Whether book is available or in active swap
  createdAt: timestamp;    // When listing was created
}
```

#### `swaps` Collection
```typescript
{
  id: string;              // Auto-generated document ID
  listingId: string;       // ID of requested book listing
  offeredBookId: string;   // ID of book being offered in exchange
  senderId: string;        // UID of user making the offer
  recipientId: string;     // UID of user receiving the offer
  status: string;          // 'pending', 'accepted', 'rejected', 'cancelled'
  createdAt: timestamp;    // When swap was requested
}
```

#### `threads` Collection
```typescript
{
  id: string;              // Auto-generated document ID
  participantIds: string[]; // UIDs of users in the chat [sorted for consistency]
  lastMessage: string;     // Preview of most recent message
  updatedAt: timestamp;    // Last activity timestamp
  messages: Collection<{    // Subcollection of messages
    senderId: string;      // UID of message sender
    text: string;          // Message content
    sentAt: timestamp;     // When message was sent
  }>
}
```

## 2. Swap State Management

### Swap Status Flow
```
[Initial]
    ↓
[Pending] ←─────────┐
    ↓               │
  [User Action]     │
    ↓               │
[Accepted]─or─[Rejected]─or─[Cancelled]
```

### State Implementation
- **Swap Status Updates**: Implemented using Firestore transactions 
- **Book Availability**: Managed via `pending` flag in listings
- **Status Transitions**:
  - Pending → Accepted: status changed to swapped 
  - Pending → Rejected/Cancelled: Books' pending flags cleared (available again)
  - No transitions allowed from terminal states (Accepted/Rejected/Cancelled)

### Optimistic UI Updates
- Local state tracks pending status changes
- UI immediately reflects intended state
- Reverts on failure with error message
- Prevents duplicate actions during updates

## 3. State Management Architecture

### Provider Pattern Implementation
- `AppSettingsProvider`: Global app settings and preferences
- Firestore Streams: Real-time data synchronization
  - Listings: `streamMyListings()`, `streamAllListings()`
  - Swaps: `streamAllMyOffers()` combines sent/received offers
  - Chats: `streamMyThreads()` and `streamMessages()`

### Key State Management Decisions
1. **Stream-based Updates**: 
   - Real-time UI updates via Firestore snapshots
   - Automatic sync across devices
   - Built-in offline support

2. **Local vs. Remote State**:
   - Critical operations use transactions
   - UI state managed locally for responsiveness
   - Optimistic updates with fallback handling

## 4. Design Trade-offs and Challenges

### Trade-offs Made

1. **Data Modeling**
   - Pro: Flat structure for efficient queries
   - Con: Some data duplication (e.g., book status in both listings and swaps)

2. **Chat Implementation**
   - Pro: Simple thread creation with sorted participantIds
   - Con: Limited to 1:1 chats, no group support

3. **Swap Flow**
   - Pro: Clear state transitions prevent invalid states
   - Con: No partial/multi-book swaps supported

### Technical Challenges

1. **Real-time Sync**
   - Challenge: Consistent state across devices
   - Solution: Stream-based state management

2. **Offline Support**
   - Challenge: Operation queuing
   - Solution: Leveraged Firestore offline persistence

