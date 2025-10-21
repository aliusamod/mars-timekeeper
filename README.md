🪐 Mars Timekeeper Contract

Overview

The Mars Timekeeper smart contract is a Clarity-based system designed to track Martian sols (Martian days) in relation to Bitcoin block time. It provides a framework for recording mission timelines, sol observations, and user participation — bridging the gap between Earth-based time (measured in Bitcoin blocks) and Martian time.

🌍 Martian Time Concept

1 Martian sol ≈ 24h 39m 35s = 88,775 seconds

1 Earth day = 86,400 seconds

Therefore, 1 sol ≈ 1.02749125 Earth days

Conversion factor used: 1 sol = 1.02749125 Earth days, scaled up for precision using a factor of 1,000,000.

This contract uses these relationships to convert between Bitcoin blocks (≈10 min each), Earth days, and Martian sols.

🧱 Key Features
1. Mission Tracking

Create, monitor, and end Mars missions.

Each mission is identified by a unique mission-id and contains details like:

Mission name

Starting Bitcoin block

Start timestamp

Creator address

Active/inactive status

Function:

start-mission (name start-block) — starts a new mission.

end-mission (mission-id) — ends an active mission.

get-mission (mission-id) — retrieves mission details.

get-total-missions — returns total number of missions created.

2. Sol Recording System

Users can log observations for specific Martian sols, attaching notes, timestamps, and the current block height.

Function:

record-sol (sol notes) — records a sol observation.

get-sol-record (sol) — retrieves recorded details for a given sol.

Each record stores:

Sol number

Block height

Timestamp (from get-block-info?)

Recorder (user principal)

Optional notes (up to 256 UTF-8 characters)

3. User Contributions

The contract maintains a record of user activity, tracking how many sol observations each user has made and the block of their first record.

Function:

get-user-stats (user) — fetches total records and first contribution block.

4. Time Conversion Utilities

Provides functions to calculate elapsed Martian sols between blocks and to estimate mission progress in sols.

Functions:

blocks-to-sols (start-block current-block) — converts block difference to sols.

get-current-mission-sol (mission-id) — returns the current sol count for a mission.

get-sol-difference (block-1 block-2) — calculates sol difference between two blocks.

5. Contract Information

The contract can return its core configuration data such as the scaling factors, current block, and total missions.

Function:

get-contract-info — returns system parameters including:

sol-to-earth-factor

blocks-per-day

total-missions

current-block

⚙️ Constants Summary
Constant	Value	Description
SOL_TO_EARTH_DAY_FACTOR	u1027491	Sol-to-Earth day conversion (scaled × 1,000,000)
SCALE_FACTOR	u1000000	Scaling factor for precision
BLOCKS_PER_EARTH_DAY	u144	Approx. number of Bitcoin blocks per day
ERR_UNAUTHORIZED	(err u100)	Unauthorized operation
ERR_INVALID_BLOCK	(err u101)	Invalid block height provided
ERR_MISSION_EXISTS	(err u102)	Mission already exists
ERR_MISSION_NOT_FOUND	(err u103)	Mission not found
🔐 Access Control

Only the mission creator can end their mission. All other operations (such as recording sols) are open to all users.

🧪 Example Workflows
Start a new mission
(contract-call? .mars-timekeeper start-mission "Olympus Exploration" u900000)

Record a sol observation
(contract-call? .mars-timekeeper record-sol u12 "Captured sunrise over Gale Crater")

End the mission
(contract-call? .mars-timekeeper end-mission u1)

Get mission progress in sols
(contract-call? .mars-timekeeper get-current-mission-sol u1)

📊 Potential Use Cases

Space-themed simulations that integrate Bitcoin time and Martian calendars.

Educational tools teaching about time dilation and planetary time.

Mission logbooks for decentralized exploration projects or games.

Data visualization of interplanetary events mapped to blockchain time.

🧾 License

This contract is open-source and may be used under the MIT License