module movehub::analytics {
    use std::signer;
    use std::string::String;
    use std::vector;
    use std::table::{Self, Table};
    use aptos_framework::timestamp;

    const E_ANALYTICS_NOT_FOUND: u64 = 200;

    struct LearningProgress has key, store, copy, drop {
        user: address,
        total_learning_hours: u64,
        quests_completed_by_type: vector<u64>,
        skills_learned: vector<String>,
        last_activity: u64,
    }

    struct UserEngagement has key, store, copy, drop {
        user: address,
        login_streak: u64,
        quest_completion_streak: u64,
        mentorship_sessions_attended: u64,
        collaboration_sessions_attended: u64,
        reputation_earned: u64,
        last_login: u64,
    }

    struct QuestAnalytics has key, store, copy, drop {
        quest_id: u64,
        completion_rate: u64,
        average_completion_time: u64,
        difficulty_rating: u64,
        popularity_score: u64,
    }

    struct PlatformAnalytics has key, store, copy, drop {
        total_active_users: u64,
        daily_active_users: u64,
        quest_completion_rate: u64,
        average_quest_difficulty: u64,
        last_updated: u64,
    }

    struct AnalyticsSystem has key {
        admin: address,
        learning_progress: Table<address, LearningProgress>,
        user_engagement: Table<address, UserEngagement>,
        quest_analytics: Table<u64, QuestAnalytics>,
        platform_analytics: PlatformAnalytics,
    }

    public entry fun initialize(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        move_to(admin, AnalyticsSystem {
            admin: admin_addr,
            learning_progress: table::new(),
            user_engagement: table::new(),
            quest_analytics: table::new(),
            platform_analytics: PlatformAnalytics {
                total_active_users: 0,
                daily_active_users: 0,
                quest_completion_rate: 0,
                average_quest_difficulty: 0,
                last_updated: timestamp::now_seconds(),
            },
        });
    }

    public fun update_learning_progress(
        user: address,
        quest_type: u8,
        skills_learned: vector<String>,
        learning_hours: u64,
    ) acquires AnalyticsSystem {
        let analytics = borrow_global_mut<AnalyticsSystem>(@movehub);
        
        if (!table::contains(&analytics.learning_progress, user)) {
            let progress = LearningProgress {
                user,
                total_learning_hours: 0,
                quests_completed_by_type: vector::empty(),
                skills_learned: vector::empty(),
                last_activity: 0,
            };
            table::add(&mut analytics.learning_progress, user, progress);
        };
        
        let progress = table::borrow_mut(&mut analytics.learning_progress, user);
        progress.total_learning_hours = progress.total_learning_hours + learning_hours;
        progress.last_activity = timestamp::now_seconds();
        
        while (vector::length(&progress.quests_completed_by_type) <= (quest_type as u64)) {
            vector::push_back(&mut progress.quests_completed_by_type, 0);
        };
        let current_count = *vector::borrow(&progress.quests_completed_by_type, quest_type as u64);
        vector::swap(&mut progress.quests_completed_by_type, quest_type as u64, current_count + 1);
        
        let i = 0;
        let len = vector::length(&skills_learned);
        while (i < len) {
            let skill = *vector::borrow(&skills_learned, i);
            vector::push_back(&mut progress.skills_learned, skill);
            i = i + 1;
        };
    }

    public fun update_user_engagement(user: address, activity_type: u8) acquires AnalyticsSystem {
        let analytics = borrow_global_mut<AnalyticsSystem>(@movehub);
        
        if (!table::contains(&analytics.user_engagement, user)) {
            let engagement = UserEngagement {
                user,
                login_streak: 0,
                quest_completion_streak: 0,
                mentorship_sessions_attended: 0,
                collaboration_sessions_attended: 0,
                reputation_earned: 0,
                last_login: 0,
            };
            table::add(&mut analytics.user_engagement, user, engagement);
        };
        
        let engagement = table::borrow_mut(&mut analytics.user_engagement, user);
        
        if (activity_type == 1) {
            engagement.login_streak = engagement.login_streak + 1;
            engagement.last_login = timestamp::now_seconds();
        } else if (activity_type == 2) {
            engagement.quest_completion_streak = engagement.quest_completion_streak + 1;
        } else if (activity_type == 3) {
            engagement.mentorship_sessions_attended = engagement.mentorship_sessions_attended + 1;
        } else if (activity_type == 4) {
            engagement.collaboration_sessions_attended = engagement.collaboration_sessions_attended + 1;
        };
    }

    public fun get_learning_progress(user: address): LearningProgress acquires AnalyticsSystem {
        let analytics = borrow_global<AnalyticsSystem>(@movehub);
        assert!(table::contains(&analytics.learning_progress, user), E_ANALYTICS_NOT_FOUND);
        *table::borrow(&analytics.learning_progress, user)
    }

    public fun get_user_engagement(user: address): UserEngagement acquires AnalyticsSystem {
        let analytics = borrow_global<AnalyticsSystem>(@movehub);
        assert!(table::contains(&analytics.user_engagement, user), E_ANALYTICS_NOT_FOUND);
        *table::borrow(&analytics.user_engagement, user)
    }

    public fun get_platform_analytics(): PlatformAnalytics acquires AnalyticsSystem {
        let analytics = borrow_global<AnalyticsSystem>(@movehub);
        analytics.platform_analytics
    }
}
