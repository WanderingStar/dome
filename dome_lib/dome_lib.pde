/* dome_lib code by Christian Miller */

import gifAnimation.*;
import java.io.File;

PGraphics src, targ;
ArrayList<String> anims = new ArrayList<String>();
int n = -1;
Gif anim;
PImage[] frames;
int frame = 0;
DomeDistort dome;
int targetFrameRate = 30;

// mode flags
boolean invert = false;
boolean line_mode = false;

float angle = 0;

void setup()
{
  //size(1024, 1024, P3D);
  //size(1920, 1080, P3D);
  size(1280, 720, P3D);
  //size(854, 480, P3D);
  //size(960, 540, P3D);
  
  frameRate(targetFrameRate);
  
  // set up source buffer for the actual frame data
  src = createGraphics(1024, 1024, P3D);
  
  // set up target buffer to render into
  targ = createGraphics(width, height, P3D);
  
  // create and configure the distortion object
  dome = new DomeDistort(targ, src);
  dome.setTexExtent(0.9); // set to < 1.0 to shrink towards center of dome
  dome.setTexRotation(0); // set to desired rotation angle in radians
  
  println(dataPath(""));
  
  // make list of animations
  File dir = new File(dataPath(""));
  for (String filename : dir.list()) {
    if (filename.endsWith(".gif")) {
      anims.add(filename);
    }
  }
  nextAnim();
}

void nextAnim()
{
  n = (n + 1) % anims.size();
  print(anims.get(n) + "\n");
  frames = Gif.getPImages(this, anims.get(n));
  frame = 0;
}

void keyPressed()
{
  if (key == '\\')
  {
    targ.save("screenshot.png");
    return;
  }
  if (key == 'i') {
    invert = !invert;
    dome.setColorTransformInvert(invert ? 1 : 0);
    return;
  }
  if (key == 'l') {
    line_mode = !line_mode;
    return;
  }
  if (key == '-') {
    if (targetFrameRate > 0) {
      targetFrameRate--;
      frameRate(targetFrameRate);
    }
    print("Framerate now " + targetFrameRate + "\n");
    return;
  }
  if (key == '+' || key == '=') {
    targetFrameRate++;
    frameRate(targetFrameRate);
    print("Framerate now " + targetFrameRate + "\n");
    return;
  }
  
  // fall through to move to the next animation
  nextAnim();
}

// stretches an image over the entire target canvas
void drawFullscreenQuad(PGraphics t, PImage i)
{
  t.beginShape();
  t.texture(i);
  t.vertex(0, 0, 0, 0);
  t.vertex(t.width, 0, i.width, 0);
  t.vertex(t.width, t.height, i.width, i.height);
  t.vertex(0, t.height, 0, i.height);
  t.endShape();
}

void draw()
{
  // draw pattern into source texture
  src.beginDraw();
  src.background(0);
  src.tint(255, 255);
  drawFullscreenQuad(src, frames[frame]); // draw a frame from the gif
  frame = (frame + 1) % frames.length;
  src.endDraw();
  
  // distort into target image
  dome.update();
  
  // draw distorted image to screen
  background(0);
  
  // override image if we're in line mode
  if (line_mode)
  {
    stroke(255);
    line(width/2, 0, width/2, height);
  }
  else
    image(targ, 0, 0);
  
  // update texture rotation
  angle += 0.002;
  //dome.setTexRotation(angle);
}


