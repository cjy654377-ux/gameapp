import 'dart:async';
import 'dart:collection';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:gameapp/core/enums/monster_element.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/presentation/flame/components/damage_text.dart';
import 'package:gameapp/presentation/flame/components/monster_sprite.dart';
import 'package:gameapp/presentation/flame/components/particle_effects.dart';
import 'package:gameapp/presentation/providers/battle_provider.dart';

/// Animation event derived from BattleLogEntry.
class _AnimEvent {
  final String attackerId;
  final String targetId;
  final int damage;
  final bool isCritical;
  final bool isSkill;
  final bool isElementAdvantage;

  _AnimEvent({
    required this.attackerId,
    required this.targetId,
    required this.damage,
    required this.isCritical,
    required this.isSkill,
    required this.isElementAdvantage,
  });
}

/// The Flame game that renders battle monsters and animations.
/// Background is transparent — Flutter Image.asset is layered beneath.
class BattleGame extends FlameGame {
  /// Speed multiplier for all animations.
  double animSpeed = 1.0;

  // Sprite lookup by monsterId
  final Map<String, MonsterSpriteComponent> _sprites = {};

  // Animation queue
  final Queue<_AnimEvent> _animQueue = Queue();
  bool _isAnimating = false;

  // Track processed log length per battle
  int _processedLogLen = 0;

  // Pending state: saved when update arrives before layout is ready.
  BattleState? _pendingState;
  bool _layoutReady = false;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    // nothing — wait for state updates
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layoutReady = true;
    // Process any pending state that arrived before layout was ready.
    if (_pendingState != null) {
      final s = _pendingState!;
      _pendingState = null;
      updateBattleState(s);
    }
  }

  /// Called by BattleArenaWidget whenever BattleState changes.
  void updateBattleState(BattleState state) {
    animSpeed = state.battleSpeed;

    if (state.phase == BattlePhase.idle || state.phase == BattlePhase.preparing) {
      _clearAll();
      _pendingState = null;
      return;
    }

    // If layout not ready yet, defer.
    if (!_layoutReady) {
      _pendingState = state;
      return;
    }

    // Rebuild sprites if teams changed (new battle started)
    final playerIds = state.playerTeam.map((m) => m.monsterId).toSet();
    final enemyIds = state.enemyTeam.map((m) => m.monsterId).toSet();
    final allIds = {...playerIds, ...enemyIds};

    if (!_sameKeys(allIds)) {
      _rebuildSprites(state);
    }

    // Update monster data
    for (final m in state.playerTeam) {
      _sprites[m.monsterId]?.updateMonster(m);
    }
    for (final m in state.enemyTeam) {
      _sprites[m.monsterId]?.updateMonster(m);
    }

    // Queue new log entries as animations
    if (state.battleLog.length > _processedLogLen) {
      for (var i = _processedLogLen; i < state.battleLog.length; i++) {
        final entry = state.battleLog[i];
        // Find attacker and target by name
        final attackerId = _findMonsterIdByName(state, entry.attackerName);
        final targetId = _findMonsterIdByName(state, entry.targetName);
        if (attackerId != null && targetId != null) {
          _animQueue.add(_AnimEvent(
            attackerId: attackerId,
            targetId: targetId,
            damage: entry.damage.round(),
            isCritical: entry.isCritical,
            isSkill: entry.isSkillActivation,
            isElementAdvantage: entry.isElementAdvantage,
          ));
        }
      }
      _processedLogLen = state.battleLog.length;
      _processQueue();
    }
  }

  String? _findMonsterIdByName(BattleState state, String name) {
    for (final m in state.playerTeam) {
      if (m.name == name) return m.monsterId;
    }
    for (final m in state.enemyTeam) {
      if (m.name == name) return m.monsterId;
    }
    return null;
  }

  bool _sameKeys(Set<String> ids) {
    if (ids.length != _sprites.length) return false;
    for (final id in ids) {
      if (!_sprites.containsKey(id)) return false;
    }
    return true;
  }

  void _clearAll() {
    for (final s in _sprites.values) {
      s.removeFromParent();
    }
    _sprites.clear();
    _animQueue.clear();
    _isAnimating = false;
    _processedLogLen = 0;
  }

  void _rebuildSprites(BattleState state) {
    _clearAll();

    final gameW = size.x;
    final gameH = size.y;

    // Layout: player team on left, enemy team on right
    _layoutTeam(state.playerTeam, true, gameW, gameH);
    _layoutTeam(state.enemyTeam, false, gameW, gameH);
  }

  void _layoutTeam(List<BattleMonster> team, bool isLeft, double gameW, double gameH) {
    if (team.isEmpty) return;

    final centerX = isLeft ? gameW * 0.25 : gameW * 0.75;
    final count = team.length;

    // 2-column layout: col1 and col2
    final col1 = <BattleMonster>[];
    final col2 = <BattleMonster>[];
    for (var i = 0; i < count; i++) {
      if (i % 2 == 0) {
        col1.add(team[i]);
      } else {
        col2.add(team[i]);
      }
    }

    final colOffset = count > 1 ? 28.0 : 0.0;

    _layoutColumn(col1, centerX - colOffset, gameH, isLeft);
    _layoutColumn(col2, centerX + colOffset, gameH, isLeft);
  }

  void _layoutColumn(List<BattleMonster> col, double x, double gameH, bool isLeft) {
    if (col.isEmpty) return;
    final spacing = (gameH - 40) / (col.length + 1);
    for (var i = 0; i < col.length; i++) {
      final y = 20 + spacing * (i + 1);
      final sprite = MonsterSpriteComponent(
        monster: col[i],
        isPlayerSide: isLeft,
        position: Vector2(x, y),
      );
      add(sprite);
      _sprites[col[i].monsterId] = sprite;
    }
  }

  /// Process animation queue sequentially.
  Future<void> _processQueue() async {
    if (_isAnimating) return;
    _isAnimating = true;

    while (_animQueue.isNotEmpty) {
      final event = _animQueue.removeFirst();
      await _playAttackAnimation(event);
    }

    _isAnimating = false;
  }

  Future<void> _playAttackAnimation(_AnimEvent event) async {
    final attacker = _sprites[event.attackerId];
    final target = _sprites[event.targetId];
    if (attacker == null || target == null) return;

    final duration = 0.15 / animSpeed;

    // Lunge toward target
    final direction = (target.position - attacker.position).normalized() * 15;
    attacker.add(MoveByEffect(
      direction,
      EffectController(duration: duration, reverseDuration: duration),
    ));

    // Wait for lunge to reach target
    await Future.delayed(Duration(milliseconds: (duration * 1000).round()));

    // Hit effects on target
    target.playHitShake();
    target.playFlash();

    // Damage text
    add(DamageTextComponent(
      damage: event.damage,
      isCritical: event.isCritical,
      isSkill: event.isSkill,
      isElementAdvantage: event.isElementAdvantage,
      spawnPosition: target.position + Vector2(0, -30),
    ));

    // Particle effects
    final elem = _getElementColor(event.targetId);

    if (event.isCritical) {
      final particles = ParticleEffects.criticalSparkle(target.position.clone());
      for (final p in particles) {
        add(p);
      }
    }

    final hitParticles = ParticleEffects.hitExplosion(target.position.clone(), elem);
    for (final p in hitParticles) {
      add(p);
    }

    if (event.isSkill) {
      add(ParticleEffects.skillRing(attacker.position.clone(), elem));

      // Element-specific attack effect from attacker to target
      final attackerElem = _getElementName(event.attackerId);
      final elemEffects = ParticleEffects.elementAttack(
        attackerElem,
        attacker.position.clone(),
        target.position.clone(),
      );
      for (final e in elemEffects) {
        add(e);
      }
    }

    // Wait for hit animation to complete
    await Future.delayed(Duration(milliseconds: (duration * 1000).round()));
  }

  Color _getElementColor(String monsterId) {
    // Try to get element color from sprite's monster data
    final sprite = _sprites[monsterId];
    if (sprite != null) {
      final elem = MonsterElement.fromName(sprite.monster.element);
      if (elem != null) return elem.color;
    }
    return Colors.white;
  }

  /// Returns the element name string (e.g. 'fire') for a given monsterId.
  String _getElementName(String monsterId) {
    final sprite = _sprites[monsterId];
    if (sprite != null) return sprite.monster.element;
    return '';
  }
}
