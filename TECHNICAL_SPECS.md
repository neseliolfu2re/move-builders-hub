# 🔧 MoveHub Technical Specifications

## 📋 Architecture Overview

MoveHub is built with a modular architecture consisting of three main components:

1. **Smart Contracts** (Move language on Aptos)
2. **Frontend** (Next.js with TypeScript)
3. **Integration Layer** (Aptos SDK)

## 🏗️ Smart Contract Architecture

### Core Modules

#### 1. movehub.move - Main Platform
```move
module movehub::movehub {
    // Core data structures
    struct UserProfile has key { ... }
    struct Quest has key, store { ... }
    struct QuestCompletion has key, store { ... }
    struct MentorshipSession has key, store { ... }
    struct CollaborationSession has key, store { ... }
    
    // Main storage
    struct MoveHub has key { ... }
    
    // Core functions
    public fun initialize(admin: &signer)
    public entry fun register_user(...)
    public entry fun create_quest(...)
    public entry fun complete_quest(...)
    public entry fun schedule_mentorship(...)
    public entry fun start_collaboration(...)
}
```

#### 2. rewards.move - Rewards System
```move
module movehub::rewards {
    struct Reward has key, store { ... }
    struct SponsorPool has key { ... }
    struct RewardsSystem has key { ... }
    
    public fun initialize(admin: &signer)
    public entry fun sponsor_deposit(...)
    public entry fun create_quest_reward(...)
    public entry fun claim_reward(...)
}
```

#### 3. analytics.move - Analytics System
```move
module movehub::analytics {
    struct LearningProgress has key, store { ... }
    struct UserEngagement has key, store { ... }
    struct QuestAnalytics has key, store { ... }
    struct PlatformAnalytics has key, store { ... }
    
    public fun initialize(admin: &signer)
    public fun update_learning_progress(...)
    public fun update_user_engagement(...)
}
```

### Data Structures

#### UserProfile
```move
struct UserProfile has key {
    username: String,
    bio: String,
    skills: vector<String>,
    join_date: u64,
    total_quests_completed: u64,
    current_streak: u64,
    longest_streak: u64,
    mentorship_sessions: u64,
    collaboration_sessions: u64,
    reputation_score: u64,
    is_mentor: bool,
    is_sponsor: bool,
}
```

#### Quest
```move
struct Quest has key, store {
    id: u64,
    title: String,
    description: String,
    quest_type: u8,
    difficulty: u8,
    reward_amount: u64,
    sponsor: address,
    created_at: u64,
    expires_at: Option<u64>,
    status: u8,
    completion_count: u64,
    max_completions: Option<u64>,
    requirements: vector<String>,
    tags: vector<String>,
}
```

### Event System

#### Event Types
```move
struct UserRegisteredEvent has store, drop { ... }
struct QuestCreatedEvent has store, drop { ... }
struct QuestCompletedEvent has store, drop { ... }
struct MentorshipScheduledEvent has store, drop { ... }
struct CollaborationStartedEvent has store, drop { ... }
struct RewardCreatedEvent has store, drop { ... }
struct RewardClaimedEvent has store, drop { ... }
```

### Security Features

1. **Access Control**: Admin-only functions for platform management
2. **Input Validation**: All user inputs are validated
3. **Duplicate Prevention**: Users cannot complete the same quest twice
4. **Expiration Handling**: Quests and rewards can have expiration dates
5. **Permission Checks**: Mentorship and sponsorship require proper permissions

## 🎨 Frontend Architecture

### Technology Stack

- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **UI Components**: Ant Design
- **Icons**: Lucide React
- **Blockchain Integration**: Aptos SDK

### Project Structure

```
frontend/
├── app/                    # Next.js App Router
│   ├── layout.tsx         # Root layout
│   ├── page.tsx           # Home page
│   └── globals.css        # Global styles
├── components/            # React components
│   ├── WalletProvider.tsx # Wallet integration
│   ├── QuestList.tsx      # Quest management
│   ├── UserProfile.tsx    # User profile
│   ├── MentorshipSection.tsx # Mentorship features
│   ├── CollaborationSection.tsx # Collaboration features
│   └── StatsSection.tsx   # Analytics dashboard
├── lib/                   # Utility libraries
│   └── aptos.ts          # Aptos integration
├── types/                 # TypeScript types
│   └── index.ts          # Type definitions
└── package.json          # Dependencies
```

### Key Components

#### WalletProvider
```typescript
export function WalletProvider({ children }: WalletProviderProps) {
  const wallets = [
    new PetraWallet(),
    new PontemWallet(),
    new MartianWallet(),
    new RiseWallet(),
    new FewchaWallet(),
  ]

  return (
    <AptosWalletProvider
      plugins={wallets}
      autoConnect={true}
      onError={(error) => {
        console.log('Wallet error:', error)
      }}
    >
      {children}
    </AptosWalletProvider>
  )
}
```

#### Contract Integration
```typescript
export const contractHelpers = {
  async registerUser(signer: any, username: string, bio: string, skills: string[]) {
    const transaction = await aptos.transaction.build.simple({
      sender: signer.address,
      data: {
        function: `${MODULES.MOVEHUB}::register_user`,
        arguments: [username, bio, skills],
      },
    })
    // ... transaction handling
  },
  // ... other contract interactions
}
```

### State Management

- **Local State**: React hooks (useState, useEffect)
- **Wallet State**: Aptos wallet adapter
- **Contract State**: Direct blockchain queries
- **UI State**: Component-level state management

## 🔌 Integration Layer

### Aptos SDK Integration

```typescript
import { Aptos, AptosConfig, Network } from '@aptos-labs/ts-sdk'

const config = new AptosConfig({ 
  network: Network.TESTNET 
})

export const aptos = new Aptos(config)
```

### Contract Addresses

```typescript
export const MOVEHUB_ADDRESS = "0x1" // Deployed contract address
export const MODULES = {
  MOVEHUB: `${MOVEHUB_ADDRESS}::movehub`,
  REWARDS: `${MOVEHUB_ADDRESS}::rewards`,
  ANALYTICS: `${MOVEHUB_ADDRESS}::analytics`,
} as const
```

### Error Handling

```typescript
try {
  const result = await contractHelpers.registerUser(signer, username, bio, skills)
  // Handle success
} catch (error) {
  console.error('Error registering user:', error)
  // Handle error
}
```

## 📊 Database Schema (On-Chain)

### Tables

#### Users Table
- **Key**: User address
- **Value**: UserProfile struct
- **Indexes**: username, is_mentor, is_sponsor

#### Quests Table
- **Key**: Quest ID
- **Value**: Quest struct
- **Indexes**: quest_type, difficulty, status, sponsor

#### Quest Completions Table
- **Key**: Quest ID
- **Value**: Vector of QuestCompletion structs
- **Indexes**: user, completed_at

#### Mentorship Sessions Table
- **Key**: Session ID
- **Value**: MentorshipSession struct
- **Indexes**: mentor, mentee, status

#### Collaboration Sessions Table
- **Key**: Session ID
- **Value**: CollaborationSession struct
- **Indexes**: participants, status

#### Rewards Table
- **Key**: Reward ID
- **Value**: Reward struct
- **Indexes**: recipient, status, reward_type

#### Sponsor Pools Table
- **Key**: Sponsor address
- **Value**: SponsorPool struct
- **Indexes**: total_deposited, available_balance

## 🚀 Deployment Architecture

### Smart Contract Deployment

```bash
# Compile contracts
aptos move compile

# Run tests
aptos move test

# Deploy to testnet
aptos move publish --named-addresses movehub=<ADDRESS>

# Initialize systems
aptos move run --function-id <ADDRESS>::movehub::initialize
aptos move run --function-id <ADDRESS>::rewards::initialize
aptos move run --function-id <ADDRESS>::analytics::initialize
```

### Frontend Deployment

```bash
# Install dependencies
npm install

# Build for production
npm run build

# Deploy to Vercel/Netlify
npm run deploy
```

### Environment Configuration

```bash
# .env.local
NEXT_PUBLIC_APTOS_NETWORK=testnet
NEXT_PUBLIC_APTOS_NODE_URL=https://fullnode.testnet.aptoslabs.com
NEXT_PUBLIC_MOVEHUB_ADDRESS=<CONTRACT_ADDRESS>
```

## 🔒 Security Considerations

### Smart Contract Security

1. **Access Control**: Role-based permissions
2. **Input Validation**: Comprehensive input checking
3. **Reentrancy Protection**: Safe external calls
4. **Integer Overflow**: Safe math operations
5. **Event Logging**: Comprehensive audit trail

### Frontend Security

1. **Input Sanitization**: XSS prevention
2. **CSRF Protection**: Request validation
3. **Secure Headers**: Security headers configuration
4. **Environment Variables**: Secure configuration
5. **Error Handling**: Safe error messages

### Wallet Security

1. **Wallet Validation**: Verified wallet providers
2. **Transaction Signing**: Secure transaction handling
3. **Private Key Protection**: No key storage
4. **Network Validation**: Correct network verification

## 📈 Performance Optimization

### Smart Contract Optimization

1. **Gas Optimization**: Efficient storage usage
2. **Batch Operations**: Multiple operations in single transaction
3. **Event Optimization**: Minimal event data
4. **Storage Optimization**: Efficient data structures

### Frontend Optimization

1. **Code Splitting**: Lazy loading components
2. **Image Optimization**: Next.js image optimization
3. **Caching**: API response caching
4. **Bundle Optimization**: Tree shaking and minification

## 🧪 Testing Strategy

### Smart Contract Testing

```move
#[test_only]
module movehub::movehub_tests {
    #[test]
    fun test_user_registration() { ... }
    
    #[test]
    fun test_quest_creation() { ... }
    
    #[test]
    fun test_quest_completion() { ... }
}
```

### Frontend Testing

```typescript
// Component testing with Jest and React Testing Library
import { render, screen } from '@testing-library/react'
import { QuestList } from '../components/QuestList'

test('renders quest list', () => {
  render(<QuestList />)
  expect(screen.getByText('Available Quests')).toBeInTheDocument()
})
```

### Integration Testing

```typescript
// End-to-end testing with Playwright
import { test, expect } from '@playwright/test'

test('user can register and complete quest', async ({ page }) => {
  await page.goto('http://localhost:3000')
  await page.click('text=Connect Wallet')
  // ... test flow
})
```

## 📚 API Documentation

### Smart Contract Functions

#### User Management
- `register_user(username, bio, skills)` - Register new user
- `get_user_profile(user)` - Get user profile
- `set_mentor_status(user, is_mentor)` - Set mentor status
- `set_sponsor_status(user, is_sponsor)` - Set sponsor status

#### Quest Management
- `create_quest(title, description, type, difficulty, reward, ...)` - Create quest
- `complete_quest(quest_id, proof, partners)` - Complete quest
- `get_quest(quest_id)` - Get quest details
- `get_quest_completions(quest_id)` - Get quest completions

#### Mentorship
- `schedule_mentorship(mentee, topic, scheduled_at, duration)` - Schedule mentorship
- `get_mentorship_session(session_id)` - Get mentorship session

#### Collaboration
- `start_collaboration(participants, quest_id, topic)` - Start collaboration
- `get_collaboration_session(session_id)` - Get collaboration session

#### Rewards
- `sponsor_deposit(amount)` - Deposit sponsor funds
- `create_quest_reward(recipient, quest_id, amount, description)` - Create reward
- `claim_reward(reward_id)` - Claim reward

### Frontend API

#### Contract Helpers
```typescript
// User operations
contractHelpers.registerUser(signer, username, bio, skills)
contractHelpers.getUserProfile(userAddress)

// Quest operations
contractHelpers.createQuest(signer, title, description, ...)
contractHelpers.completeQuest(signer, questId, proof, partners)

// Mentorship operations
contractHelpers.scheduleMentorship(signer, mentee, topic, ...)

// Collaboration operations
contractHelpers.startCollaboration(signer, participants, ...)

// Reward operations
contractHelpers.sponsorDeposit(signer, amount)
contractHelpers.claimReward(signer, rewardId)
```

## 🔄 Event Handling

### Blockchain Events

```typescript
// Listen for events
aptos.getEventsByEventType({
  eventType: `${MOVEHUB_ADDRESS}::movehub::UserRegisteredEvent`,
  options: { limit: 10 }
})

// Handle events in frontend
useEffect(() => {
  const handleUserRegistered = (event: UserRegisteredEvent) => {
    // Update UI state
    setUsers(prev => [...prev, event])
  }
  
  // Subscribe to events
  eventSubscription.on('UserRegistered', handleUserRegistered)
  
  return () => {
    eventSubscription.off('UserRegistered', handleUserRegistered)
  }
}, [])
```

## 📱 Mobile Responsiveness

### Responsive Design

```css
/* Mobile-first approach */
.quest-card {
  @apply w-full md:w-1/2 lg:w-1/3;
}

/* Touch-friendly interactions */
.button {
  @apply min-h-[44px] min-w-[44px];
}

/* Responsive typography */
.title {
  @apply text-lg md:text-xl lg:text-2xl;
}
```

### Progressive Web App

```json
// manifest.json
{
  "name": "MoveHub",
  "short_name": "MoveHub",
  "description": "On-chain learning platform for Move developers",
  "start_url": "/",
  "display": "standalone",
  "theme_color": "#0ea5e9",
  "background_color": "#ffffff"
}
```

## 🌐 Internationalization

### Multi-language Support

```typescript
// i18n configuration
const i18n = {
  en: {
    'quest.title': 'Available Quests',
    'user.profile': 'Your Profile',
    'mentorship.title': 'Mentorship',
  },
  es: {
    'quest.title': 'Misiones Disponibles',
    'user.profile': 'Tu Perfil',
    'mentorship.title': 'Mentoría',
  }
}
```

## 🔧 Development Tools

### Smart Contract Development

- **Aptos CLI**: Contract compilation and deployment
- **Move Analyzer**: Code analysis and linting
- **Move Prover**: Formal verification
- **Aptos Explorer**: Transaction and account inspection

### Frontend Development

- **Next.js DevTools**: Development server and hot reload
- **TypeScript**: Type checking and IntelliSense
- **ESLint**: Code linting and formatting
- **Prettier**: Code formatting
- **Tailwind CSS**: Utility-first styling

### Testing Tools

- **Jest**: Unit testing framework
- **React Testing Library**: Component testing
- **Playwright**: End-to-end testing
- **Move Test Framework**: Smart contract testing

## 📊 Monitoring and Analytics

### Smart Contract Monitoring

- **Transaction Monitoring**: Track all contract interactions
- **Event Monitoring**: Monitor emitted events
- **Error Tracking**: Track and analyze errors
- **Performance Metrics**: Gas usage and execution time

### Frontend Monitoring

- **Error Tracking**: Sentry integration
- **Performance Monitoring**: Core Web Vitals
- **User Analytics**: User behavior tracking
- **Real User Monitoring**: Performance in production

## 🚀 Future Enhancements

### Planned Features

1. **NFT Badges**: Achievement badges for quest completions
2. **Advanced Analytics**: Machine learning insights
3. **Mobile App**: Native mobile application
4. **API Gateway**: RESTful API for external integrations
5. **Multi-chain Support**: Support for other blockchains

### Technical Improvements

1. **Optimistic Updates**: Instant UI updates
2. **Off-chain Storage**: IPFS integration for large data
3. **Layer 2 Integration**: Optimized transaction costs
4. **Advanced Caching**: Redis integration
5. **Real-time Updates**: WebSocket integration

---

This technical specification provides a comprehensive overview of the MoveHub platform architecture, implementation details, and development guidelines. The modular design ensures scalability, maintainability, and extensibility for future enhancements.
