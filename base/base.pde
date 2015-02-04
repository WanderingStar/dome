boolean save = false;
boolean waitForClick = true;
int frames = 5;
int frame = 1;

void setup() {
  // if we're saving these, set this to full 1080p, otherwise use the retina equivalent
  if (save) {
    size(1920, 1080, "processing.core.PGraphicsRetina2D");
  } else {
    size(960, 540, "processing.core.PGraphicsRetina2D");
  }
  
  background(0.0);
  
  if (waitForClick) {
    noLoop();
  }
}

void draw() {
  translate(width/2, height/2); // center the origin
  rotate(-PI/2); // 0 radians is up
  
  float outer = max(width/2, height/2);
  ellipse(0, 0, outer * 2, outer *2);
  
  float r = min(width/2, height/2);
  
  ellipse(0, 0, r * 2, r * 2);
  for (float i=0; i<3; i++) {
    Polar p = new Polar(r, (frame + i) * 2.0 * PI / 5.0);
    line(0, 0, p.x, p.y); 
  }
  
  if (save) {
    saveFrame();
  }
  if (frame++ >= frames) {
    noLoop();
  }
}

void mouseClicked() {
  if (waitForClick) {
    redraw();
  }
}

class Polar {
  float x;
  float y;
  
  Polar(float r, float theta) {
    x = r * cos(theta);
    y = r * sin(theta);
  }
}
