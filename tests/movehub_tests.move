#[test_only]
module movehub::movehub_tests {
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use std::option;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use movehub::movehub;

    // Test accounts
    const ADMIN: address = @0x1;
    const USER1: address = @0x2;
    const USER2: address = @0x3;
    const SPONSOR: address = @0x4;

    // Test helper functions
    fun setup_test(): (signer, signer, signer, signer) {
        let admin = account::create_account_for_test(ADMIN);
        let user1 = account::create_account_for_test(USER1);
        let user2 = account::create_account_for_test(USER2);
        let sponsor = account::create_account_for_test(SPONSOR);
        
        // Initialize the platform
        movehub::initialize(&admin);
        
        (admin, user1, user2, sponsor)
    }

    #[test(admin = @0x1, user1 = @0x2, user2 = @0x3, sponsor = @0x4)]
    fun test_platform_initialization(admin: &signer, user1: &signer, user2: &signer, sponsor: &signer) {
        // Initialize platform
        movehub::initialize(admin);
        
        // Check platform stats
        let (total_users, total_quests, total_mentorships, total_collaborations) = movehub::get_platform_stats();
        assert!(total_users == 0, 0);
        assert!(total_quests == 0, 1);
        assert!(total_mentorships == 0, 2);
        assert!(total_collaborations == 0, 3);
    }

    #[test(admin = @0x1, user1 = @0x2, user2 = @0x3, sponsor = @0x4)]
    fun test_user_registration(admin: &signer, user1: &signer, user2: &signer, sponsor: &signer) {
        movehub::initialize(admin);
        
        // Register first user
        let username1 = string::utf8(b"alice_dev");
        let bio1 = string::utf8(b"Move developer learning Aptos");
        let skills1 = vector::empty<String>();
        vector::push_back(&mut skills1, string::utf8(b"Move"));
        vector::push_back(&mut skills1, string::utf8(b"Rust"));
        
        movehub::register_user(user1, username1, bio1, skills1);
        
        // Check user profile
        let profile = movehub::get_user_profile(USER1);
        assert!(profile.username == string::utf8(b"alice_dev"), 0);
        assert!(profile.total_quests_completed == 0, 1);
        assert!(profile.current_streak == 0, 2);
        assert!(profile.is_mentor == false, 3);
        assert!(profile.is_sponsor == false, 4);
        
        // Check platform stats
        let (total_users, _, _, _) = movehub::get_platform_stats();
        assert!(total_users == 1, 5);
    }

    #[test(admin = @0x1, user1 = @0x2, user2 = @0x3, sponsor = @0x4)]
    fun test_quest_creation_and_completion(admin: &signer, user1: &signer, user2: &signer, sponsor: &signer) {
        movehub::initialize(admin);
        
        // Register user
        let username = string::utf8(b"alice_dev");
        let bio = string::utf8(b"Move developer");
        let skills = vector::empty<String>();
        movehub::register_user(user1, username, bio, skills);
        
        // Create a quest
        let title = string::utf8(b"Learn Move Basics");
        let description = string::utf8(b"Complete the Move tutorial");
        let quest_type = 1; // TUTORIAL
        let difficulty = 2;
        let reward_amount = 100;
        let expires_at = option::some(timestamp::now_seconds() + 86400); // 1 day
        let max_completions = option::some(100);
        let requirements = vector::empty<String>();
        let tags = vector::empty<String>();
        vector::push_back(&mut tags, string::utf8(b"beginner"));
        vector::push_back(&mut tags, string::utf8(b"tutorial"));
        
        movehub::create_quest(
            sponsor,
            title,
            description,
            quest_type,
            difficulty,
            reward_amount,
            expires_at,
            max_completions,
            requirements,
            tags,
        );
        
        // Check quest was created
        let quest = movehub::get_quest(1);
        assert!(quest.title == string::utf8(b"Learn Move Basics"), 0);
        assert!(quest.quest_type == 1, 1);
        assert!(quest.difficulty == 2, 2);
        assert!(quest.status == 1, 3); // ACTIVE
        
        // Complete the quest
        let proof = string::utf8(b"Completed tutorial with certificate");
        let partners = vector::empty<address>();
        movehub::complete_quest(user1, 1, proof, partners);
        
        // Check quest completion
        let completions = movehub::get_quest_completions(1);
        assert!(vector::length(&completions) == 1, 4);
        
        // Check user progress
        let profile = movehub::get_user_profile(USER1);
        assert!(profile.total_quests_completed == 1, 5);
        assert!(profile.current_streak == 1, 6);
        assert!(profile.longest_streak == 1, 7);
        assert!(profile.reputation_score == 20, 8); // difficulty * 10
    }

    #[test(admin = @0x1, user1 = @0x2, user2 = @0x3, sponsor = @0x4)]
    fun test_mentorship_system(admin: &signer, user1: &signer, user2: &signer, sponsor: &signer) {
        movehub::initialize(admin);
        
        // Register users
        let username1 = string::utf8(b"mentor");
        let bio1 = string::utf8(b"Experienced Move developer");
        let skills1 = vector::empty<String>();
        movehub::register_user(user1, username1, bio1, skills1);
        
        let username2 = string::utf8(b"mentee");
        let bio2 = string::utf8(b"Learning Move");
        let skills2 = vector::empty<String>();
        movehub::register_user(user2, username2, bio2, skills2);
        
        // Set user1 as mentor
        movehub::set_mentor_status(admin, USER1, true);
        
        // Check mentor status
        let profile = movehub::get_user_profile(USER1);
        assert!(profile.is_mentor == true, 0);
        
        // Schedule mentorship session
        let topic = string::utf8(b"Move smart contract development");
        let scheduled_at = timestamp::now_seconds() + 3600; // 1 hour from now
        let duration = 60; // 60 minutes
        
        movehub::schedule_mentorship(user1, USER2, topic, scheduled_at, duration);
        
        // Check mentorship session
        let session = movehub::get_mentorship_session(1);
        assert!(session.mentor == USER1, 1);
        assert!(session.mentee == USER2, 2);
        assert!(session.topic == string::utf8(b"Move smart contract development"), 3);
        assert!(session.status == 1, 4); // scheduled
    }

    #[test(admin = @0x1, user1 = @0x2, user2 = @0x3, sponsor = @0x4)]
    fun test_collaboration_system(admin: &signer, user1: &signer, user2: &signer, sponsor: &signer) {
        movehub::initialize(admin);
        
        // Register users
        let username1 = string::utf8(b"collaborator1");
        let bio1 = string::utf8(b"Developer 1");
        let skills1 = vector::empty<String>();
        movehub::register_user(user1, username1, bio1, skills1);
        
        let username2 = string::utf8(b"collaborator2");
        let bio2 = string::utf8(b"Developer 2");
        let skills2 = vector::empty<String>();
        movehub::register_user(user2, username2, bio2, skills2);
        
        // Start collaboration session
        let participants = vector::empty<address>();
        vector::push_back(&mut participants, USER2);
        let quest_id = option::some(1u64);
        let topic = string::utf8(b"Pair programming on Move project");
        
        movehub::start_collaboration(user1, participants, quest_id, topic);
        
        // Check collaboration session
        let session = movehub::get_collaboration_session(1);
        assert!(vector::length(&session.participants) == 2, 0);
        assert!(session.topic == string::utf8(b"Pair programming on Move project"), 1);
        assert!(session.status == 1, 2); // active
    }

    #[test(admin = @0x1, user1 = @0x2, user2 = @0x3, sponsor = @0x4)]
    #[expected_failure(abort_code = 5)] // E_QUEST_ALREADY_COMPLETED
    fun test_duplicate_quest_completion(admin: &signer, user1: &signer, user2: &signer, sponsor: &signer) {
        movehub::initialize(admin);
        
        // Register user
        let username = string::utf8(b"alice_dev");
        let bio = string::utf8(b"Move developer");
        let skills = vector::empty<String>();
        movehub::register_user(user1, username, bio, skills);
        
        // Create a quest
        let title = string::utf8(b"Learn Move Basics");
        let description = string::utf8(b"Complete the Move tutorial");
        let quest_type = 1;
        let difficulty = 2;
        let reward_amount = 100;
        let expires_at = option::some(timestamp::now_seconds() + 86400);
        let max_completions = option::some(100);
        let requirements = vector::empty<String>();
        let tags = vector::empty<String>();
        
        movehub::create_quest(
            sponsor,
            title,
            description,
            quest_type,
            difficulty,
            reward_amount,
            expires_at,
            max_completions,
            requirements,
            tags,
        );
        
        // Complete the quest first time
        let proof = string::utf8(b"Completed tutorial");
        let partners = vector::empty<address>();
        movehub::complete_quest(user1, 1, proof, partners);
        
        // Try to complete the same quest again - should fail
        let proof2 = string::utf8(b"Completed tutorial again");
        movehub::complete_quest(user1, 1, proof2, partners);
    }

    #[test(admin = @0x1, user1 = @0x2, user2 = @0x3, sponsor = @0x4)]
    #[expected_failure(abort_code = 3)] // E_USER_NOT_FOUND
    fun test_quest_completion_without_registration(admin: &signer, user1: &signer, user2: &signer, sponsor: &signer) {
        movehub::initialize(admin);
        
        // Create a quest
        let title = string::utf8(b"Learn Move Basics");
        let description = string::utf8(b"Complete the Move tutorial");
        let quest_type = 1;
        let difficulty = 2;
        let reward_amount = 100;
        let expires_at = option::some(timestamp::now_seconds() + 86400);
        let max_completions = option::some(100);
        let requirements = vector::empty<String>();
        let tags = vector::empty<String>();
        
        movehub::create_quest(
            sponsor,
            title,
            description,
            quest_type,
            difficulty,
            reward_amount,
            expires_at,
            max_completions,
            requirements,
            tags,
        );
        
        // Try to complete quest without registering - should fail
        let proof = string::utf8(b"Completed tutorial");
        let partners = vector::empty<address>();
        movehub::complete_quest(user1, 1, proof, partners);
    }
}
