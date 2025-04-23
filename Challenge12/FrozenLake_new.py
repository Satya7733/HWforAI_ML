import time
import numpy as np
import gym
import random
from gym.envs.toy_text.frozen_lake import generate_random_map

# ── PATCH NUMPY FOR GYM COMPATIBILITY ────────────────────────────────────────
if not hasattr(np, 'bool8'):
    setattr(np, 'bool8', np.bool_)

# ── CONFIGURATION ───────────────────────────────────────────────────────────
SIZE            = 15               # 15×15 grid
HOLE_PROB       = 0.2              # 20% holes
FREEZE_P        = 1 - HOLE_PROB
EPISODES        = 100_000          # training episodes
EVAL_EPISODES   = 200              # evaluation episodes
ALPHA           = 0.1              # learning rate
GAMMA           = 0.99             # discount factor
EPS_START       = 1.0              # initial exploration
EPS_END         = 0.01             # final exploration
PLANNING_STEPS  = 20               # Dyna‑Q planning per real step
STEP_PENALTY    = 0.001            # small penalty to encourage shortest paths

EPS_DECAY = (EPS_START - EPS_END) / EPISODES

# ── GENERATE ONE FIXED MAP ───────────────────────────────────────────────────
RANDOM_MAP = generate_random_map(size=SIZE, p=FREEZE_P)

# ── HELPER FUNCTIONS ─────────────────────────────────────────────────────────
def q_update(Q, s, a, s2, r):
    best_next = np.argmax(Q[s2])
    Q[s, a] += ALPHA * (r + GAMMA * Q[s2, best_next] - Q[s, a])

def planning_update(Q, s, a, s2, r):
    best_n = np.argmax(Q[s2])
    Q[s, a] += ALPHA * (r + GAMMA * Q[s2, best_n] - Q[s, a])

# ── TRAINING & PROFILING ──────────────────────────────────────────────────────
def train_and_profile():
    env = gym.make("FrozenLake-v1", desc=RANDOM_MAP, is_slippery=False)
    nS, nA = env.observation_space.n, env.action_space.n
    Q     = np.zeros((nS, nA))
    model = {}

    time_q_update = 0.0
    time_planning = 0.0

    for ep in range(EPISODES):
        state = env.reset()
        if isinstance(state, tuple):
            state = state[0]
        done = False
        eps  = max(EPS_END, EPS_START - EPS_DECAY * ep)

        while not done:
            # choose action
            if np.random.rand() < eps:
                action = env.action_space.sample()
            else:
                action = int(np.argmax(Q[state]))

            # take step
            out = env.step(action)
            if len(out) == 5:
                nxt, reward, term, trunc, _ = out
                done = term or trunc
            else:
                nxt, reward, done, _ = out

            # penalize falling in hole
            if done and reward == 0:
                reward = -1.0
            # step penalty
            reward -= STEP_PENALTY

            # time the Q‑update
            t0 = time.perf_counter()
            q_update(Q, state, action, nxt, reward)
            time_q_update += time.perf_counter() - t0

            # update model and do Dyna‑Q planning
            model[(state, action)] = (nxt, reward)
            for _ in range(PLANNING_STEPS):
                s_p, a_p = random.choice(list(model.keys()))
                s2_p, r2_p = model[(s_p, a_p)]
                t1 = time.perf_counter()
                planning_update(Q, s_p, a_p, s2_p, r2_p)
                time_planning += time.perf_counter() - t1

            state = nxt

        # progress indicator
        if (ep + 1) % 5000 == 0:
            print(f"  Trained {ep+1}/{EPISODES} episodes")

    env.close()
    return Q, time_q_update, time_planning

# ── EVALUATION ────────────────────────────────────────────────────────────────
def evaluate(Q):
    env = gym.make("FrozenLake-v1", desc=RANDOM_MAP, is_slippery=False)
    successes = 0

    for _ in range(EVAL_EPISODES):
        state = env.reset()
        if isinstance(state, tuple):
            state = state[0]
        done = False

        while not done:
            action = int(np.argmax(Q[state]))
            out = env.step(action)
            if len(out) == 5:
                state, reward, term, trunc, _ = out
                done = term or trunc
            else:
                state, reward, done, _ = out

        if reward > 0:
            successes += 1

    env.close()
    return successes

# ── MAIN ENTRY POINT ──────────────────────────────────────────────────────────
if __name__ == "__main__":
    script_start = time.perf_counter()

    print("Training and profiling...")
    Q, tq, tp = train_and_profile()
    print(f"\nTime in Q-update steps:    {tq:.4f} s")
    print(f"Time in planning steps:    {tp:.4f} s")

    print("\nRunning evaluation...")
    succ = evaluate(Q)
    rate = succ / EVAL_EPISODES
    print(f"Success rate: {succ}/{EVAL_EPISODES} = {rate:.2%}")

    script_end = time.perf_counter()
    total = script_end - script_start
    overhead = total - (tq + tp)

    print(f"\nTotal runtime:             {total:.4f} s")
    print("Time distribution:")
    print(f"  Q-update:                {tq/total*100:6.2f}%")
    print(f"  Planning:                {tp/total*100:6.2f}%")
    print(f"  Overhead (other work):   {overhead/total*100:6.2f}%")
