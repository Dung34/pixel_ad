import 'dart:async';

import 'package:flame/components.dart';

import 'package:flutter/services.dart';
import 'package:pixel_adventure/collisions/collisions.dart';

import 'package:pixel_adventure/enum/player_state/player_state.dart';
import 'package:pixel_adventure/pixel_adventure.dart';
import 'package:pixel_adventure/utils/utils.dart';

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, KeyboardHandler {
  String charater;
  Player({position, required this.charater}) : super(position: position);
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpAnimation;
  late final SpriteAnimation doubleJumpAnimation;
  late final SpriteAnimation fallAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation wallJumpAnimation;
  final double stepTime = 0.05;

  double horizontalmovement = 0;
  final double _gravity = 9.8;
  final double _jumpForce = 300;
  final double _terminalVelocity = 300;
  double moveSpeed = 100;
  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool hasJumped = false;
  List<CollisionsBlock> collisionsBlock = [];

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimation();
    debugMode = true;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updatePlayerState();
    _updatePlayerMovemnet(dt);
    _checkHorizontalCollision();
    _applyGravity(dt);
    _checkVerticalCollision();
    // log(horizontalmovement.toString());
    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalmovement = 0;

    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);
    hasJumped = keysPressed.contains(LogicalKeyboardKey.space);

    horizontalmovement += isLeftKeyPressed ? -1 : 0;
    horizontalmovement += isRightKeyPressed ? 1 : 0;

    return super.onKeyEvent(event, keysPressed);
  }

  void _loadAllAnimation() {
    idleAnimation = _spriteAnimation('Idle', 11);
    runningAnimation = _spriteAnimation('Run', 12);
    jumpAnimation = _spriteAnimation('Jump', 1);
    doubleJumpAnimation = _spriteAnimation('Double Jump', 6);
    fallAnimation = _spriteAnimation('Fall', 1);
    hitAnimation = _spriteAnimation("Hit", 7);
    wallJumpAnimation = _spriteAnimation("Wall Jump", 5);

    //Lists of all animations
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpAnimation,
      PlayerState.doubleJump: doubleJumpAnimation,
      PlayerState.wallJump: wallJumpAnimation,
      PlayerState.fall: fallAnimation,
      PlayerState.hit: hitAnimation
    };
    //Set current animation
  }

  SpriteAnimation _spriteAnimation(String charaterState, int frame) {
    return SpriteAnimation.fromFrameData(
        game.images
            .fromCache('Main Characters/$charater/$charaterState (32x32).png'),
        SpriteAnimationData.sequenced(
            amount: frame, stepTime: stepTime, textureSize: Vector2.all(32)));
  }

  void _updatePlayerMovemnet(double dt) {
    // velocity = Vector2(dirX, 0.0);
    if (hasJumped && isOnGround) _playerJump(dt);
    if (velocity.y > _gravity) {
      isOnGround = false;
    }
    velocity.x = horizontalmovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) {
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    hasJumped = false;
    isOnGround = false;
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    }

    if (velocity.x > 0 || velocity.x < 0) {
      playerState = PlayerState.running;
    }

    //check player is falling ??
    if (velocity.y > _gravity) {
      playerState = PlayerState.fall;
    }
    //check Jump
    if (velocity.y < 0) {
      playerState = PlayerState.jumping;
    }
    current = playerState;
  }

  void _checkHorizontalCollision() {
    for (final block in collisionsBlock) {
      if (!block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - width;
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + width;
            break;
          }
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollision() {
    for (final block in collisionsBlock) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - width;
            isOnGround = true;
          }
        }
      } else {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - width;
            isOnGround = true;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height;
          }
        }
      }
    }
  }
}
