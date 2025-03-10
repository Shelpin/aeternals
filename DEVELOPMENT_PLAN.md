# Multi-Bot Telegram System Development Plan

## Overview
This document outlines the development plan for implementing a multi-bot system within ElizaOS, focusing on creating an engaging, autonomous multi-bot ecosystem for Telegram groups.

## Project Timeline
Note: The phases described below are logical development units. In YOLO mode with AI assistance, these can be implemented much faster than traditional development timelines. Each "week" represents a logical phase rather than actual calendar time.

## Phase 1: Foundation Setup (1-2 hours)
Core infrastructure implementation focusing on:

### State Management System
```typescript
interface StateManager {
  // Shared state between processes
  sharedState: SharedStateStore;
  // Process-specific state
  localState: Map<string, BotState>;
  
  // Methods
  updateSharedState(update: Partial<SharedState>): Promise<void>;
  getConversationState(): Promise<ConversationState>;
  isConversationActive(): boolean;
}
```

### Inter-Process Communication Layer
```typescript
interface IPCManager {
  // Event broadcasting
  broadcast(event: BotEvent): Promise<void>;
  subscribe(eventType: string, handler: EventHandler): void;
  
  // State synchronization
  syncState(botId: string): Promise<void>;
  notifyStateChange(change: StateChange): Promise<void>;
}
```

## Phase 2: Core Features Implementation (2-3 hours)

### Conversation Manager
- Message counting and limits
- Natural conversation endings
- Context maintenance
- Topic tracking

### Auto-posting System
- Scheduling with timing controls (65min - 24h intervals)
- Coordination between bots
- Content queue management

### User Interaction System
- Activity tracking
- Smart user selection
- 24h cooldown management per user

## Phase 3: Bot Personality Integration (2-3 hours)

### Character System
```typescript
interface BotCharacter {
  personality: PersonalityType;
  interests: string[];
  responseStyle: StyleGuide;
  triggerTopics: string[];
  autopostFrequency: number;
}
```

### Response Generator
- Context-aware responses
- Personality-driven interactions
- Natural language processing

## Character Enhancement & Knowledge Integration

### Character-Specific Enhancements

1. **ETHMemeLord9000**
```typescript
const ethMemeLordProfile: EnhancedCharacter = {
  core: {
    name: "ETHMemeLord9000",
    role: "Ethereum Enthusiast & Meme Creator",
    background: "Early ETH adopter, DeFi expert, meme culture specialist",
    expertise: ["Ethereum", "DeFi", "NFTs", "Meme Culture", "Trading"],
    traits: ["Humorous", "Tech-Savvy", "Optimistic", "Trend-Aware"]
  },
  knowledge: {
    primaryDomains: ["Ethereum Ecosystem", "DeFi Protocols", "NFT Markets"],
    sources: [
      { url: "https://ethereum.org/en/", updateFrequency: "daily" },
      { url: "https://defillama.com/", updateFrequency: "hourly" },
      { url: "https://etherscan.io/", updateFrequency: "realtime" }
    ]
  }
};
```

2. **BitcoinMaxi420**
```typescript
const bitcoinMaxiProfile: EnhancedCharacter = {
  core: {
    name: "BitcoinMaxi420",
    role: "Bitcoin Maximalist & Crypto Purist",
    background: "Long-term Bitcoin holder, Lightning Network enthusiast",
    expertise: ["Bitcoin", "Lightning Network", "Monetary Theory"],
    traits: ["Passionate", "Skeptical of Altcoins", "Security-Focused"]
  },
  knowledge: {
    primaryDomains: ["Bitcoin Protocol", "Lightning Network", "Austrian Economics"],
    sources: [
      { url: "https://bitcoin.org/", updateFrequency: "daily" },
      { url: "https://mempool.space/", updateFrequency: "realtime" },
      { url: "https://lightning.network/", updateFrequency: "daily" }
    ]
  }
};
```

3. **CodeSamurai77**
```typescript
const codeSamuraiProfile: EnhancedCharacter = {
  core: {
    name: "CodeSamurai77",
    role: "Blockchain Developer & Technical Expert",
    background: "Smart contract auditor, protocol developer",
    expertise: ["Smart Contracts", "Protocol Design", "Security"],
    traits: ["Analytical", "Detail-Oriented", "Security-Conscious"]
  },
  knowledge: {
    primaryDomains: ["Smart Contract Development", "Blockchain Security", "Protocol Design"],
    sources: [
      { url: "https://docs.soliditylang.org/", updateFrequency: "daily" },
      { url: "https://github.com/aeternity", updateFrequency: "hourly" },
      { url: "https://consensys.io/diligence/blog", updateFrequency: "daily" }
    ]
  }
};
```

### Knowledge Integration Pipeline

1. **Source Management**
```typescript
interface KnowledgeSourceConfig {
  characters: {
    [characterId: string]: {
      sources: KnowledgeSource[];
      updateSchedule: UpdateSchedule;
      processingPriority: Priority;
    }
  };
  
  globalSources: {
    [domain: string]: KnowledgeSource[];
  };
  
  processingConfig: {
    chunkSize: number;
    overlapSize: number;
    embeddingModel: string;
    updateFrequency: UpdateFrequency;
  };
}
```

2. **Knowledge Processing Flow**
```
URL/Content Source
      ↓
Content Extraction
      ↓
Text Chunking & Processing
      ↓
Embedding Generation (Using ElizaOS's built-in embedding system)
      ↓
Vector Storage (Qdrant/Postgres with pgvector)
      ↓
Character-Specific Knowledge Base
```

### Enhanced RAG Memory System

1. **Memory Types**
```typescript
interface CharacterMemory {
  // Conversation memory
  conversations: {
    recent: ConversationThread[];  // Last 24 hours
    significant: ConversationHighlight[];  // Important interactions
    userSpecific: Map<UserId, UserInteraction[]>;
  };
  
  // Knowledge memory
  knowledge: {
    factual: VectorStore;  // Embedded knowledge from sources
    learned: LearnedConcept[];  // Insights from conversations
    temporary: CacheStore;  // Short-term relevant info
  };
  
  // Personality memory
  personality: {
    traits: PersonalityTrait[];
    adaptations: BehaviorAdaptation[];
    preferences: InteractionPreference[];
  };
}
```

2. **Memory Integration with Response Generation**
```typescript
class ResponseGenerator {
  async generateResponse(input: Message, character: Character): Promise<Response> {
    // 1. Gather context
    const conversationMemory = await this.getRelevantConversations(input);
    const knowledgeContext = await this.retrieveRelevantKnowledge(input);
    const personalityContext = character.getPersonalityContext();
    
    // 2. Build response context
    const context = this.buildContext({
      conversation: conversationMemory,
      knowledge: knowledgeContext,
      personality: personalityContext,
      currentState: await this.getCurrentState()
    });
    
    // 3. Generate and refine response
    const response = await this.generateInitialResponse(context);
    const refinedResponse = await this.applyPersonalityFilters(response, character);
    
    // 4. Update memory
    await this.updateMemory(input, response, context);
    
    return refinedResponse;
  }
}
```

### Implementation Approach

1. **Character Enhancement Phase**
   - Update all 6 character files with enhanced profiles
   - Add knowledge source configurations
   - Implement personality traits and behaviors
   - Time: 1-2 hours

2. **Knowledge Integration Phase**
   - Set up knowledge ingestion pipeline
   - Configure source crawling and processing
   - Implement vector storage system
   - Time: 2-3 hours

3. **Memory System Phase**
   - Implement RAG architecture
   - Set up memory management
   - Create context retrieval system
   - Time: 2-3 hours

4. **Integration & Testing Phase**
   - Combine all systems
   - Test with real conversations
   - Optimize response generation
   - Time: 1-2 hours

### Success Criteria for Enhanced System

1. **Character Depth**
   - Each character maintains consistent personality
   - Responses reflect knowledge domains
   - Natural conversation style
   - Appropriate use of domain expertise

2. **Knowledge Integration**
   - Up-to-date information from sources
   - Relevant knowledge in responses
   - Proper source attribution
   - Regular knowledge updates

3. **Memory Effectiveness**
   - Consistent conversation context
   - Relevant information recall
   - Natural conversation flow
   - Appropriate reference to past interactions

## Implementation Strategy

### Step 1: Basic Infrastructure (1-2 hours)
- [  ] Set up ElizaOS plugin structure
- [  ] Implement basic state management
- [  ] Create IPC system
- [  ] Basic bot process management

### Step 2: Core Features (2-3 hours)
- [  ] Implement conversation management
- [  ] Add autoposting system
- [  ] Develop user interaction tracking
- [  ] Basic coordination between bots

### Step 3: Enhanced Features (2-3 hours)
- [  ] Add personality-driven responses
- [  ] Implement smart user tagging
- [  ] Add conversation flow control
- [  ] Develop topic management

### Step 4: Testing & Stabilization (1-2 hours)
- [  ] Load testing
- [  ] Conversation flow testing
- [  ] Bot interaction testing
- [  ] System stability verification

## Technical Implementation Details

### 1. Plugin Structure
```typescript
export const telegramMultiBotPlugin: Plugin = {
  name: 'telegram-multi-bot',
  version: '1.0.0',
  
  // Core components
  stateManager: new StateManager(),
  ipcManager: new IPCManager(),
  
  // Bot management
  botManager: new BotManager(),
  
  // Systems
  conversationSystem: new ConversationSystem(),
  autopostSystem: new AutopostSystem(),
  userInteractionSystem: new UserInteractionSystem()
};
```

### 2. Process Management
```typescript
class BotManager {
  // Bot lifecycle
  async startBot(config: BotConfig): Promise<void>;
  async stopBot(botId: string): Promise<void>;
  
  // State management
  async getBotState(botId: string): Promise<BotState>;
  async updateBotState(botId: string, state: Partial<BotState>): Promise<void>;
  
  // Coordination
  async coordinateAutopost(botId: string): Promise<boolean>;
  async checkConversationAvailability(): Promise<boolean>;
}
```

### 3. Conversation Control
```typescript
class ConversationSystem {
  readonly MAX_MESSAGES = 10;
  readonly COOLDOWN_PERIOD = 24 * 60 * 60 * 1000;  // 24 hours
  
  async startConversation(topic: string): Promise<void>;
  async addMessage(message: Message): Promise<void>;
  async shouldEndConversation(): Promise<boolean>;
  async getActiveParticipants(): Promise<string[]>;
}
```

## Testing Strategy

### Unit Tests
- State management
- Bot coordination
- Message limits
- Cooldown system

### Integration Tests
- Multi-bot conversations
- Autoposting coordination
- User interaction flow
- State synchronization

### System Tests
- Full conversation cycles
- Load handling
- Recovery from failures
- Long-running stability

## Timeline Clarification
In YOLO mode with AI assistance, the entire implementation can be completed in approximately 6-10 hours of focused development:

1. Foundation Setup: 1-2 hours
2. Core Features: 2-3 hours
3. Bot Personality Integration: 2-3 hours
4. Testing & Stabilization: 1-2 hours

This accelerated timeline is possible because:
- AI assistance enables rapid code generation and debugging
- YOLO mode allows for aggressive feature implementation
- The ElizaOS plugin architecture provides many built-in capabilities
- We can iterate and improve after the basic system is working

## Next Steps
1. Confirm this development plan
2. Begin Phase 1 implementation
3. Rapid iteration through phases
4. Continuous testing and refinement

## Success Criteria
- All 6 bots running stably
- Natural conversation flow
- Proper autoposting timing
- Effective user engagement
- No system crashes or hangs
- Clean process management 

### Knowledge Storage & Retrieval System

1. **SQLite-based Vector Storage**
```typescript
interface SQLiteVectorStore {
  // Database schema
  tables: {
    embeddings: {
      id: string;
      text: string;
      embedding: Buffer;  // Store embeddings as binary
      source_url: string;
      character_id: string;
      timestamp: number;
    },
    chunks: {
      id: string;
      text: string;
      source_url: string;
      processed: boolean;
      timestamp: number;
    }
  };
  
  // Methods
  async storeEmbedding(text: string, embedding: number[], metadata: EmbeddingMetadata): Promise<void>;
  async searchSimilar(query: string, limit: number): Promise<SearchResult[]>;
  async pruneOldEmbeddings(maxAge: number): Promise<void>;
}
```

2. **Simplified URL Knowledge Retrieval**
```typescript
class URLKnowledgeManager {
  // URL content fetching
  async fetchContent(url: string): Promise<string> {
    const response = await fetch(url);
    const html = await response.text();
    return this.extractMainContent(html);
  }
  
  // Content processing
  async processURL(url: string, characterId: string): Promise<void> {
    // 1. Fetch and extract content
    const content = await this.fetchContent(url);
    
    // 2. Split into chunks
    const chunks = this.splitIntoChunks(content, {
      maxChunkSize: 500,
      overlap: 50
    });
    
    // 3. Store raw chunks
    await this.storeChunks(chunks, url, characterId);
    
    // 4. Process chunks into embeddings (background)
    this.scheduleEmbeddingGeneration(chunks, characterId);
  }
  
  // Background processing
  private async scheduleEmbeddingGeneration(chunks: string[], characterId: string): Promise<void> {
    for (const chunk of chunks) {
      // Use ElizaOS's built-in embedding system
      const embedding = await this.generateEmbedding(chunk);
      await this.vectorStore.storeEmbedding(chunk, embedding, {
        characterId,
        timestamp: Date.now()
      });
    }
  }
}
```

3. **Knowledge Update System**
```typescript
class KnowledgeUpdateManager {
  // Update scheduling
  private updateSchedules = new Map<string, UpdateConfig>();
  
  // Add URL to update schedule
  async scheduleURLUpdate(url: string, frequency: UpdateFrequency): Promise<void> {
    const schedule = {
      url,
      frequency,
      lastUpdate: Date.now(),
      nextUpdate: this.calculateNextUpdate(frequency)
    };
    this.updateSchedules.set(url, schedule);
  }
  
  // Regular update check
  async checkForUpdates(): Promise<void> {
    const now = Date.now();
    for (const [url, schedule] of this.updateSchedules.entries()) {
      if (now >= schedule.nextUpdate) {
        await this.updateURL(url);
        schedule.lastUpdate = now;
        schedule.nextUpdate = this.calculateNextUpdate(schedule.frequency);
      }
    }
  }
}
```

4. **Simple Query Interface**
```typescript
class KnowledgeQuery {
  constructor(private vectorStore: SQLiteVectorStore) {}
  
  // Query knowledge base
  async query(question: string, characterId: string): Promise<QueryResult> {
    // 1. Generate question embedding
    const questionEmbedding = await this.generateEmbedding(question);
    
    // 2. Find similar content
    const results = await this.vectorStore.searchSimilar(questionEmbedding, 5);
    
    // 3. Build context from results
    const context = this.buildContext(results);
    
    return {
      context,
      sources: results.map(r => r.source_url)
    };
  }
}
```

### Implementation Notes

1. **SQLite Advantages**
   - Simple setup, no external dependencies
   - Single file storage
   - Built-in full-text search
   - Efficient for our scale
   - Easy backup and maintenance

2. **URL Processing Strategy**
   - Fetch content in background
   - Process and store incrementally
   - Update on schedule or demand
   - Maintain source attribution

3. **Memory Optimization**
   - Prune old embeddings periodically
   - Keep recent content in memory cache
   - Background processing of updates
   - Efficient binary storage of embeddings

4. **Query Performance**
   - Index frequently accessed content
   - Cache common queries
   - Batch embedding generation
   - Progressive loading of results

### Usage Example
```typescript
// Initialize systems
const vectorStore = new SQLiteVectorStore('knowledge.db');
const urlManager = new URLKnowledgeManager(vectorStore);
const queryInterface = new KnowledgeQuery(vectorStore);

// Add knowledge source
await urlManager.processURL('https://ethereum.org/en/', 'ETHMemeLord9000');

// Query knowledge
const result = await queryInterface.query(
  'What are the latest developments in Ethereum?',
  'ETHMemeLord9000'
);

console.log('Context:', result.context);
console.log('Sources:', result.sources);
``` 