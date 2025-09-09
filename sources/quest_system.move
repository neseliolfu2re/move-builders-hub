module movehub::quest_system {
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::event;

    // Error codes
    const E_NOT_INITIALIZED: u64 = 1;
    const E_ALREADY_COMPLETED: u64 = 2;
    const E_INVALID_QUEST: u64 = 3;
    const E_UNAUTHORIZED: u64 = 4;

    // Quest difficulty levels
    const DIFFICULTY_BEGINNER: u8 = 1;
    const DIFFICULTY_INTERMEDIATE: u8 = 2;
    const DIFFICULTY_ADVANCED: u8 = 3;

    // Quest structure
    struct Quest has copy, drop, store {
        id: u64,
        title: String,
        description: String,
        difficulty: u8,
        reward_amount: u64,
        is_active: bool,
    }

    // User quest completion record
    struct QuestCompletion has copy, drop, store {
        quest_id: u64,
        completed_at: u64,
        tx_hash: String,
    }

    // User profile
    struct UserProfile has key {
        wallet_address: address,
        completed_quests: vector<QuestCompletion>,
        total_completed: u64,
        total_rewards: u64,
        streak: u64,
        last_activity: u64,
        badges: vector<String>,
    }

    // Global quest registry
    struct QuestRegistry has key {
        quests: vector<Quest>,
        total_completions: u64,
        total_users: u64,
    }

    // Events
    struct QuestCompletedEvent has drop, store {
        user: address,
        quest_id: u64,
        timestamp: u64,
        reward: u64,
    }

    struct NewUserEvent has drop, store {
        user: address,
        timestamp: u64,
    }

    // Initialize the quest system (called once by admin)
    public entry fun initialize(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        
        // Create initial quests
        let quests = vector::empty<Quest>();
        
        vector::push_back(&mut quests, Quest {
            id: 1,
            title: string::utf8(b"Basic Move Syntax"),
            description: string::utf8(b"Learn Move basics: variables, functions, types"),
            difficulty: DIFFICULTY_BEGINNER,
            reward_amount: 10000000, // 0.1 APT
            is_active: true,
        });

        vector::push_back(&mut quests, Quest {
            id: 2,
            title: string::utf8(b"Struct & Functions"),
            description: string::utf8(b"Structs, public functions, and modular design"),
            difficulty: DIFFICULTY_INTERMEDIATE,
            reward_amount: 20000000, // 0.2 APT
            is_active: true,
        });

        vector::push_back(&mut quests, Quest {
            id: 3,
            title: string::utf8(b"Resource Model"),
            description: string::utf8(b"Resource safety, abilities, and ownership model"),
            difficulty: DIFFICULTY_ADVANCED,
            reward_amount: 40000000, // 0.4 APT
            is_active: true,
        });

        vector::push_back(&mut quests, Quest {
            id: 4,
            title: string::utf8(b"Control Flow"),
            description: string::utf8(b"Conditionals, loops, and patterns"),
            difficulty: DIFFICULTY_BEGINNER,
            reward_amount: 12000000, // 0.12 APT
            is_active: true,
        });

        vector::push_back(&mut quests, Quest {
            id: 5,
            title: string::utf8(b"Modules"),
            description: string::utf8(b"Module design, visibility, dependencies"),
            difficulty: DIFFICULTY_INTERMEDIATE,
            reward_amount: 25000000, // 0.25 APT
            is_active: true,
        });

        vector::push_back(&mut quests, Quest {
            id: 6,
            title: string::utf8(b"Security"),
            description: string::utf8(b"Security best practices, testing, and reviews"),
            difficulty: DIFFICULTY_ADVANCED,
            reward_amount: 50000000, // 0.5 APT
            is_active: true,
        });

        move_to(admin, QuestRegistry {
            quests,
            total_completions: 0,
            total_users: 0,
        });
    }

    // Initialize user profile
    public entry fun initialize_user(user: &signer) {
        let user_addr = signer::address_of(user);
        
        if (!exists<UserProfile>(user_addr)) {
            move_to(user, UserProfile {
                wallet_address: user_addr,
                completed_quests: vector::empty<QuestCompletion>(),
                total_completed: 0,
                total_rewards: 0,
                streak: 0,
                last_activity: timestamp::now_seconds(),
                badges: vector::empty<String>(),
            });

            // Increment total users
            let registry = borrow_global_mut<QuestRegistry>(@movehub);
            registry.total_users = registry.total_users + 1;

            // Emit new user event
            event::emit(NewUserEvent {
                user: user_addr,
                timestamp: timestamp::now_seconds(),
            });
        }
    }

    // Complete a quest
    public entry fun complete_quest(
        user: &signer, 
        quest_id: u64,
        tx_hash: String
    ) acquires UserProfile, QuestRegistry {
        let user_addr = signer::address_of(user);
        
        // Ensure user profile exists
        if (!exists<UserProfile>(user_addr)) {
            initialize_user(user);
        };

        let user_profile = borrow_global_mut<UserProfile>(user_addr);
        let registry = borrow_global_mut<QuestRegistry>(@movehub);

        // Find the quest
        let quest_opt = find_quest(&registry.quests, quest_id);
        assert!(vector::length(&quest_opt) > 0, E_INVALID_QUEST);
        let quest = *vector::borrow(&quest_opt, 0);

        // Check if already completed
        assert!(!is_quest_completed(&user_profile.completed_quests, quest_id), E_ALREADY_COMPLETED);

        // Record completion
        let completion = QuestCompletion {
            quest_id,
            completed_at: timestamp::now_seconds(),
            tx_hash,
        };

        vector::push_back(&mut user_profile.completed_quests, completion);
        user_profile.total_completed = user_profile.total_completed + 1;
        user_profile.total_rewards = user_profile.total_rewards + quest.reward_amount;
        user_profile.last_activity = timestamp::now_seconds();

        // Update streak (simplified logic)
        user_profile.streak = user_profile.streak + 1;

        // Award badges
        award_badges(user_profile);

        // Update global stats
        registry.total_completions = registry.total_completions + 1;

        // Emit completion event
        event::emit(QuestCompletedEvent {
            user: user_addr,
            quest_id,
            timestamp: timestamp::now_seconds(),
            reward: quest.reward_amount,
        });
    }

    // Helper function to find quest by ID
    fun find_quest(quests: &vector<Quest>, quest_id: u64): vector<Quest> {
        let result = vector::empty<Quest>();
        let i = 0;
        let len = vector::length(quests);
        
        while (i < len) {
            let quest = vector::borrow(quests, i);
            if (quest.id == quest_id) {
                vector::push_back(&mut result, *quest);
                break
            };
            i = i + 1;
        };
        
        result
    }

    // Check if quest is already completed
    fun is_quest_completed(completions: &vector<QuestCompletion>, quest_id: u64): bool {
        let i = 0;
        let len = vector::length(completions);
        
        while (i < len) {
            let completion = vector::borrow(completions, i);
            if (completion.quest_id == quest_id) {
                return true
            };
            i = i + 1;
        };
        
        false
    }

    // Award badges based on achievements
    fun award_badges(user_profile: &mut UserProfile) {
        let completed = user_profile.total_completed;
        
        // First Quest badge
        if (completed >= 1 && !has_badge(&user_profile.badges, string::utf8(b"First Quest"))) {
            vector::push_back(&mut user_profile.badges, string::utf8(b"First Quest"));
        };

        // Quest Master badge
        if (completed >= 5 && !has_badge(&user_profile.badges, string::utf8(b"Quest Master"))) {
            vector::push_back(&mut user_profile.badges, string::utf8(b"Quest Master"));
        };

        // Move Expert badge
        if (completed >= 10 && !has_badge(&user_profile.badges, string::utf8(b"Move Expert"))) {
            vector::push_back(&mut user_profile.badges, string::utf8(b"Move Expert"));
        };
    }

    // Check if user has a specific badge
    fun has_badge(badges: &vector<String>, badge_name: String): bool {
        let i = 0;
        let len = vector::length(badges);
        
        while (i < len) {
            let badge = vector::borrow(badges, i);
            if (*badge == badge_name) {
                return true
            };
            i = i + 1;
        };
        
        false
    }

    // View functions
    #[view]
    public fun get_user_profile(user_addr: address): (u64, u64, u64, u64) acquires UserProfile {
        if (!exists<UserProfile>(user_addr)) {
            return (0, 0, 0, 0)
        };
        
        let profile = borrow_global<UserProfile>(user_addr);
        (
            profile.total_completed,
            profile.total_rewards,
            profile.streak,
            profile.last_activity
        )
    }

    #[view]
    public fun get_global_stats(): (u64, u64) acquires QuestRegistry {
        let registry = borrow_global<QuestRegistry>(@movehub);
        (registry.total_completions, registry.total_users)
    }

    #[view]
    public fun get_quest_count(): u64 acquires QuestRegistry {
        let registry = borrow_global<QuestRegistry>(@movehub);
        vector::length(&registry.quests)
    }
}
