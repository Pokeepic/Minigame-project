import pygame
import random
import sys

# -----------------------------
# CONFIG
# -----------------------------
CELL_SIZE = 20
GRID_WIDTH = 30   # number of cells horizontally
GRID_HEIGHT = 20  # number of cells vertically

WIDTH = CELL_SIZE * GRID_WIDTH
HEIGHT = CELL_SIZE * GRID_HEIGHT
FPS = 10  # game speed (higher = faster)

# Colors (R, G, B)
BLACK = (0, 0, 0)
GREEN = (0, 200, 0)
DARK_GREEN = (0, 150, 0)
RED = (200, 0, 0)
WHITE = (255, 255, 255)
GRAY = (40, 40, 40)


# -----------------------------
# HELPER FUNCTIONS
# -----------------------------
def random_food_position(snake):
    """Return a random position (x, y) that is not on the snake."""
    while True:
        x = random.randint(0, GRID_WIDTH - 1)
        y = random.randint(0, GRID_HEIGHT - 1)
        if (x, y) not in snake:
            return (x, y)


def draw_grid(surface):
    """Optional: draw a subtle grid background."""
    for x in range(0, WIDTH, CELL_SIZE):
        pygame.draw.line(surface, GRAY, (x, 0), (x, HEIGHT))
    for y in range(0, HEIGHT, CELL_SIZE):
        pygame.draw.line(surface, GRAY, (0, y), (WIDTH, y))


def draw_snake(surface, snake):
    """Draw the snake on the surface."""
    for i, (x, y) in enumerate(snake):
        # Head slightly brighter
        color = DARK_GREEN if i == 0 else GREEN
        rect = pygame.Rect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
        pygame.draw.rect(surface, color, rect)


def draw_food(surface, food_pos):
    """Draw the food."""
    x, y = food_pos
    rect = pygame.Rect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
    pygame.draw.rect(surface, RED, rect)


def draw_text(surface, text, font, color, center):
    """Draw centered text."""
    render = font.render(text, True, color)
    rect = render.get_rect(center=center)
    surface.blit(render, rect)


def reset_game():
    """Create a fresh game state."""
    snake = [
        (GRID_WIDTH // 2, GRID_HEIGHT // 2),
        (GRID_WIDTH // 2 - 1, GRID_HEIGHT // 2),
        (GRID_WIDTH // 2 - 2, GRID_HEIGHT // 2),
    ]
    direction = (1, 0)  # moving right
    food = random_food_position(snake)
    score = 0
    return snake, direction, food, score


# -----------------------------
# MAIN GAME FUNCTION
# -----------------------------
def main():
    pygame.init()
    screen = pygame.display.set_mode((WIDTH, HEIGHT))
    pygame.display.set_caption("Simple Snake Game")
    clock = pygame.time.Clock()
    font = pygame.font.SysFont(None, 32)
    big_font = pygame.font.SysFont(None, 52)

    # Game state
    snake, direction, food, score = reset_game()
    state = "MENU"  # "MENU", "PLAYING", "PAUSED", "GAME_OVER"

    while True:
        # -----------------------------
        # EVENT HANDLING
        # -----------------------------
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()

            if event.type == pygame.KEYDOWN:

                # ===== MAIN MENU CONTROLS =====
                if state == "MENU":
                    if event.key in (pygame.K_RETURN, pygame.K_SPACE):
                        # Start a new game
                        snake, direction, food, score = reset_game()
                        state = "PLAYING"
                    elif event.key == pygame.K_ESCAPE:
                        pygame.quit()
                        sys.exit()

                # ===== PLAYING CONTROLS =====
                elif state == "PLAYING":
                    # Change direction with arrow keys / WASD
                    if event.key in (pygame.K_UP, pygame.K_w):
                        if direction != (0, 1):
                            direction = (0, -1)
                    elif event.key in (pygame.K_DOWN, pygame.K_s):
                        if direction != (0, -1):
                            direction = (0, 1)
                    elif event.key in (pygame.K_LEFT, pygame.K_a):
                        if direction != (1, 0):
                            direction = (-1, 0)
                    elif event.key in (pygame.K_RIGHT, pygame.K_d):
                        if direction != (-1, 0):
                            direction = (1, 0)
                    elif event.key == pygame.K_p:
                        # Pause game
                        state = "PAUSED"

                # ===== PAUSED CONTROLS =====
                elif state == "PAUSED":
                    if event.key == pygame.K_p:
                        # Resume game
                        state = "PLAYING"
                    elif event.key == pygame.K_ESCAPE:
                        # Back to menu
                        state = "MENU"

                # ===== GAME OVER CONTROLS =====
                elif state == "GAME_OVER":
                    if event.key in (pygame.K_SPACE, pygame.K_RETURN):
                        # Restart game immediately
                        snake, direction, food, score = reset_game()
                        state = "PLAYING"
                    elif event.key == pygame.K_ESCAPE:
                        # Back to main menu
                        state = "MENU"

        # -----------------------------
        # UPDATE GAME STATE
        # -----------------------------
        if state == "PLAYING":
            head_x, head_y = snake[0]
            dx, dy = direction
            new_head = (head_x + dx, head_y + dy)

            # Check wall collision
            out_of_bounds = (
                new_head[0] < 0 or new_head[0] >= GRID_WIDTH or
                new_head[1] < 0 or new_head[1] >= GRID_HEIGHT
            )

            # Check self collision
            hit_self = new_head in snake

            if out_of_bounds or hit_self:
                state = "GAME_OVER"
            else:
                snake.insert(0, new_head)  # add new head

                # Check if ate food
                if new_head == food:
                    score += 1
                    food = random_food_position(snake)
                else:
                    snake.pop()  # move (remove tail)

        # -----------------------------
        # DRAW
        # -----------------------------
        screen.fill(BLACK)

        if state == "MENU":
            # Just show main menu
            title_y = HEIGHT // 2 - 60
            draw_text(screen, "SNAKE GAME", big_font, WHITE, (WIDTH // 2, title_y))
            draw_text(screen, "Press ENTER or SPACE to Play",
                      font, WHITE, (WIDTH // 2, title_y + 50))
            draw_text(screen, "Press ESC to Quit",
                      font, WHITE, (WIDTH // 2, title_y + 90))

        else:
            # Common game view (grid, snake, food, score)
            draw_grid(screen)
            draw_snake(screen, snake)
            draw_food(screen, food)

            # Draw score
            score_text = f"Score: {score}"
            draw_text(screen, score_text, font, WHITE, (80, 20))

            if state == "PAUSED":
                draw_text(screen, "PAUSED", big_font, WHITE, (WIDTH // 2, HEIGHT // 2 - 20))
                draw_text(screen, "Press P to Resume | ESC for Menu",
                          font, WHITE, (WIDTH // 2, HEIGHT // 2 + 20))

            if state == "GAME_OVER":
                draw_text(screen, "GAME OVER", big_font, WHITE, (WIDTH // 2, HEIGHT // 2 - 40))
                draw_text(screen, "SPACE/ENTER: Restart  |  ESC: Menu",
                          font, WHITE, (WIDTH // 2, HEIGHT // 2))

        pygame.display.flip()
        clock.tick(FPS)


# -----------------------------
# ENTRY POINT
# -----------------------------
if __name__ == "__main__":
    main()
