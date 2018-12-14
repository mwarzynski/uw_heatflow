mport subprocess
import time
import pygame

# 0 200
# t = 0.5
# 100
def color_interp(start, stop, t):
    assert (t > 0)
    return (
        start[0] + (stop[0] - start[0]) * t,
        start[1] + (stop[1] - start[1]) * t,
        start[2] + (stop[2] - start[2]) * t,
    )

def main():
    pygame.init()

    steps = 60*20

    input = steps*"\n" + "e"
    r = subprocess.run(["./simulation", "./input-file"], input=input.encode("utf-8"), capture_output=True)
    results = r.stdout.decode("utf-8")
    values = [ [float(x) for x in l.split(' ')[:-1]] for l in results.split("\n") ][:-1]
    boards = [ values[i*100:i*100+100] for i in range(0, len(values)//100) ]

    w = pygame.display.set_mode((1000, 1000))

    counter = 0
    for board in boards:
        for y, r in enumerate(board):
            for x, c in enumerate(r):
                red = (255,0,0)
                blue = (0,0,255)
                pygame.draw.rect(w, color_interp(blue, red, c / 255), pygame.Rect(x*10, y*10, 10, 10))
        pygame.display.flip()
        pygame.image.save(w, "video/" + str(counter) + ".bmp")
        counter += 1

    return

if __name__ == "__main__":
    main()

