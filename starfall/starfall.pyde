saveFrames = False
waitForClick = False
frameLimit = None
stars = []

class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y
    @staticmethod
    def fromPolar(r, theta):
        return Point(r * cos(theta), r * sin(theta))

class Star:
    def __init__(self, theta, tailLength, speed):
        self.head = 0
        self.theta = theta
        self.tailLength = tailLength
        self.speed = speed
    def display(self):
        with pushMatrix():
            rotate(self.theta)
            translate(self.head, 0)
            s = sqrt(self.speed)
            with pushStyle():
                noStroke()
                with pushStyle():
                    fill(255,255,255, 127)
                    triangle(0, s/2, 0, -s/2, -self.tailLength, 0)
                ellipse(0, 0, s, s)
    def step(self):
        self.head += self.speed

def setup():
    if saveFrames:
        size(1920, 1080, "processing.core.PGraphicsRetina2D")
    else:
        size(960, 540, "processing.core.PGraphicsRetina2D")
    background(0)
    if waitForClick:
        noLoop()
        
def draw():
    translate(width/2, height/2) # center origin
    rotate(-PI/2) # 0 radians is up
    background(0)
    
    edge = max(width, height)
    
    while len(stars) < 10000:
        distance = random(edge/100)
        stars.append(Star(random(2 * PI), distance, distance))
    
    for star in stars:
        star.display()
        star.step()
    stars = [s for s in stars if s.head < edge]

    if saveFrames:
        saveFrame()
    if frameLimit and frameCount >= frameLimit:
        noLoop()
        
def mouseClicked():
    if waitForClick:
        redraw()
    
