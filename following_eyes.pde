
import SimpleOpenNI.*;
SimpleOpenNI  kinect;
PImage eyeTexture;
PShape globe;

// display resolution of the screen (adjust for your own display)
int displayWidth = 800;
int displayHeight = 600;

// size of Kinect's depth map
int width = 640;
int height = 480;
float kinectX = displayWidth - width;
float kinectY = displayHeight - height;

float rx = 0; //randomX
float ry = 0; //randomY
float tx = 0; //definedX
float ty = 0; //definedY
float tr = 0; //defined radius
int fn = 0; //fileNumber
boolean debug = false;

//boolean sketchFullScreen() {
//    return true;
//}


// position and user ID of target
PVector target;
int targetId;
//-=-=-=-=-=-=

int timer;
int maxEyes = 6; //number of eyes
float miner = 20; //minimum eye size
float maxer = 180; //maximum eye size
float mFactor = 0.85; //margin
ArrayList theEyes;
int maxTries= 10000;
float x;
float y;
float easing = 0.05;//amount of easing higher =faster lower = slower 0.05 default
PImage mask, eye, shadow, reflection;

PImage[] myImageArray = new PImage[8];


void setup () {
  
// gather eye_00?.png files and place them in an array
  for (int i=0; i<myImageArray.length; i++){
  myImageArray[i] = loadImage( "data/eyes_00" + i + ".png");
}
  
  shadow = loadImage("data/EyesShadow.png");//eyeshadows and mask layer
  reflection = loadImage("data/Reflection.png");//reflection dots
  
  size(displayWidth, displayHeight,P3D);//project size = display res
  
    //-=-=-=-
     kinect = new SimpleOpenNI(this);
     kinect.enableDepth();
     kinect.enableUser();
     kinect.setMirror(true);// mirror the data
  
  //=-=-=-=-

  theEyes = new ArrayList();
   while (theEyes.size() < maxEyes) {
      float tr = random (miner, maxer); // select random radius
   

//Define eyes here (tx=X axis, ty=y axis, tr=radius, fn=eye file number(for alternate eye colors)   
  //0=blue, 1=grey, 2=green, 3=orange, 4=purple, 5=pink, 6=turquoise, 7=yellow
  for (int j=0; j < (maxEyes); j++){
    if (j == 5){ 
       fn = (1);   //eye selection
       tx = (102); //x-position
       ty = (400); //y-position
       tr = (20);  //radius
      
    }
    if (j == 4){ 
       fn = (2);   //eye selection
       tx = (320); //x-position
       ty = (80); //y-position
       tr = (30); //radius
       
     }
    if (j == 3){ 
       fn = (3);   //eye selection
       tx = (620); //x-position
       ty = (340); //y-position
       tr = (40);  //radius
       
    }
    if (j == 2){ 
       fn = (4);  //eye selection
       tx = (50); //x-position
       ty = (70); //y-position
       tr = (50); //radius
       
    }
    if (j == 1){ 
       fn = (5);   //eye selection
       tx = (120); //x-position
       ty = (240); //y-position
       tr = (60);  //radius
      
    }
    if (j == 0){ 
       fn = (7);   //eye selection
       tx = (430); //x-position
       ty = (356); //y-position
       tr = (90);  //radius
       
    }
   
  
   PVector tc = new PVector (tx,ty); //place eyes in locations listed above
  
   //-=-=-=-
    boolean noOverlap = true;
    for (int i=0; i <theEyes.size(); i++) {
      eyeBall eye = (eyeBall) theEyes.get(i);
      if (tc.dist(eye.wc) < (eye.r + tr+2)) { noOverlap = false; }
    }
    if (noOverlap)  { theEyes.add (new eyeBall (tc, tr)); }
  }
}
  //-----TESTING 3D SPHERE Creation----
translate(width/2, height/2, -300);
hint(DISABLE_DEPTH_MASK);
 noStroke();
  fill(255);
  sphereDetail(40);
  eyeTexture= loadImage("/data/eyes_001.png");
  globe = createShape(SPHERE,40);
  globe.setTexture (eyeTexture);
  //-----------------
}



void draw () {

background(0);
  
   // tell the kinect to grab a new image
  kinect.update();
   if (millis() - timer >= 5000) {
     rx = random(displayWidth);
     ry = random(displayHeight);
   timer = millis();
 }
   // all available targets
  IntVector userList = new IntVector();
  kinect.getUsers(userList);
  
  // if there's a target and they stayed in frame, get their new position
  if (target != null) {
    PVector center = centerFor(targetId);
   
    if (center == null) {
      println("Lost target: " + targetId);
      target = null;
      targetId = -1;
    } else
      target = center;   
  }
  
  // if we don't have the target, or we lost it, find the next valid target
  if (target == null) {
    for (int i=0; i<userList.size(); i++) {
      int userId = userList.get(i);
      
      PVector center = centerFor(userId);
      
      if (center != null) {
        target = center;
        targetId = userId;
        println("Got target: " + userId);
      }
    }
  }
      
    if (target != null)  //if we'ev got a target
       if (debug){   //and if we are in debugging mode
       PImage depth = kinect.depthImage(); // show the depth image
       image(depth, kinectX,kinectY);  
       littleEye(kinectX + target.x, kinectY + target.y); //and put little eyes on i
    } else {
//------------Easing------------------------------
  float targetX = target.x;
  //  float targetX = kinectX;
  float dx = targetX - x;
  x += dx * easing;
 
  float targetY = target.y;
  //float targetY = kinectX;
  float dy = targetY - y;
  y += dy * easing;
  
  background (0,0,1);
//---------------------------------------------- 
//---- draw eyes--------------------------------
 
 for (int i=0; i <theEyes.size(); i++) {
      eyeBall eye = (eyeBall) theEyes.get(i);
      eye.display(new PVector (x, y)); //folow with easing
 }
}

    if (target == null){
  

   float targetX = rx;
   float dx = targetX - x;
    x += dx * easing;
 
   float targetY = ry;
   float dy = targetY - y;
    y += dy * easing;
    
    background (0,0,0);  
 
   for (int i=0; i <theEyes.size(); i++) {
      eyeBall eye = (eyeBall) theEyes.get(i);
    
      eye.display(new PVector (x,y));
     
   
  }
 }
    
}//end draw eyes---------------------------------- 




class eyeBall { //build the eyes and get them up onto the stage
 
 color ic;
 float r;
 PVector wc;
  
eyeBall (PVector myCentre, float myRadius) {
  
  ic = (fn);//eye color = file number
  wc = myCentre;
  r = myRadius;
 }
 
 void display(PVector direction) {
   noStroke();
   
   
//--------Whites of the eyes
//   fill (255);
//image (eye, wc.x - 50 , wc.y - 50, r*2, r*2); //whites of the eye
//ellipse (wc.x, wc.y, r*2, r*2); //whites of the eye
//--------
  
   PVector d = direction;
   pushMatrix();
   if (d.dist(wc) < (r/2.5)) {   //changed from r/2 to fix over tracking out of shadow bounds
     translate (d.x, d.y);
   } else {
     translate ((r/2.5)*( (d.x - wc.x)/d.dist(wc)) + wc.x, (r/2.5)*((d.y - wc.y)/d.dist(wc)) + wc.y ); ////changed from r/2 to fix over tracking out of shadow bounds
   }



image(myImageArray[ic],-r*1.25,-r*1.25,r*2.55,r*2.55); //selects ic (eye color) and places the eye in the stage

//---------Iris Color--------    
   
// fill(ic);
// ellipse (0,0, r, r); //eye color
//----------------------------


//----------Pupil------------
//  fill(0);
//  ellipse (0,0, r/2, r/2);
//---------------------------
//----------Reflection--------
//  fill (255, 200);
//  ellipse (r*-0.2, r*-0.2, r*0.3, r*0.3);
//---------
// overlay reflection image
// image(reflection,-250,-250);
   
   popMatrix();

   image (shadow, wc.x - r*1.75, wc.y - r*1.75,  r*3.5, r*3.5);
   image (reflection, wc.x -r*2.0, wc.y -r*2.0, r*3.5,r*3.5);
  
  
//  pushMatrix();
//
//  translate(wc.x,wc.y);
//  rotateX(d.x);
//  rotateY(d.y);
//  shape(globe);
//  popMatrix();
 
 if (debug) { 
  pushMatrix();
 translate(d.x,d.y,0);
sphere(5);
popMatrix();
 }
   
   
 }
}


// looks to see if there's a center of mass for the given user ID, and one that is not on the edge of the frame
PVector centerFor(int userId) {  
  PVector position = new PVector();
  kinect.getCoM(userId, position);
  
  if (position == null)
    return null;
  
  PVector converted = new PVector();
  kinect.convertRealWorldToProjective(position, converted); 
  
  if (converted == null)
    return null;
  
  // don't wait for the Kinect to decide the user isn't coming back - if someone goes off frame, they're out
  if (!(converted.x > 0 && converted.x < width))
    return null;
    
  return converted;
}
// draws a little eye over the target on the debug window
void littleEye(float x, float y) {
  fill(180, 0, 0);
  ellipse(x, y, 15, 15);
  println (x, y);
}
//debugger mode
void keyPressed() {
      if (keyCode == UP)
   debug = !debug; 
}
