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
    def headPoint(self):
        return Point.fromPolar(self.head, self.theta)
    def tailPoint(self):
        tail = max(0, self.head - self.tailLength)
        return Point.fromPolar(tail, self.theta)
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
    
    while len(stars) < 1000:
        distance = random(edge/100)
        stars.append(Star(random(2 * PI), distance, distance))
    
    stroke('#FFFFFF')
    for star in stars:
        head = star.headPoint()
        tail = star.tailPoint()
        line(head.x, head.y, tail.x, tail.y)
        star.step()
    stars = [s for s in stars if s.head < edge]

    if saveFrames:
        saveFrame()
    if frameLimit and frameCount >= frameLimit:
        noLoop()
        
def mouseClicked():
    if waitForClick:
        redraw()
    
