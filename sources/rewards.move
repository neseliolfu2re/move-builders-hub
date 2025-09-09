module movehub::rewards {
    use std::signer;
    use std::string::String;
    use std::vector;
    use std::table::{Self, Table};
    use std::option::{Self, Option};
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::event::{Self, EventHandle};

    const E_INSUFFICIENT_BALANCE: u64 = 100;
    const E_REWARD_NOT_FOUND: u64 = 101;
    const E_REWARD_ALREADY_CLAIMED: u64 = 102;

    const REWARD_TYPE_QUEST_COMPLETION: u8 = 1;
    const REWARD_TYPE_STREAK_MILESTONE: u8 = 2;
    const REWARD_TYPE_MENTORSHIP: u8 = 3;

    const REWARD_STATUS_AVAILABLE: u8 = 1;
    const REWARD_STATUS_CLAIMED: u8 = 2;

    struct Reward has key, store, copy, drop {
        id: u64,
        reward_type: u8,
        amount: u64,
        sponsor: address,
        recipient: address,
        quest_id: Option<u64>,
        created_at: u64,
        status: u8,
        description: String,
    }

    struct SponsorPool has key, store, copy, drop {
        sponsor: address,
        total_deposited: u64,
        available_balance: u64,
    }

    struct RewardsSystem has key {
        admin: address,
        total_rewards: u64,
        rewards: Table<u64, Reward>,
        sponsor_pools: Table<address, SponsorPool>,
        user_rewards: Table<address, vector<u64>>,
        reward_created_events: EventHandle<RewardCreatedEvent>,
        reward_claimed_events: EventHandle<RewardClaimedEvent>,
    }

    struct RewardCreatedEvent has store, drop {
        reward_id: u64,
        amount: u64,
        sponsor: address,
        recipient: address,
    }

    struct RewardClaimedEvent has store, drop {
        reward_id: u64,
        recipient: address,
        amount: u64,
    }

    public entry fun initialize(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        move_to(admin, RewardsSystem {
            admin: admin_addr,
            total_rewards: 0,
            rewards: table::new(),
            sponsor_pools: table::new(),
            user_rewards: table::new(),
            reward_created_events: account::new_event_handle<RewardCreatedEvent>(admin),
            reward_claimed_events: account::new_event_handle<RewardClaimedEvent>(admin),
        });
    }

    public entry fun sponsor_deposit(sponsor: &signer, amount: u64) acquires RewardsSystem {
        let sponsor_addr = signer::address_of(sponsor);
        let rewards_system = borrow_global_mut<RewardsSystem>(@movehub);
        
        if (!table::contains(&rewards_system.sponsor_pools, sponsor_addr)) {
            let pool = SponsorPool {
                sponsor: sponsor_addr,
                total_deposited: 0,
                available_balance: 0,
            };
            table::add(&mut rewards_system.sponsor_pools, sponsor_addr, pool);
        };
        
        let pool = table::borrow_mut(&mut rewards_system.sponsor_pools, sponsor_addr);
        pool.total_deposited = pool.total_deposited + amount;
        pool.available_balance = pool.available_balance + amount;
    }

    public entry fun create_quest_reward(
        sponsor: &signer,
        recipient: address,
        quest_id: u64,
        amount: u64,
        description: String,
    ) acquires RewardsSystem {
        let sponsor_addr = signer::address_of(sponsor);
        let rewards_system = borrow_global_mut<RewardsSystem>(@movehub);
        
        assert!(table::contains(&rewards_system.sponsor_pools, sponsor_addr), E_INSUFFICIENT_BALANCE);
        let pool = table::borrow_mut(&mut rewards_system.sponsor_pools, sponsor_addr);
        assert!(pool.available_balance >= amount, E_INSUFFICIENT_BALANCE);
        
        let reward_id = rewards_system.total_rewards + 1;
        let current_time = timestamp::now_seconds();
        
        let reward = Reward {
            id: reward_id,
            reward_type: REWARD_TYPE_QUEST_COMPLETION,
            amount,
            sponsor: sponsor_addr,
            recipient,
            quest_id: option::some(quest_id),
            created_at: current_time,
            status: REWARD_STATUS_AVAILABLE,
            description,
        };
        
        table::add(&mut rewards_system.rewards, reward_id, reward);
        pool.available_balance = pool.available_balance - amount;
        
        if (!table::contains(&rewards_system.user_rewards, recipient)) {
            table::add(&mut rewards_system.user_rewards, recipient, vector::empty());
        };
        let user_rewards = table::borrow_mut(&mut rewards_system.user_rewards, recipient);
        vector::push_back(user_rewards, reward_id);
        
        rewards_system.total_rewards = reward_id;
        
        event::emit_event(&mut rewards_system.reward_created_events, RewardCreatedEvent {
            reward_id,
            amount,
            sponsor: sponsor_addr,
            recipient,
        });
    }

    public entry fun claim_reward(recipient: &signer, reward_id: u64) acquires RewardsSystem {
        let recipient_addr = signer::address_of(recipient);
        let rewards_system = borrow_global_mut<RewardsSystem>(@movehub);
        
        assert!(table::contains(&rewards_system.rewards, reward_id), E_REWARD_NOT_FOUND);
        let reward = table::borrow_mut(&mut rewards_system.rewards, reward_id);
        
        assert!(reward.recipient == recipient_addr, E_REWARD_NOT_FOUND);
        assert!(reward.status == REWARD_STATUS_AVAILABLE, E_REWARD_ALREADY_CLAIMED);
        
        reward.status = REWARD_STATUS_CLAIMED;
        
        event::emit_event(&mut rewards_system.reward_claimed_events, RewardClaimedEvent {
            reward_id,
            recipient: recipient_addr,
            amount: reward.amount,
        });
    }

    public fun get_reward(reward_id: u64): Reward acquires RewardsSystem {
        let rewards_system = borrow_global<RewardsSystem>(@movehub);
        assert!(table::contains(&rewards_system.rewards, reward_id), E_REWARD_NOT_FOUND);
        *table::borrow(&rewards_system.rewards, reward_id)
    }

    public fun get_user_rewards(user: address): vector<u64> acquires RewardsSystem {
        let rewards_system = borrow_global<RewardsSystem>(@movehub);
        if (table::contains(&rewards_system.user_rewards, user)) {
            *table::borrow(&rewards_system.user_rewards, user)
        } else {
            vector::empty()
        }
    }
}
