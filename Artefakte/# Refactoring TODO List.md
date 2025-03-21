# The Little Saint - Adjusted Refactoring Plan

Based on your current project state, I've adjusted the refactoring plan for the remaining tasks (19-75). I've observed that you've successfully implemented:

- Base classes (BaseEnemy, BasePowerUp, BaseProjectile)
- State machine framework
- Player and enemy state classes
- Modified existing scripts to work with the new architecture

Here's the adjusted plan with proper sequencing to prevent duplicate file modifications:

## Phase 1: Core Infrastructure & Game Management (Foundation
 First)

1. [NEW] `scripts/utils/constants.gd` (Task 68) - Create global constants file for game settings
2. [MODIFY] `scripts/autoload/game_manager.gd` (Task 19) - Develop the empty manager with:
   - Game state tracking (menu, playing, paused, game over)
   - Scene management functionality
   - Global event handling
3. [NEW] `scripts/autoload/save_manager.gd` (Task 22) - Create dedicated save manager that:
   - Handles saving/loading player data
   - Manages outfit configurations
   - Includes error handling and validation
4. [NEW] `scripts/utils/save_data.gd` (Task 23) - Create data structure for saved games
5. [NEW] `scripts/resources/player_outfit_resource.gd` (Task 31) - Create resource-based outfit system

## Phase 2: Player System Enhancements (Building on State Machine)

6. [MODIFY] `scripts/core/characters/player.gd` (Tasks 25, 26, 63) - Complete refactoring by:
   - Integrating with SaveManager (replace ConfigFile usage)
   - Optimizing signal connections
   - Ensuring proper state machine integration
7. [MODIFY] `scripts/ui/character_customizer/customizer_controller.gd` (Tasks 24, 32) - Improve by:
   - Using SaveManager instead of ConfigFile
   - Implementing resource-based outfit system
8. [MODIFY] `scripts/ui/character_customizer/preview_helper.gd` (Task 34) - Optimize preview generation
9. [MODIFY] `scripts/ui/character_customizer/outfit_showcase.gd` (Task 33) - Improve UI feedback

## Phase 3: UI Framework & Dialog Enhancements

10. [NEW] `scripts/ui/theme/ui_theme.gd` (Task 45) - Create consistent UI theme
11. [MODIFY] `scripts/ui/dialogs/popup_dialog.gd` (Task 54) - Enhance with animations and polish
12. [NEW] `scripts/ui/dialogs/conversation_system.gd` (Task 55) - Create NPC conversation system
13. [NEW] `scripts/ui/dialogs/dialog_tree.gd` (Task 56) - Implement branching dialogs
14. [NEW] `scripts/ui/components/button_with_sound.gd` (Task 47) - Create button with sound effects
15. [NEW] `scripts/ui/transitions/screen_transition.gd` (Task 48) - Create screen transition effects

## Phase 4: HUD & User Experience

16. [MODIFY] `scripts/ui/hud/hud_controller.gd` (Tasks 44, 50) - Enhance with:
    - Improved health display
    - Better damage feedback
    - Animations for UI changes
17. [NEW] `scripts/ui/hud/mini_map.gd` (Task 51) - Add mini-map component
18. [NEW] `scripts/ui/hud/objective_tracker.gd` (Task 52) - Add objective tracking
19. [MODIFY] `scenes/ui/hud/hud.tscn` (Task 53) - Update with new components
20. [MODIFY] `scenes/ui/main_menu/main_menu.tscn` (Task 49) - Update with new UI components

## Phase 5: Combat System & Enemy Behaviors

21. [NEW] `scripts/core/combat/damage_system.gd` (Task 41) - Create system for damage handling
22. [NEW] `scripts/core/combat/hit_effect.gd` (Task 42) - Create visual effects for hits
23. [NEW] `scripts/core/combat/screen_shake.gd` (Task 43) - Add screen shake effect
24. [NEW] `scripts/core/enemies/behaviors/patrol_behavior.gd` (Task 35) - Create modular patrol behavior
25. [NEW] `scripts/core/enemies/behaviors/chase_behavior.gd` (Task 36) - Create modular chase behavior
26. [NEW] `scripts/core/enemies/behaviors/attack_behavior.gd` (Task 37) - Create modular attack behavior
27. [NEW] `scripts/core/enemies/behaviors/ranged_attack.gd` (Task 38) - Create ranged attack component
28. [NEW] `scripts/core/enemies/behaviors/melee_attack.gd` (Task 39) - Create melee attack component
29. [NEW] `scripts/managers/enemy_manager.gd` (Task 40) - Create manager for enemy spawning and waves

## Phase 6: Performance Optimization & Resource Management

30. [NEW] `scripts/utils/resource_preloader.gd` (Task 58) - Create resource preloading manager
31. [NEW] `scripts/utils/object_pool.gd` (Task 59) - Implement object pooling system
32. [NEW] `scripts/utils/performance_monitor.gd` (Task 64) - Add monitoring capabilities
33. [MODIFY] `scripts/core/projectiles/mage_ball.gd` (Task 60) - Use object pooling
34. [MODIFY] `scripts/core/projectiles/rock.gd` (Task 61) - Use object pooling

## Phase 7: Audio System Enhancements

35. [MODIFY] `scripts/autoload/audio_manager.gd` (Task 72) - Expand with:
    - Audio categories (Music, SFX, UI, Ambient)
    - Volume control
    - Sound effect management
36. [NEW] `scripts/audio/adaptive_music_system.gd` (Task 73) - Create dynamic music system
37. [NEW] `scripts/audio/sound_effect.gd` (Task 74) - Create enhanced sound effect class
38. [MODIFY] `scenes/managers/audio_manager.tscn` (Task 75) - Update with new audio buses

## Phase 8: Development Tools & Documentation

39. [NEW] `scripts/utils/debug_console.gd` (Task 65) - Implement in-game debug console
40. [NEW] `scripts/utils/performance_display.gd` (Task 66) - Add FPS and memory display
41. [NEW] `scripts/utils/cheat_system.gd` (Task 67) - Add cheat code functionality
42. [NEW] `docs/code_standards.md` (Task 70) - Create coding standards document
43. [NEW] `docs/architecture.md` (Task 71) - Document project architecture
44. [REVIEW] (Task 62) - Optimize heavy processing in _process methods
45. [REVIEW] (Task 69) - Standardize class_name usage across all scripts

## Implementation Strategy

1. **Focus on core infrastructure first** - Ensure the game manager, event system, and save system are robust before moving on.
2. **Implement one phase at a time** - Complete each phase before moving to the next to maintain code stability.
3. **Test frequently** - Run the game after each significant change to catch issues early.
4. **Document as you go** - Update documentation in parallel with code changes.
5. **Leverage state machine** - Use the existing state machine for new behaviors instead of creating parallel systems.

## Priority Order

If you need to prioritize certain improvements:

1. Game Manager & Save System (Phase 1)
2. UI Framework & HUD Improvements (Phases 3 & 4)
3. Combat System & Enemy Behaviors (Phase 5)
4. Audio System Enhancements (Phase 7)
5. Performance Optimization (Phase 6)
6. Development Tools (Phase 8)