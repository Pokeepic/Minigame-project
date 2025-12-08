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
FPS = 12  # game speed (higher = faster)

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

    # Initial snake (length 3, centered)
    snake = [
        (GRID_WIDTH // 2, GRID_HEIGHT // 2),
        (GRID_WIDTH // 2 - 1, GRID_HEIGHT // 2),
        (GRID_WIDTH // 2 - 2, GRID_HEIGHT // 2),
    ]
    direction = (1, 0)  # moving to the right initially (dx, dy)

    food = random_food_position(snake)
    score = 0
    game_over = False

    while True:
        # -----------------------------
        # EVENT HANDLING
        # -----------------------------
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()

            if event.type == pygame.KEYDOWN:
                if not game_over:
                    # Change direction with arrow keys / WASD
                    if event.key in (pygame.K_UP, pygame.K_w):
                        # Prevent instant reverse
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
                else:
                    # When game over, press SPACE to restart, ESC to quit
                    if event.key == pygame.K_SPACE:
                        return main()  # restart game
                    elif event.key == pygame.K_ESCAPE:
                        pygame.quit()
                        sys.exit()

        if not game_over:
            # -----------------------------
            # UPDATE GAME STATE
            # -----------------------------
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
                game_over = True
            else:
                snake.insert(0, new_head)  # add new head

                # Check if ate food
                if new_head == food:
                    score += 1
                    food = random_food_position(snake)
                    # Do not remove tail (snake grows)
                else:
                    snake.pop()  # remove tail (snake moves)

        # -----------------------------
        # DRAW
        # -----------------------------
        screen.fill(BLACK)
        draw_grid(screen)
        draw_snake(screen, snake)
        draw_food(screen, food)

        # Draw score
        score_text = f"Score: {score}"
        draw_text(screen, score_text, font, WHITE, (80, 20))

        if game_over:
            draw_text(screen, "GAME OVER", big_font, WHITE, (WIDTH // 2, HEIGHT // 2 - 30))
            draw_text(screen, "Press SPACE to restart or ESC to quit",
                      font, WHITE, (WIDTH // 2, HEIGHT // 2 + 10))

        pygame.display.flip()
        clock.tick(FPS)

# -----------------------------
# ENTRY POINT
# -----------------------------
if __name__ == "__main__":
    main()
