/* dome_lib code by Christian Miller */

import gifAnimation.*;
import java.io.File;

PImage tex;
PGraphics src, targ;
ArrayList<String> anims = new ArrayList<String>();
int n = -1;
Gif anim;
PImage[] frames;
int frame = 0;
DomeDistort dome;
int targetFrameRate = 15;

float angle = 0;

void setup()
{
  //size(1920, 1080, P3D);
  //size(1280, 720, P3D);
  //size(854, 480, P3D);
  size(960, 540, P3D);
  
  frameRate(targetFrameRate);
  
  // set up source buffer for the actual frame data
  src = createGraphics(1024, 1024, P3D);
  
  // set up target buffer to render into
  targ = createGraphics(width, height, P3D);
  
  // create and configure the distortion object
  dome = new DomeDistort(targ, src);
  dome.setTexExtent(0.9); // set to < 1.0 to shrink towards center of dome
  dome.setTexRotation(0); // set to desired rotation angle in radians
  
  // load up some textures
  tex = loadImage("polargrid.png");
  println(dataPath(""));
  
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
  // anim = new Gif(this, anims.get(n));
  // anim.play();
  print(anims.get(n) + "\n");
  frames = Gif.getPImages(this, anims.get(n));
  frame = 0;
}

void keyPressed()
{
  if (key == 'q') {
    noLoop();
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
  if (key >= '1' && key <= '5') {
    println(anims.get(n) + " " + key);
  }
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
  // src.tint(255, 25);
  // drawFullscreenQuad(src, tex); // fade a grid over it
  src.endDraw();
  
  // distort into target image
  dome.update();
  
  // draw distorted image to screen
  background(0);
  image(targ, 0, 0);
  
  // update texture rotation
  angle += 0.002;
  dome.setTexRotation(angle);
}


