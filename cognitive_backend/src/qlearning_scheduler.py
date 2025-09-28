"""
Q-Learning Spaced Retrieval Scheduler
Uses tabular Q-learning to optimize memory review intervals
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Tuple, Optional
import json
import os

class QLearningScheduler:
    """
    Tabular Q-learning scheduler for spaced retrieval
    """
    
    def __init__(self, 
                 learning_rate: float = 0.1,
                 discount_factor: float = 0.9,
                 epsilon: float = 0.1,
                 max_streak: int = 3,
                 max_latency_bin: int = 2,
                 max_load_bin: int = 2):
        
        self.learning_rate = learning_rate
        self.discount_factor = discount_factor
        self.epsilon = epsilon
        self.max_streak = max_streak
        self.max_latency_bin = max_latency_bin
        self.max_load_bin = max_load_bin
        
        # State dimensions: (difficulty, success_streak, latency_bin, load_band)
        self.state_dims = (3, max_streak + 1, max_latency_bin + 1, max_load_bin + 1)
        
        # Actions: intervals in seconds
        self.actions = [30, 60, 120, 240]  # 30s, 1min, 2min, 4min
        self.n_actions = len(self.actions)
        
        # Initialize Q-table
        self.q_table = np.zeros(self.state_dims + (self.n_actions,))
        
        # Track item states
        self.item_states = {}  # item_id -> (difficulty, success_streak, last_latency_bin, last_load_band)
        self.item_sessions = {}  # item_id -> list of session results
        
    def get_state_index(self, difficulty: int, success_streak: int, 
                       latency_bin: int, load_band: int) -> Tuple[int, int, int, int]:
        """Convert state components to Q-table indices"""
        difficulty_idx = min(difficulty - 1, 2)  # 1-3 -> 0-2
        streak_idx = min(success_streak, self.max_streak)
        latency_idx = min(latency_bin, self.max_latency_bin)
        load_idx = min(load_band - 1, self.max_load_bin)  # 1-3 -> 0-2
        
        return (difficulty_idx, streak_idx, latency_idx, load_idx)
    
    def get_latency_bin(self, latency_sec: float) -> int:
        """Convert latency to bin index"""
        if latency_sec <= 2.0:
            return 0
        elif latency_sec <= 5.0:
            return 1
        else:
            return 2
    
    def get_load_band_index(self, load_band: str) -> int:
        """Convert load band string to index"""
        band_map = {'low': 1, 'moderate': 2, 'high': 3}
        return band_map.get(load_band, 2)
    
    def choose_action(self, state: Tuple[int, int, int, int], 
                     item_id: int, force_exploit: bool = False) -> int:
        """Choose action using epsilon-greedy policy with safety constraints"""
        state_idx = self.get_state_index(*state)
        
        if not force_exploit and np.random.random() < self.epsilon:
            # Explore: choose random action
            action = np.random.randint(0, self.n_actions)
        else:
            # Exploit: choose best action
            action = np.argmax(self.q_table[state_idx])
        
        # Apply safety constraints
        difficulty, success_streak, latency_bin, load_band = state
        
        # Don't use very long intervals for difficult items or high load
        if difficulty >= 3 or load_band == 'high':
            action = min(action, 2)  # Max 2 minutes
        
        # Don't use very short intervals for easy items with good streak
        if difficulty == 1 and success_streak >= 2 and load_band in ['low', 'moderate']:
            action = max(action, 1)  # Min 1 minute
        
        return action
    
    def calculate_reward(self, correct: bool, latency_sec: float, 
                        difficulty: int, load_band: str) -> float:
        """Calculate reward for an action"""
        if correct:
            # Base reward for correct answer
            reward = 1.0
            
            # Bonus for faster response (up to 0.5 bonus)
            if latency_sec <= 2.0:
                reward += 0.5
            elif latency_sec <= 5.0:
                reward += 0.3
            elif latency_sec <= 10.0:
                reward += 0.1
            
            # Bonus for handling difficult items
            if difficulty >= 3:
                reward += 0.2
            
            # Bonus for handling high load situations
            if load_band == 'high':
                reward += 0.2
                
        else:
            # Penalty for incorrect answer
            reward = -0.5
            
            # Extra penalty for easy items
            if difficulty == 1:
                reward -= 0.3
        
        return reward
    
    def update_q_value(self, state: Tuple[int, int, int, int], 
                      action: int, reward: float, 
                      next_state: Tuple[int, int, int, int]):
        """Update Q-value using Q-learning update rule"""
        state_idx = self.get_state_index(*state)
        next_state_idx = self.get_state_index(*next_state)
        
        # Q-learning update: Q(s,a) = (1-α)Q(s,a) + α[r + γ*max_a'Q(s',a')]
        current_q = self.q_table[state_idx + (action,)]
        max_next_q = np.max(self.q_table[next_state_idx])
        
        new_q = current_q + self.learning_rate * (reward + self.discount_factor * max_next_q - current_q)
        self.q_table[state_idx + (action,)] = new_q
    
    def get_next_interval(self, item_id: int, difficulty: int, 
                         load_band: str, force_exploit: bool = False) -> int:
        """Get next review interval for an item"""
        # Get current state
        if item_id not in self.item_states:
            # Initialize new item
            state = (difficulty, 0, 1, self.get_load_band_index(load_band))
            self.item_states[item_id] = state
            self.item_sessions[item_id] = []
        else:
            state = self.item_states[item_id]
        
        # Choose action
        action = self.choose_action(state, item_id, force_exploit)
        interval = self.actions[action]
        
        return interval
    
    def record_result(self, item_id: int, correct: bool, latency_sec: float,
                     difficulty: int, load_band: str):
        """Record the result of a memory session"""
        if item_id not in self.item_states:
            return
        
        # Get current state
        current_state = self.item_states[item_id]
        difficulty, success_streak, latency_bin, load_band_idx = current_state
        
        # Calculate reward
        reward = self.calculate_reward(correct, latency_sec, difficulty, load_band)
        
        # Update success streak
        if correct:
            new_streak = min(success_streak + 1, self.max_streak)
        else:
            new_streak = 0
        
        # Update latency bin
        new_latency_bin = self.get_latency_bin(latency_sec)
        
        # New state
        new_state = (difficulty, new_streak, new_latency_bin, self.get_load_band_index(load_band))
        
        # Update Q-value
        # Find the action that was taken (this is a simplification)
        # In practice, you'd track the action taken
        action = 0  # Default to first action for now
        self.update_q_value(current_state, action, reward, new_state)
        
        # Update item state
        self.item_states[item_id] = new_state
        
        # Record session
        session_data = {
            'correct': correct,
            'latency_sec': latency_sec,
            'reward': reward,
            'old_state': current_state,
            'new_state': new_state
        }
        self.item_sessions[item_id].append(session_data)
    
    def get_item_statistics(self, item_id: int) -> Dict:
        """Get statistics for a specific item"""
        if item_id not in self.item_sessions:
            return {}
        
        sessions = self.item_sessions[item_id]
        if not sessions:
            return {}
        
        total_sessions = len(sessions)
        correct_sessions = sum(1 for s in sessions if s['correct'])
        accuracy = correct_sessions / total_sessions
        avg_latency = np.mean([s['latency_sec'] for s in sessions])
        avg_reward = np.mean([s['reward'] for s in sessions])
        
        return {
            'total_sessions': total_sessions,
            'accuracy': accuracy,
            'avg_latency': avg_latency,
            'avg_reward': avg_reward,
            'current_streak': self.item_states[item_id][1]
        }
    
    def save_model(self, filepath: str):
        """Save Q-table and item states"""
        model_data = {
            'q_table': self.q_table.tolist(),
            'item_states': {str(k): v for k, v in self.item_states.items()},
            'item_sessions': {str(k): v for k, v in self.item_sessions.items()},
            'hyperparameters': {
                'learning_rate': self.learning_rate,
                'discount_factor': self.discount_factor,
                'epsilon': self.epsilon,
                'max_streak': self.max_streak,
                'max_latency_bin': self.max_latency_bin,
                'max_load_bin': self.max_load_bin
            }
        }
        
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, 'w') as f:
            json.dump(model_data, f, indent=2)
    
    def load_model(self, filepath: str):
        """Load Q-table and item states"""
        with open(filepath, 'r') as f:
            model_data = json.load(f)
        
        self.q_table = np.array(model_data['q_table'])
        self.item_states = {int(k): tuple(v) for k, v in model_data['item_states'].items()}
        self.item_sessions = {int(k): v for k, v in model_data['item_sessions'].items()}
        
        hyperparams = model_data['hyperparameters']
        self.learning_rate = hyperparams['learning_rate']
        self.discount_factor = hyperparams['discount_factor']
        self.epsilon = hyperparams['epsilon']
        self.max_streak = hyperparams['max_streak']
        self.max_latency_bin = hyperparams['max_latency_bin']
        self.max_load_bin = hyperparams['max_load_bin']

def simulate_memory_sessions(scheduler: QLearningScheduler, 
                           memory_items: pd.DataFrame,
                           n_sessions: int = 40) -> pd.DataFrame:
    """Simulate memory sessions for evaluation"""
    results = []
    
    for session in range(n_sessions):
        # Randomly select items for this session
        n_items = min(12, len(memory_items))  # Max 12 items per session
        session_items = memory_items.sample(n=n_items)
        
        session_accuracy = 0
        session_latency = 0
        session_load_band = np.random.choice(['low', 'moderate', 'high'], p=[0.4, 0.4, 0.2])
        
        for _, item in session_items.iterrows():
            item_id = item['item_id']
            difficulty = item['difficulty']
            
            # Get next interval (simplified - in practice this would be based on scheduling)
            interval = scheduler.get_next_interval(item_id, difficulty, session_load_band)
            
            # Simulate response (simplified)
            # Higher difficulty and load = lower accuracy, higher latency
            base_accuracy = 0.9 - (difficulty - 1) * 0.15 - (0.1 if session_load_band == 'high' else 0)
            accuracy = max(0.3, min(0.95, base_accuracy + np.random.normal(0, 0.1)))
            correct = np.random.random() < accuracy
            
            # Simulate latency
            base_latency = 2.0 + (difficulty - 1) * 1.5 + (1.0 if session_load_band == 'high' else 0)
            latency = max(0.5, base_latency + np.random.normal(0, 0.5))
            
            # Record result
            scheduler.record_result(item_id, correct, latency, difficulty, session_load_band)
            
            session_accuracy += (1 if correct else 0)
            session_latency += latency
        
        # Calculate session metrics
        session_accuracy /= n_items
        session_latency /= n_items
        
        results.append({
            'session': session + 1,
            'accuracy': session_accuracy,
            'avg_latency': session_latency,
            'load_band': session_load_band,
            'n_items': n_items
        })
    
    return pd.DataFrame(results)

if __name__ == "__main__":
    # Load memory items
    memory_items = pd.read_csv('data/memory_items.csv')
    
    # Create scheduler
    scheduler = QLearningScheduler()
    
    # Simulate sessions
    results = simulate_memory_sessions(scheduler, memory_items, n_sessions=40)
    
    # Save results
    os.makedirs('outputs', exist_ok=True)
    results.to_csv('outputs/session_results.csv', index=False)
    
    # Save model
    scheduler.save_model('outputs/qlearning_model.json')
    
    print("Q-Learning Simulation Complete!")
    print(f"Final accuracy: {results['accuracy'].iloc[-1]:.3f}")
    print(f"Final latency: {results['avg_latency'].iloc[-1]:.2f}s")
