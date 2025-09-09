module movehub::movehub {
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use std::table::{Self, Table};
    use std::option::{Self, Option};
    use aptos_framework::account;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;
    use aptos_framework::event::{Self, EventHandle};

    // Error codes
    const E_NOT_INITIALIZED: u64 = 1;
    const E_ALREADY_INITIALIZED: u64 = 2;
    const E_USER_NOT_FOUND: u64 = 3;
    const E_QUEST_NOT_FOUND: u64 = 4;
    const E_QUEST_ALREADY_COMPLETED: u64 = 5;
    const E_INVALID_QUEST_TYPE: u64 = 6;
    const E_INSUFFICIENT_PERMISSIONS: u64 = 7;
    const E_INVALID_SPONSOR: u64 = 8;
    const E_QUEST_EXPIRED: u64 = 9;
    const E_INVALID_MENTORSHIP: u64 = 10;

    // Quest types
    const QUEST_TYPE_TUTORIAL: u8 = 1;
    const QUEST_TYPE_CODING: u8 = 2;
    const QUEST_TYPE_COLLABORATION: u8 = 3;
    const QUEST_TYPE_MENTORSHIP: u8 = 4;
    const QUEST_TYPE_HACKATHON: u8 = 5;

    // Quest status
    const QUEST_STATUS_ACTIVE: u8 = 1;
    const QUEST_STATUS_COMPLETED: u8 = 2;
    const QUEST_STATUS_EXPIRED: u8 = 3;

    // User profile structure
    struct UserProfile has key, store, copy, drop {
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

    // Quest structure
    struct Quest has key, store, copy, drop {
        id: u64,
        title: String,
        description: String,
        quest_type: u8,
        difficulty: u8, // 1-5 scale
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

    // Quest completion record
    struct QuestCompletion has key, store, copy, drop {
        quest_id: u64,
        user: address,
        completed_at: u64,
        proof_of_completion: String,
        mentor_feedback: Option<String>,
        collaboration_partners: vector<address>,
    }

    // Mentorship session
    struct MentorshipSession has key, store, copy, drop {
        id: u64,
        mentor: address,
        mentee: address,
        topic: String,
        scheduled_at: u64,
        duration_minutes: u64,
        status: u8, // 1: scheduled, 2: completed, 3: cancelled
        feedback: Option<String>,
    }

    // Collaboration session
    struct CollaborationSession has key, store, copy, drop {
        id: u64,
        participants: vector<address>,
        quest_id: Option<u64>,
        topic: String,
        started_at: u64,
        ended_at: Option<u64>,
        status: u8, // 1: active, 2: completed, 3: cancelled
    }

    // Main storage structure
    struct MoveHub has key {
        admin: address,
        total_users: u64,
        total_quests: u64,
        total_mentorships: u64,
        total_collaborations: u64,
        users: Table<address, UserProfile>,
        quests: Table<u64, Quest>,
        quest_completions: Table<u64, vector<QuestCompletion>>,
        mentorship_sessions: Table<u64, MentorshipSession>,
        collaboration_sessions: Table<u64, CollaborationSession>,
        user_quest_completions: Table<address, vector<u64>>,
        user_mentorships: Table<address, vector<u64>>,
        user_collaborations: Table<address, vector<u64>>,
        // Event handles
        user_registered_events: EventHandle<UserRegisteredEvent>,
        quest_created_events: EventHandle<QuestCreatedEvent>,
        quest_completed_events: EventHandle<QuestCompletedEvent>,
        mentorship_scheduled_events: EventHandle<MentorshipScheduledEvent>,
        collaboration_started_events: EventHandle<CollaborationStartedEvent>,
    }

    // Event structures
    struct UserRegisteredEvent has store, drop {
        user: address,
        username: String,
        timestamp: u64,
    }

    struct QuestCreatedEvent has store, drop {
        quest_id: u64,
        title: String,
        quest_type: u8,
        sponsor: address,
        timestamp: u64,
    }

    struct QuestCompletedEvent has store, drop {
        quest_id: u64,
        user: address,
        timestamp: u64,
    }

    struct MentorshipScheduledEvent has store, drop {
        session_id: u64,
        mentor: address,
        mentee: address,
        topic: String,
        timestamp: u64,
    }

    struct CollaborationStartedEvent has store, drop {
        session_id: u64,
        participants: vector<address>,
        topic: String,
        timestamp: u64,
    }

    // Initialize the MoveHub platform
    public entry fun initialize(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        
        move_to(admin, MoveHub {
            admin: admin_addr,
            total_users: 0,
            total_quests: 0,
            total_mentorships: 0,
            total_collaborations: 0,
            users: table::new(),
            quests: table::new(),
            quest_completions: table::new(),
            mentorship_sessions: table::new(),
            collaboration_sessions: table::new(),
            user_quest_completions: table::new(),
            user_mentorships: table::new(),
            user_collaborations: table::new(),
            user_registered_events: account::new_event_handle<UserRegisteredEvent>(admin),
            quest_created_events: account::new_event_handle<QuestCreatedEvent>(admin),
            quest_completed_events: account::new_event_handle<QuestCompletedEvent>(admin),
            mentorship_scheduled_events: account::new_event_handle<MentorshipScheduledEvent>(admin),
            collaboration_started_events: account::new_event_handle<CollaborationStartedEvent>(admin),
        });
    }

    // User registration
    public entry fun register_user(
        user: &signer,
        username: String,
        bio: String,
        skills: vector<String>,
    ) acquires MoveHub {
        let user_addr = signer::address_of(user);
        let movehub = borrow_global_mut<MoveHub>(@movehub);
        
        // Check if user already exists
        assert!(!table::contains(&movehub.users, user_addr), E_ALREADY_INITIALIZED);
        
        let current_time = timestamp::now_seconds();
        
        let profile = UserProfile {
            username,
            bio,
            skills,
            join_date: current_time,
            total_quests_completed: 0,
            current_streak: 0,
            longest_streak: 0,
            mentorship_sessions: 0,
            collaboration_sessions: 0,
            reputation_score: 0,
            is_mentor: false,
            is_sponsor: false,
        };
        
        table::add(&mut movehub.users, user_addr, profile);
        table::add(&mut movehub.user_quest_completions, user_addr, vector::empty());
        table::add(&mut movehub.user_mentorships, user_addr, vector::empty());
        table::add(&mut movehub.user_collaborations, user_addr, vector::empty());
        
        movehub.total_users = movehub.total_users + 1;
        
        // Emit event
        event::emit_event(&mut movehub.user_registered_events, UserRegisteredEvent {
            user: user_addr,
            username,
            timestamp: current_time,
        });
    }

    // Create a new quest
    public entry fun create_quest(
        creator: &signer,
        title: String,
        description: String,
        quest_type: u8,
        difficulty: u8,
        reward_amount: u64,
        expires_at: Option<u64>,
        max_completions: Option<u64>,
        requirements: vector<String>,
        tags: vector<String>,
    ) acquires MoveHub {
        let creator_addr = signer::address_of(creator);
        let movehub = borrow_global_mut<MoveHub>(@movehub);
        
        // Validate quest type
        assert!(quest_type >= QUEST_TYPE_TUTORIAL && quest_type <= QUEST_TYPE_HACKATHON, E_INVALID_QUEST_TYPE);
        
        let quest_id = movehub.total_quests + 1;
        let current_time = timestamp::now_seconds();
        
        let quest = Quest {
            id: quest_id,
            title,
            description,
            quest_type,
            difficulty,
            reward_amount,
            sponsor: creator_addr,
            created_at: current_time,
            expires_at,
            status: QUEST_STATUS_ACTIVE,
            completion_count: 0,
            max_completions,
            requirements,
            tags,
        };
        
        table::add(&mut movehub.quests, quest_id, quest);
        table::add(&mut movehub.quest_completions, quest_id, vector::empty());
        
        movehub.total_quests = quest_id;
        
        // Emit event
        event::emit_event(&mut movehub.quest_created_events, QuestCreatedEvent {
            quest_id,
            title,
            quest_type,
            sponsor: creator_addr,
            timestamp: current_time,
        });
    }

    // Complete a quest
    public entry fun complete_quest(
        user: &signer,
        quest_id: u64,
        proof_of_completion: String,
        collaboration_partners: vector<address>,
    ) acquires MoveHub {
        let user_addr = signer::address_of(user);
        let movehub = borrow_global_mut<MoveHub>(@movehub);
        
        // Check if user exists
        assert!(table::contains(&movehub.users, user_addr), E_USER_NOT_FOUND);
        
        // Check if quest exists
        assert!(table::contains(&movehub.quests, quest_id), E_QUEST_NOT_FOUND);
        
        let quest = table::borrow_mut(&mut movehub.quests, quest_id);
        
        // Check if quest is still active
        assert!(quest.status == QUEST_STATUS_ACTIVE, E_QUEST_NOT_FOUND);
        
        // Check if quest has expired
        if (option::is_some(&quest.expires_at)) {
            let expires_at = *option::borrow(&quest.expires_at);
            let current_time = timestamp::now_seconds();
            assert!(current_time <= expires_at, E_QUEST_EXPIRED);
        };
        
        // Check if quest has reached max completions
        if (option::is_some(&quest.max_completions)) {
            let max_completions = *option::borrow(&quest.max_completions);
            assert!(quest.completion_count < max_completions, E_QUEST_ALREADY_COMPLETED);
        };
        
        // Check if user already completed this quest
        let user_completions = table::borrow(&movehub.user_quest_completions, user_addr);
        let i = 0;
        let len = vector::length(user_completions);
        while (i < len) {
            let completed_quest_id = *vector::borrow(user_completions, i);
            assert!(completed_quest_id != quest_id, E_QUEST_ALREADY_COMPLETED);
            i = i + 1;
        };
        
        let current_time = timestamp::now_seconds();
        
        // Create completion record
        let completion = QuestCompletion {
            quest_id,
            user: user_addr,
            completed_at: current_time,
            proof_of_completion,
            mentor_feedback: option::none(),
            collaboration_partners,
        };
        
        // Add completion to quest
        let quest_completions = table::borrow_mut(&mut movehub.quest_completions, quest_id);
        vector::push_back(quest_completions, completion);
        
        // Add quest to user's completed quests
        let user_completions = table::borrow_mut(&mut movehub.user_quest_completions, user_addr);
        vector::push_back(user_completions, quest_id);
        
        // Update quest completion count
        quest.completion_count = quest.completion_count + 1;
        
        // Update user profile
        let user_profile = table::borrow_mut(&mut movehub.users, user_addr);
        user_profile.total_quests_completed = user_profile.total_quests_completed + 1;
        user_profile.current_streak = user_profile.current_streak + 1;
        
        if (user_profile.current_streak > user_profile.longest_streak) {
            user_profile.longest_streak = user_profile.current_streak;
        };
        
        // Update reputation score based on quest difficulty
        user_profile.reputation_score = user_profile.reputation_score + ((quest.difficulty as u64) * 10);
        
        // Emit event
        event::emit_event(&mut movehub.quest_completed_events, QuestCompletedEvent {
            quest_id,
            user: user_addr,
            timestamp: current_time,
        });
    }

    // Schedule a mentorship session
    public entry fun schedule_mentorship(
        mentor: &signer,
        mentee: address,
        topic: String,
        scheduled_at: u64,
        duration_minutes: u64,
    ) acquires MoveHub {
        let mentor_addr = signer::address_of(mentor);
        let movehub = borrow_global_mut<MoveHub>(@movehub);
        
        // Check if both users exist
        assert!(table::contains(&movehub.users, mentor_addr), E_USER_NOT_FOUND);
        assert!(table::contains(&movehub.users, mentee), E_USER_NOT_FOUND);
        
        let mentor_profile = table::borrow(&movehub.users, mentor_addr);
        assert!(mentor_profile.is_mentor, E_INSUFFICIENT_PERMISSIONS);
        
        let session_id = movehub.total_mentorships + 1;
        
        let session = MentorshipSession {
            id: session_id,
            mentor: mentor_addr,
            mentee,
            topic,
            scheduled_at,
            duration_minutes,
            status: 1, // scheduled
            feedback: option::none(),
        };
        
        table::add(&mut movehub.mentorship_sessions, session_id, session);
        
        // Add to user's mentorship lists
        let mentor_sessions = table::borrow_mut(&mut movehub.user_mentorships, mentor_addr);
        vector::push_back(mentor_sessions, session_id);
        
        let mentee_sessions = table::borrow_mut(&mut movehub.user_mentorships, mentee);
        vector::push_back(mentee_sessions, session_id);
        
        movehub.total_mentorships = session_id;
        
        // Emit event
        event::emit_event(&mut movehub.mentorship_scheduled_events, MentorshipScheduledEvent {
            session_id,
            mentor: mentor_addr,
            mentee,
            topic,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Start a collaboration session
    public entry fun start_collaboration(
        initiator: &signer,
        participants: vector<address>,
        quest_id: Option<u64>,
        topic: String,
    ) acquires MoveHub {
        let initiator_addr = signer::address_of(initiator);
        let movehub = borrow_global_mut<MoveHub>(@movehub);
        
        // Check if initiator exists
        assert!(table::contains(&movehub.users, initiator_addr), E_USER_NOT_FOUND);
        
        // Add initiator to participants if not already included
        let i = 0;
        let len = vector::length(&participants);
        let initiator_included = false;
        while (i < len) {
            let participant = *vector::borrow(&participants, i);
            if (participant == initiator_addr) {
                initiator_included = true;
                break
            };
            i = i + 1;
        };
        
        let final_participants = if (initiator_included) {
            participants
        } else {
        let new_participants = participants;
        vector::push_back(&mut new_participants, initiator_addr);
        new_participants
        };
        
        let session_id = movehub.total_collaborations + 1;
        let current_time = timestamp::now_seconds();
        
        let session = CollaborationSession {
            id: session_id,
            participants: final_participants,
            quest_id,
            topic,
            started_at: current_time,
            ended_at: option::none(),
            status: 1, // active
        };
        
        table::add(&mut movehub.collaboration_sessions, session_id, session);
        
        // Add to each participant's collaboration list
        let i = 0;
        let len = vector::length(&final_participants);
        while (i < len) {
            let participant = *vector::borrow(&final_participants, i);
            let participant_sessions = table::borrow_mut(&mut movehub.user_collaborations, participant);
            vector::push_back(participant_sessions, session_id);
            i = i + 1;
        };
        
        movehub.total_collaborations = session_id;
        
        // Emit event
        event::emit_event(&mut movehub.collaboration_started_events, CollaborationStartedEvent {
            session_id,
            participants: final_participants,
            topic,
            timestamp: current_time,
        });
    }

    // Set user as mentor
    public entry fun set_mentor_status(
        admin: &signer,
        user: address,
        is_mentor: bool,
    ) acquires MoveHub {
        let admin_addr = signer::address_of(admin);
        let movehub = borrow_global_mut<MoveHub>(@movehub);
        
        assert!(admin_addr == movehub.admin, E_INSUFFICIENT_PERMISSIONS);
        assert!(table::contains(&movehub.users, user), E_USER_NOT_FOUND);
        
        let user_profile = table::borrow_mut(&mut movehub.users, user);
        user_profile.is_mentor = is_mentor;
    }

    // Set user as sponsor
    public entry fun set_sponsor_status(
        admin: &signer,
        user: address,
        is_sponsor: bool,
    ) acquires MoveHub {
        let admin_addr = signer::address_of(admin);
        let movehub = borrow_global_mut<MoveHub>(@movehub);
        
        assert!(admin_addr == movehub.admin, E_INSUFFICIENT_PERMISSIONS);
        assert!(table::contains(&movehub.users, user), E_USER_NOT_FOUND);
        
        let user_profile = table::borrow_mut(&mut movehub.users, user);
        user_profile.is_sponsor = is_sponsor;
    }

    // View functions
    public fun get_user_profile(user: address): UserProfile acquires MoveHub {
        let movehub = borrow_global<MoveHub>(@movehub);
        assert!(table::contains(&movehub.users, user), E_USER_NOT_FOUND);
        *table::borrow(&movehub.users, user)
    }

    public fun get_quest(quest_id: u64): Quest acquires MoveHub {
        let movehub = borrow_global<MoveHub>(@movehub);
        assert!(table::contains(&movehub.quests, quest_id), E_QUEST_NOT_FOUND);
        *table::borrow(&movehub.quests, quest_id)
    }

    public fun get_quest_completions(quest_id: u64): vector<QuestCompletion> acquires MoveHub {
        let movehub = borrow_global<MoveHub>(@movehub);
        assert!(table::contains(&movehub.quest_completions, quest_id), E_QUEST_NOT_FOUND);
        *table::borrow(&movehub.quest_completions, quest_id)
    }

    public fun get_user_quest_completions(user: address): vector<u64> acquires MoveHub {
        let movehub = borrow_global<MoveHub>(@movehub);
        assert!(table::contains(&movehub.user_quest_completions, user), E_USER_NOT_FOUND);
        *table::borrow(&movehub.user_quest_completions, user)
    }

    public fun get_mentorship_session(session_id: u64): MentorshipSession acquires MoveHub {
        let movehub = borrow_global<MoveHub>(@movehub);
        assert!(table::contains(&movehub.mentorship_sessions, session_id), E_INVALID_MENTORSHIP);
        *table::borrow(&movehub.mentorship_sessions, session_id)
    }

    public fun get_collaboration_session(session_id: u64): CollaborationSession acquires MoveHub {
        let movehub = borrow_global<MoveHub>(@movehub);
        assert!(table::contains(&movehub.collaboration_sessions, session_id), E_INVALID_MENTORSHIP);
        *table::borrow(&movehub.collaboration_sessions, session_id)
    }

    public fun get_platform_stats(): (u64, u64, u64, u64) acquires MoveHub {
        let movehub = borrow_global<MoveHub>(@movehub);
        (movehub.total_users, movehub.total_quests, movehub.total_mentorships, movehub.total_collaborations)
    }
}
