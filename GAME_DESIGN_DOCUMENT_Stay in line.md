# Stay In Line - Compact Game Design Document

## High Concept

Stay In Line is a small 2D arcade mini-game about keeping pace with a moving queue. The player must remain inside the queue zone as it slides toward the finish, dodge incoming obstacles, and reach the goal without stepping out of line.

## Player Fantasy

The player is trying to stay disciplined inside a moving line while pressure builds from timing, movement, and hazards. The fun comes from micro-adjusting position, resisting panic, and threading through obstacles while the safe space keeps drifting forward.

## Core Loop

1. Spawn inside the queue zone.
2. Move with the queue as it travels across the playfield.
3. Dodge obstacles entering from the right.
4. Stay inside the queue until reaching the goal area.
5. Win on goal contact, or restart quickly after leaving the queue or touching an obstacle.

## Current Game Rules

- The player can move freely in 2D using arrow keys or WASD.
- The queue zone moves horizontally to the right.
- Once the player has been registered inside the queue, exiting it is a fail state.
- If the player exits near the finish, the game waits one physics frame so goal contact can resolve fairly.
- Obstacles spawn from the right at random vertical positions and move left.
- Touching an obstacle triggers the same restart flow as leaving the queue.
- Reaching the goal area wins the game and stops queue movement and obstacle spawning.

## Controls

| Action | Input |
| --- | --- |
| Move left/right/up/down | Arrow keys |
| Move left/right/up/down | WASD |

## Objects And Systems

| Object | Role |
| --- | --- |
| Player | CharacterBody2D controlled by the user; owns movement and spawn reset. |
| QueueZone | Moving Area2D safe zone; only owns queue movement. |
| GoalArea | Finish trigger; entering it wins the game. |
| ObstacleSpawner | Creates obstacles at timed intervals and relays obstacle contact. |
| Obstacle | Moving Area2D hazard; emits contact once, then keeps moving until cleanup. |
| QueueGameManager | Owns win, fail, restart, signal wiring, UI result text, and stopping systems. |

## Current Tuning

| Value | Current Setting |
| --- | --- |
| Player speed | 220 px/s |
| Queue speed | 80 px/s |
| Obstacle speed | 180 px/s |
| Obstacle spawn interval | 1.25 s |
| Obstacle spawn range | y 170-310 |
| Obstacle spawn x | 980 |
| Obstacle cleanup x | -80 |
| Restart delay | 0.25 s |

## Feedback

- Win message: `You stayed in line!`
- Queue exit message: `Out of line!`
- Obstacle hit message: `Hit an obstacle!`
- On fail, the current scene reloads after a short delay.
- On win, the result label remains visible and gameplay systems stop.

## Visual Direction

The current prototype uses simple readable shapes:

- Player: blue square/capsule-like avatar.
- Queue zone: translucent green rectangle.
- Goal area: translucent yellow vertical finish zone.
- Obstacles: red square hazards.

Future visual work should preserve instant readability: safe area, player, hazard, and finish must be distinguishable at a glance.

## Architecture Guidelines

The project should keep the current lightweight responsibility split:

- Moving areas and hazards announce events.
- The player owns player movement and local reset behavior.
- The manager owns global game flow, win, fail, restart, and UI.

Avoid putting scene reload, global timing, or win/fail decisions inside temporary hazard objects.

## Near-Term Improvements

- Add a start countdown or short grace period before the queue begins moving.
- Add score variants such as time survived, distance traveled, or clean run bonuses.
- Add progressive difficulty by increasing obstacle speed, spawn rate, or lane density.
- Add juice: hit flash, screen shake, sound effects, and goal celebration.
- Add authored levels with different queue paths instead of only straight-line movement.
- Add checkpoints or multi-stage queues if the game grows beyond a mini-game.

## Success Criteria

The prototype is successful when a player immediately understands:

- Stay inside the green queue.
- Avoid red obstacles.
- Reach the yellow goal.
- Failure restarts quickly enough to invite another try.
