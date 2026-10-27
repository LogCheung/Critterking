# Critterking
A roguelike where you build the colony you defend. Select and place cards to construct an army and a colony that supports them to beat back the ever-threating invaders!
<br/> <br/>


https://github.com/user-attachments/assets/e036f259-2c1e-4ca0-91c2-9cd98caa7e1d




Update 1 is almost ready. <br/>
Playable demo of Update 1 is available upon request. <br/>
Gameplay video of Update 1 at bottom of README. <br/>
Steam Page: https://store.steampowered.com/app/4073470/Critterking/  <br/>
# Design Goals / Phases
- Jam Build
  - Make engaging and satisfying combat with groups and countering unit types and RTS style combat
  - Day / Night to match Upgrade / Fight, using buildings and unit upgrades to impact battle.
  - Stakes through needing to defend houses
  - Mix the systems of known strategy games (Mini motorways, Bad North, 9 Kings)
- Steam Initial Release
  - Diversify map tiles / beautify world (after harsh graphics ratings as a result of jam)
  - Introduce more decisions / ways to battle through decrees
  - Spice up nights with occasional swarm waves ( after noticing game was felt more fun in later nights, dealing with enemies on multiple sides in large numbers)
  - Introduce risk / reward with charm & expedition system with losing a unit temporarily for an upgrade
  - Space for a greater variety of interactions through more unit types and buildings
  - Incentive to keep playing game after winning once through Adaptations / Challenges / Unlocks
- Update 1 : Critterkingdom
  - Expand game apart from a tactics game and introduce strategic decisions apart from combat (colony mechanics).
  - Expand greatly upon the day time part of the game and tie it closely with the night combat
    - Introduce colony buildings & resource management & daily shop for buildings
    - Militia/Rebels spawning in the night due to colony state
    - Think back to inspiration of Mini Motorways and importance of planning colony with more demand for colony space
  - Balance risk of losing through means of mismanaging colony and slipping up in the nights, both parts should feel important 
# Feature List (Current)
- Daytime / Deckbuilding
  - Daily Drawing of cards
    - Units/Charms/Decrees/Buildings/Colony Buildings/General Cards can all be drawn
  - Shop spending Petals (for Colony Buildings/Buildings/Destroy Card)
  - Colony Management
    - Traits (Culture, Commerce, Fame, Productivity)
    - Resources (Petals, Satisfaction, Citizens, Food, Army Size)
    - Job Assignments/Citizen Allocation
    - Citizens consume Food/Satisfaction
    - Colony Buildings Cards (16 types)
      - Trait Scaling Buildings (Theatre/Trading Post/Garden/School/Bakery)
      - Resource Generators (Tavern/Hall/Field/House/Monument)
      - Percent Chance Proc Buildings (Casino/Marketplace/Customs/Guild)
      - Buffing/Support Buildings (Pond/Pantry)
    - Militia/Rebels Spawning (based on Satisfaction)
  - Buildings Cards (8 types)
    - Affect Daily Draws (Storage/Nursery)
    - Affect Unit Stats (Sapstores/Farm)
    - Battle Buildings (Care Tent/Fort/Traps/Campfire)
  - General Cards
    - Ponder (Reduced Decree Cooldown)
    - Destroy (Ruins/Building/Obstacles clearing)
  - Expeditions/Charms
    - Remove one unit from hand
    - Return next night with a Charm
  - Charm cards (13 types)
    - Add stats/power (Health/AtkSpeed/Damage/Speed/Dodge/Heal Time/Range/Stun Chance)
  - Procedural generation of outside map
    - Includes obstacles surrounding colony
  - Group System
    - Unit Cards can be placed to form a group
    - Merging Cards upgrades them
    - Charm can be applied to group
    - Death of entire group means elimination of card
    - Each group placed is paid a wage in Petals
  - Units (following rock paper scissors design of units)
    - Biter/Spitter/Plated (Original Triangle; Melee/Range/Shielded)
    - Acidic/Flying/Crazed + the late Bomber unit (2nd Triangle; AOE/Dash/Speed&Dodge)
    - Paralytic/Stinger/Resilient (Status triangle; stuns/poison/healing)
    - Explosive/Fungi/Trapjaw (4th triangle; AOE on death/Zombie spawn on kill/Knockback)
    - 1st Upgrade is increased stats
    - 2nd Upgrade is increased group size
- Night Time / Battle
  - Nights / Difficulty Progression
    - Every 2 nights add an attacking party to the total attackers of the night
    - Every 4 nights convert one random attacking party to upgraded enemies
    - Every 6 nights expand colony territory, grant Decree draw, swarm player with increased parties, frequency, and groupings
    - Night 2 : Introduce Raiders, chance for enemies to be Raiders (only targets buildings)
    - Night 12 : Introduce Assassins, low chance for enemies to be assassins (only targets houses)
    - Lose Condition : All player houses are destroyed
  - Commanding Groups
    - Isometric Tiles
    - Highlight available tiles upon clicking group & slow-mo
    - Move group formation to selected tile upon clicking tile
    - Click a house/care tent to replenish unit groups during the night
  - Combat
    - Groups attack nearby enemies
    - Ranged Units strafe, units return to formation after attacking
  - Enemies
    - Spawn in waves aggressively march toward player colony
    - Prioritizes buildings naturally unless interrupted by player units or has unique behavior (raider/assassin)
  - Decrees (12 types0
    - Stat Affecting Decrees (Inspiration/Defense/Recon/Mastery/Fortitude)
    - Event Decrees (War/Conscription/Care/Renovate/Terror/Sabotage)
- Adaptations
  - Difficulty modifiers unlocked each time player beats the game (survives 30 nights)
- Unlocks
  - Player starts with two trianagles
  - Player unlocks more buildings & unit triangles each time player wins
- Challenges
  - Modes that drastically change gameplay from traditional play
    - Juiced : Increased game speed
    - Minimalist : small starting colony size
    - Tower Defense : slow unit movement, challenging to defend buildings
  - Unlock special charms/decrees upon beating challenge
- Save/Load System
  - Player data, unlocks, wins
  - Player current save (nights, buildings, units, charms, decrees, resources, traits)
- Tutorial
  - Dialogue with "Advisor" that guides player through each screen/introduction of mechanic
- UI
  - Overhead info bar displaying colony information & giant night counter
  - Job assignment toggle of buildings
  - Next turn
  - Dragging/dropping cards in hand
  - Selecting cards for purchase or to send on expedition
  - Main Menu/Play Screen to select challenges & adaptations
- Settings
  - Volume
  - Resolution
