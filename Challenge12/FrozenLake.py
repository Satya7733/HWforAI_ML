import time
import numpy as np
import gym
import pandas as pd
from gym.envs.toy_text.frozen_lake import generate_random_map

# ── 1) PATCH NUMPY FOR GYM COMPATIBILITY ────────────────────────────────────────
if not hasattr(np, 'bool8'):
    setattr(np, 'bool8', np.bool_)

# ── 2) HIGH‑PRECISION PRINTING ─────────────────────────────────────────────────
np.set_printoptions(precision=3, suppress=True)

# ── 3) CONFIGURATION: adjust these parameters as needed ────────────────────────
size            = 5              # Matrix size: 'size x size'
hole_prob       = 0.2             # Hole percentage (0.2 → 20% holes)
freeze_p        = 1 - hole_prob   # Probability of frozen tile
episodes        = 50000           # Number of training episodes
alpha_start     = 0.1             # Initial learning rate
alpha_end       = 0.01            # Final learning rate
gamma           = 0.9             # Discount factor
eps_start       = 1.0             # Initial exploration rate
eps_end         = 0.01            # Final exploration rate
step_penalty    = 0.01             # No step penalty to encourage goal-reaching
planning_steps  = 20              # Dyna-Q planning updates per real step

# Derived decay rates
eps_decay     = (eps_start - eps_end) / episodes
alpha_decay   = (alpha_start - alpha_end) / episodes

# ── 4) TIMER SETUP ─────────────────────────────────────────────────────────────
script_start = time.perf_counter()

# ── 5) CREATE MAP & ENV ───────────────────────────────────────────────────────
random_map = generate_random_map(size=size, p=freeze_p)
env = gym.make("FrozenLake-v1", desc=random_map, is_slippery=False)

# ── 6) Q-TABLE & MODEL INIT ────────────────────────────────────────────────────
nS = env.observation_space.n
nA = env.action_space.n
Q  = np.zeros((nS, nA))
model = {}  # for Dyna-Q: stores (next_state, reward)

# Profiling counters
time_select = time_step = time_update = time_plan = 0.0


# ── 7) TRAINING WITH Dyna-Q ─────────────────────────────────────────────────────
# ── 7) TRAINING WITH Dyna-Q ─────────────────────────────────────────────────────
print("\n=== Training Dyna-Q ===")
train_start = time.perf_counter()
for ep in range(episodes):
    # decay rates
    epsilon = max(eps_end, eps_start - eps_decay * ep)
    alpha   = max(alpha_end, alpha_start - alpha_decay * ep)

    state = env.reset()
    state = state[0] if isinstance(state, tuple) else state
    done  = False

    while not done:
        # action selection timing
        t0 = time.perf_counter()
        if np.random.rand() < epsilon:
            action = env.action_space.sample()
        else:
            action = np.argmax(Q[state])
        time_select += time.perf_counter() - t0

        # step timing
        t0 = time.perf_counter()
        out = env.step(action)
        time_step += time.perf_counter() - t0

        if len(out) == 5:
            next_state, reward, term, trunc, _ = out
            done = term or trunc
        else:
            next_state, reward, done, _ = out

        reward -= step_penalty

        # Q-update timing
        t0 = time.perf_counter()
        best_next = np.argmax(Q[next_state])
        Q[state, action] += alpha * (reward + gamma * Q[next_state, best_next] - Q[state, action])
        time_update += time.perf_counter() - t0

        # update model and Dyna planning...
        model[(state, action)] = (next_state, reward)
        for _ in range(planning_steps):
            (s_p, a_p), (s2_p, r2_p) = model.popitem()
            t0 = time.perf_counter()
            best_n = np.argmax(Q[s2_p])
            Q[s_p, a_p] += alpha * (r2_p + gamma * Q[s2_p, best_n] - Q[s_p, a_p])
            time_plan += time.perf_counter() - t0
            model[(s_p, a_p)] = (s2_p, r2_p)

        state = next_state

    # ←—— progress print every 1000 episodes
    if (ep + 1) % 1000 == 0:
        print(f"  Trained {ep + 1} / {episodes} episodes")

train_end = time.perf_counter()


# ── 8) EVALUATION ──────────────────────────────────────────────────────────────
print("\n=== Evaluation ===")
eval_start = time.perf_counter()  
eval_episodes = 1000
successes = 0
paths = []
for _ in range(eval_episodes):
    state = env.reset()
    state = state[0] if isinstance(state, tuple) else state
    done = False
    steps = []
    while not done:
        action = int(np.argmax(Q[state]))
        steps.append(action)
        out = env.step(action)
        if len(out) == 5:
            state, reward, term, trunc, _ = out
            done = term or trunc
        else:
            state, reward, done, _ = out
    if reward > 0:
        successes += 1
    paths.append(steps)
eval_end = time.perf_counter()

# ── 9) CONSOLIDATED OUTPUT ───────────────────────────────────────────────────────
print("\n=== Q-Table ===")
print("\n=== Timing Summary ===")
print(f"Total runtime:           {eval_end - script_start:.3f}s")
print(f"Training time:           {train_end - train_start:.3f}s")
print(f"  - select action:       {time_select:.3f}s")
print(f"  - env.step calls:      {time_step:.3f}s")
print(f"  - Q updates:           {time_update:.3f}s")
print(f"  - planning updates:    {time_plan:.3f}s")
print(f"Evaluation time:         {eval_end - eval_start:.3f}s")

print("\n=== Results ===")
print(f"Evaluation Episodes:     {eval_episodes}")
print(f"Success Rate:            {successes}/{eval_episodes} ({successes/eval_episodes:.2%})")

# Optionally show one successful path
print("\n=== Example Path to Goal ===")
for idx, path in enumerate(paths):
    if len(path) > 0 and reward > 0:
        print(path)
        break

env.close()

