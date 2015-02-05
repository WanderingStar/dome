saveFrames = False
waitForClick = False
frameLimit = None
rings = []

class Ring:
    def __init__(self, centerRadius, thickness, pattern=[1], c=color(255,255,255,128), speed=0):
        self.cR = centerRadius
        self.t = thickness
        self.pat = pattern
        self.c = c
        self.s = speed
        self.rotation = 0
    def display(self):
        sweep = 2 * PI / len(self.pat)
        s = self.rotation
        e = s + sweep
        with pushStyle():
            stroke(self.c)
            strokeWeight(self.t)
            strokeCap(SQUARE)
            fill(0,0,0,0)
            for p in self.pat:
                if p:
                    arc(0,0, self.cR,self.cR, s,e)
                s = e
                e += sweep
    def step(self):
        self.rotation += self.s

def setup():
    if saveFrames:
        size(1920, 1080, "processing.core.PGraphicsRetina2D")
    else:
        size(960, 540, "processing.core.PGraphicsRetina2D")
    background(0)
    if waitForClick:
        noLoop()
    
    colorMode(HSB, 360)
    maxR = dist(0,0, width,height)
    r = 50
    while r < maxR:
        c = color(random(360), 360, 360)
        pattern = [int(random(2)) for i in range(random(24)+1)]
        print(pattern)
        rings.append(Ring(r, 20, pattern, c, random(PI/24)))
        r += 50
    
        
def draw():
    translate(width/2, height/2) # center origin
    rotate(-PI/2) # 0 radians is up
    background(0)
    
    for ring in rings:
        ring.display()
        ring.step()

    if saveFrames:
        saveFrame()
    if frameLimit and frameCount >= frameLimit:
        noLoop()
        
def mouseClicked():
    if waitForClick:
        redraw()
    
