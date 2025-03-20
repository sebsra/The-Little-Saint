# The Little Saint - Refactoring TODO List

## 1. Core Architecture Refactoring

### 1.2 Implement State Machines
14. [NEW] `scripts/core/state_machine/state_machine.gd` - Create state machine framework
15. [NEW] `scripts/core/state_machine/state.gd` - Create base state class
16. [NEW] `scripts/core/state_machine/player_states/` - Create folder for player states
17. [NEW] `scripts/core/state_machine/enemy_states/` - Create folder for enemy states
18. [MODIFY] `scripts/core/characters/player.gd` - Integrate state machine for player

## 2. Enhanced Game Management

### 2.1 Expand Game Manager
19. [MODIFY] `scripts/autoload/game_manager.gd` - Develop the empty manager with game state handling
20. [NEW] `scripts/autoload/scene_manager.gd` - Create manager for scene transitions
21. [NEW] `scripts/autoload/event_bus.gd` - Create centralized event system

### 2.2 Improve Save System
22. [NEW] `scripts/autoload/save_manager.gd` - Create dedicated save manager
23. [NEW] `scripts/utils/save_data.gd` - Create data structure for saved games
24. [MODIFY] `scripts/ui/character_customizer/customizer_controller.gd` - Use SaveManager instead of ConfigFile
25. [MODIFY] `scripts/core/characters/player.gd` - Use SaveManager instead of ConfigFile

## 3. Player System Improvements

### 3.1 Refactor Player Controller
26. [MODIFY] `scripts/core/characters/player.gd` - Major refactoring for cleaner structure
27. [NEW] `scripts/core/characters/player_movement.gd` - Extract movement logic
28. [NEW] `scripts/core/characters/player_animation.gd` - Extract animation logic
29. [NEW] `scripts/core/characters/player_outfit.gd` - Extract outfit management
30. [NEW] `scripts/core/characters/player_input.gd` - Create input handler

### 3.2 Enhance Character Customization
31. [NEW] `scripts/resources/player_outfit_resource.gd` - Create outfit resource type
32. [MODIFY] `scripts/ui/character_customizer/customizer_controller.gd` - Use resource-based system
33. [MODIFY] `scripts/ui/character_customizer/outfit_showcase.gd` - Improve UI feedback
34. [MODIFY] `scripts/ui/character_customizer/preview_helper.gd` - Optimize preview generation

## 4. Enemy System Enhancements

### 4.1 Standardize Enemy Behavior
35. [NEW] `scripts/core/enemies/behaviors/patrol_behavior.gd` - Create modular patrol behavior
36. [NEW] `scripts/core/enemies/behaviors/chase_behavior.gd` - Create modular chase behavior
37. [NEW] `scripts/core/enemies/behaviors/attack_behavior.gd` - Create modular attack behavior
38. [NEW] `scripts/core/enemies/behaviors/ranged_attack.gd` - Create ranged attack component
39. [NEW] `scripts/core/enemies/behaviors/melee_attack.gd` - Create melee attack component
40. [NEW] `scripts/managers/enemy_manager.gd` - Create manager for enemy spawning and waves

### 4.2 Improve Combat System
41. [NEW] `scripts/core/combat/damage_system.gd` - Create system for damage handling
42. [NEW] `scripts/core/combat/hit_effect.gd` - Create visual effects for hits
43. [NEW] `scripts/core/combat/screen_shake.gd` - Add screen shake effect
44. [MODIFY] `scripts/ui/hud/hud_controller.gd` - Improve damage feedback

## 5. UI and User Experience

### 5.1 Enhance UI Framework
45. [NEW] `scripts/ui/theme/ui_theme.gd` - Create consistent UI theme
46. [NEW] `scripts/ui/components/` - Create folder for reusable UI components
47. [NEW] `scripts/ui/components/button_with_sound.gd` - Create button with sound effects
48. [NEW] `scripts/ui/transitions/screen_transition.gd` - Create screen transition effects
49. [MODIFY] `scenes/ui/main_menu/main_menu.tscn` - Update with new UI components

### 5.2 Improve HUD
50. [MODIFY] `scripts/ui/hud/hud_controller.gd` - Enhance health display and animations
51. [NEW] `scripts/ui/hud/mini_map.gd` - Add mini-map component
52. [NEW] `scripts/ui/hud/objective_tracker.gd` - Add objective tracking
53. [MODIFY] `scenes/ui/hud/hud.tscn` - Update with new components

### 5.3 Dialog System
54. [MODIFY] `scripts/ui/dialogs/popup_dialog.gd` - Enhance with animations
55. [NEW] `scripts/ui/dialogs/conversation_system.gd` - Create NPC conversation system
56. [NEW] `scripts/ui/dialogs/dialog_tree.gd` - Implement branching dialogs
57. [NEW] `scripts/ui/dialogs/quest_tracker.gd` - Add quest tracking

## 6. Performance Optimization

### 6.1 Resource Management
58. [NEW] `scripts/utils/resource_preloader.gd` - Create resource preloading manager
59. [NEW] `scripts/utils/object_pool.gd` - Implement object pooling system
60. [MODIFY] `scripts/core/projectiles/mage_ball.gd` - Use object pooling
61. [MODIFY] `scripts/core/projectiles/rock.gd` - Use object pooling

### 6.2 Code Optimization
62. [REVIEW] All scripts with _process methods - Optimize heavy processing
63. [MODIFY] `scripts/core/characters/player.gd` - Optimize signal connections
64. [NEW] `scripts/utils/performance_monitor.gd` - Add monitoring capabilities

## 7. Development Tooling

### 7.1 Create Debug Tools
65. [NEW] `scripts/utils/debug_console.gd` - Implement in-game debug console
66. [NEW] `scripts/utils/performance_display.gd` - Add FPS and memory display
67. [NEW] `scripts/utils/cheat_system.gd` - Add cheat code functionality

### 7.2 Improve Project Structure
68. [NEW] `scripts/utils/constants.gd` - Create global constants file
69. [REVIEW] All scripts - Standardize class_name usage
70. [NEW] `docs/code_standards.md` - Create coding standards document
71. [NEW] `docs/architecture.md` - Document project architecture

## 8. Audio System Enhancements

### 8.1 Expand Audio Manager
72. [MODIFY] `scripts/autoload/audio_manager.gd` - Expand with categories and spatial audio
73. [NEW] `scripts/audio/adaptive_music_system.gd` - Create dynamic music system
74. [NEW] `scripts/audio/sound_effect.gd` - Create enhanced sound effect class
75. [MODIFY] `scenes/managers/audio_manager.tscn` - Update with new audio buses