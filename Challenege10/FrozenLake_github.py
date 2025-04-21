# -*- coding: utf-8 -*-
"""
Created on Sat Mar 28 12:59:23 2020

Assignment 2 - Agents and Reinforcement Learning

Modified for profiling by ChatGPT
"""

import numpy as np
import random
import matplotlib.pyplot as plt
from time import perf_counter

BOARD_ROWS = 5
BOARD_COLS = 5
START = (0, 0)
WIN_STATE = (4, 4)
HOLE_STATE = [(1,0),(3,1),(4,2),(1,3)]

class State:
    def __init__(self, state=START):
        self.state = state
        self.isEnd = False        

    def getReward(self):
        if self.state in HOLE_STATE:
            return -5
        if self.state == WIN_STATE:
            return 1       
        return -1

    def isEndFunc(self):
        if self.state == WIN_STATE or self.state in HOLE_STATE:
            self.isEnd = True

    def nxtPosition(self, action):     
        if action == 0:                
            nxtState = (self.state[0] - 1, self.state[1]) #up             
        elif action == 1:
            nxtState = (self.state[0] + 1, self.state[1]) #down
        elif action == 2:
            nxtState = (self.state[0], self.state[1] - 1) #left
        else:
            nxtState = (self.state[0], self.state[1] + 1) #right

        if 0 <= nxtState[0] <= 4 and 0 <= nxtState[1] <= 4:
            return nxtState
        return self.state 

class Agent:

    def __init__(self):
        self.states = []
        self.actions = [0,1,2,3]    # up, down, left, right
        self.State = State()
        self.alpha = 0.5
        self.gamma = 0.9
        self.epsilon = 0.1
        self.isEnd = self.State.isEnd
        self.plot_reward = []
        self.Q = {}
        self.new_Q = {}
        self.rewards = 0
        
        # Initialize Q-table
        for i in range(BOARD_ROWS):
            for j in range(BOARD_COLS):
                for k in self.actions:
                    self.Q[(i, j, k)] = 0
                    self.new_Q[(i, j, k)] = 0

        # Timing variables
        self.q_update_time = 0.0
        self.action_selection_time = 0.0
        self.q_assign_time = 0.0
        
    def Action(self):
        start_time = perf_counter()
        rnd = random.random()
        mx_nxt_reward = -10
        action = None
        i, j = self.State.state

        if rnd > self.epsilon:
            for k in self.actions:
                nxt_reward = self.Q[(i,j,k)]
                if nxt_reward >= mx_nxt_reward:
                    action = k
                    mx_nxt_reward = nxt_reward
        else:
            action = np.random.choice(self.actions)

        position = self.State.nxtPosition(action)
        self.action_selection_time += perf_counter() - start_time
        return position, action

    def Q_Learning(self, episodes):
        x = 0
        while x < episodes:
            if self.isEnd:
                reward = self.State.getReward()
                self.rewards += reward
                self.plot_reward.append(self.rewards)
                i,j = self.State.state
                for a in self.actions:
                    self.new_Q[(i,j,a)] = round(reward, 3)
                self.State = State()
                self.isEnd = self.State.isEnd
                self.rewards = 0
                x += 1
            else:
                next_state, action = self.Action()
                i, j = self.State.state
                reward = self.State.getReward()
                self.rewards += reward
                mx_nxt_value = -10

                # Profile Q-value computation
                q_start = perf_counter()
                for a in self.actions:
                    nxt_q = (1 - self.alpha) * self.Q[(i,j,action)] + \
                            self.alpha * (reward + self.gamma * self.Q[(next_state[0], next_state[1], a)])
                    if nxt_q >= mx_nxt_value:
                        mx_nxt_value = nxt_q
                self.q_update_time += perf_counter() - q_start

                # Update State
                self.State = State(state=next_state)
                self.State.isEndFunc()
                self.isEnd = self.State.isEnd

                # Profile assignment to Q
                q_assign_start = perf_counter()
                self.new_Q[(i,j,action)] = round(mx_nxt_value, 3)
                self.q_assign_time += perf_counter() - q_assign_start

            self.Q = self.new_Q.copy()

        # Print timings after all episodes
        print(f"\n[Timing Summary for {episodes} episodes]")
        print(f"Total Q-value computation time: {self.q_update_time:.4f} seconds")
        print(f"Total action selection time:    {self.action_selection_time:.4f} seconds")
        print(f"Total Q assignment time:        {self.q_assign_time:.4f} seconds")

    def plot(self, episodes):
        plt.plot(self.plot_reward)
        plt.xlabel("Episodes")
        plt.ylabel("Cumulative Reward")
        plt.title("Q-Learning Reward Progress")
        plt.show()

    def showValues(self):
        for i in range(BOARD_ROWS):
            print('-----------------------------------------------')
            out = '| '
            for j in range(BOARD_COLS):
                mx_nxt_value = -10
                for a in self.actions:
                    nxt_value = self.Q[(i,j,a)]
                    if nxt_value >= mx_nxt_value:
                        mx_nxt_value = nxt_value
                out += str(mx_nxt_value).ljust(6) + ' | '
            print(out)
        print('-----------------------------------------------')


if __name__ == "__main__":
    ag = Agent()
    episodes = 10000
    ag.Q_Learning(episodes)
    ag.plot(episodes)
    ag.showValues()
