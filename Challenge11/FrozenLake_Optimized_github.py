import cupy as cp
import numpy as np
import random
import matplotlib.pyplot as plt
from time import perf_counter

BOARD_ROWS, BOARD_COLS = 5, 5
START = (0, 0)
WIN_STATE = (4, 4)
HOLE_STATE = [(1,0),(3,1),(4,2),(1,3)]
ACTIONS = [0, 1, 2, 3]  # up, down, left, right
ACTION_SPACE = 4

class AgentGPU:
    def __init__(self):
        self.alpha = 0.5
        self.gamma = 0.9
        self.epsilon = 0.1
        self.plot_reward = []

        # Use GPU arrays
        self.Q = cp.zeros((BOARD_ROWS, BOARD_COLS, ACTION_SPACE), dtype=cp.float32)
        self.rewards = 0

        # Profile timing
        self.q_update_time = 0.0
        self.action_selection_time = 0.0
        self.q_assign_time = 0.0

    def get_reward(self, state):
        if tuple(state) in HOLE_STATE:
            return -5
        if tuple(state) == WIN_STATE:
            return 1
        return -1

    def is_terminal(self, state):
        return tuple(state) == WIN_STATE or tuple(state) in HOLE_STATE

    def next_position(self, state, action):
        i, j = state
        if action == 0 and i > 0: i -= 1
        elif action == 1 and i < BOARD_ROWS - 1: i += 1
        elif action == 2 and j > 0: j -= 1
        elif action == 3 and j < BOARD_COLS - 1: j += 1
        return [i, j]

    def choose_action(self, state):
        start = perf_counter()
        if random.random() < self.epsilon:
            action = random.choice(ACTIONS)
        else:
            i, j = state
            action = int(cp.argmax(self.Q[i, j, :]))
        self.action_selection_time += perf_counter() - start
        return action

    def Q_Learning(self, episodes):
        for ep in range(episodes):
            state = list(START)
            total_reward = 0
            while not self.is_terminal(state):
                action = self.choose_action(state)
                next_state = self.next_position(state, action)
                reward = self.get_reward(next_state)
                total_reward += reward

                i, j = state
                ni, nj = next_state

                q_start = perf_counter()
                max_next_q = cp.max(self.Q[ni, nj, :])
                td_target = reward + self.gamma * max_next_q
                td_error = td_target - self.Q[i, j, action]
                self.Q[i, j, action] += self.alpha * td_error
                self.q_update_time += perf_counter() - q_start

                state = next_state

            self.plot_reward.append(total_reward)

        print(f"\n[GPU Timing Summary for {episodes} episodes]")
        print(f"Total Q-value update time:    {self.q_update_time:.4f} seconds")
        print(f"Total action selection time:  {self.action_selection_time:.4f} seconds")

    def plot(self):
        plt.plot(self.plot_reward)
        plt.xlabel("Episodes")
        plt.ylabel("Total Reward")
        plt.title("Q-Learning on GPU - Reward Progress")
        plt.show()

    def show_values(self):
        print("\nFinal Value Table:")
        for i in range(BOARD_ROWS):
            row = ""
            for j in range(BOARD_COLS):
                max_q = float(cp.max(self.Q[i, j, :]))
                row += f"{max_q:6.2f} | "
            print(row)
        print()

if __name__ == "__main__":
    agent = AgentGPU()
    agent.Q_Learning(10000)
    agent.plot()
    agent.show_values()
