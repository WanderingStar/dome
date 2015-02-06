saveFrames = True
waitForClick = False
frameLimit = 1200
n = 20
rings = []
rate = 10
h = 0

class Ring:
    def __init__(self, centerRadius, thickness, pattern=[1], c=color(255,255,255,128), rotation=0, zoom=0):
        self.cR = centerRadius
        self.t = thickness
        self.pat = pattern
        self.c = c
        self.r = rotation
        self.z = zoom
        self.angle = 0
    def display(self):
        sweep = 2 * PI / len(self.pat)
        s = self.angle
        e = s + sweep
        with pushStyle():
            stroke(self.c)
            strokeWeight(self.t)
            fill(0,0,0,0)
            for p in self.pat:
                if p:
                    arc(0,0, self.cR,self.cR, s,e)
                s = e
                e += sweep
    def step(self):
        self.angle += self.r
        self.cR += self.z

def setup():
    if saveFrames:
        size(1920, 1080, "processing.core.PGraphicsRetina2D")
    else:
        size(960, 540, "processing.core.PGraphicsRetina2D")
    background(0)
    if waitForClick:
        noLoop()

    
def randomPattern():
    pattern =  [1] + [int(random(2)) for i in range(random(10)+1)]
    #pattern = [1, 0] * int(random(10) + 1) #+ [0] * int(random(5))
    #pattern = [1]
    print(pattern)
    return pattern
        
def draw():
    translate(width/2, height/2) # center origin
    rotate(-PI/2) # 0 radians is up
    background(0)
    
    for ring in rings:
        ring.display()
        ring.step()
    
    maxR = dist(0,0, width,height)
    r = maxR / n
    radius = r / 2
    v = 128 + int(random(128))
    c = color(255, 255, 255, v)
    if random(10) < 1:
        h = (h + random(30)) % 360
        rings.append(Ring(r, random(1) * r, randomPattern(), c, random(PI/12) - PI/24, (1 + random(2)) *  r / rate))
        radius += r
    
    rings = [r for r in rings if r.cR < maxR]

    if saveFrames:
        saveFrame("frames/####.png")
        print("Frame {} Rings {}".format(frameCount, len(rings)))
    if frameLimit and frameCount >= frameLimit:
        noLoop()
        
def mouseClicked():
    if waitForClick:
        redraw()
    
