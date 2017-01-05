import javax.swing.JFrame;
import java.awt.*;
import java.lang.Object;
import java.awt.Color;
import SimpleOpenNI.*;
SimpleOpenNI kinect;

// display resolution of the screen (adjust for your own display)
int displayWidth = 1024;
int displayHeight = 768;

// size of Kinect's depth map
int width = 640;
int height = 480;
float kinectX = displayWidth - width;
float kinectY = displayHeight - height;

int timer; //setup a simple timer for capturing kinect frames

//variables for blinking animation
float wavelength = 300; //speed of blink cycle (higher = slower)
float cycle = 0; //blink initialize
float blinkTrigger = 0; //open and close eye
int blinkTimer0; //
int blinkTimer1;
//---------------------------------

//used to determine location and size of eyes on window or wall. 
float targetEyeX = 500; //setup eye target X coord
float targetEyeY = 340; //setup eye target Y coord
float targetEyeR = 100; //setup eye target radius
boolean targetEyeEnable = false; //toggle targetEye setup ellipse


float rx = 0; //randomX
float ry = 0; //randomY
float tx = 0; //definedX
float ty = 0; //definedY
float tr = 0; //temporary radius
int fn = 0; //fileNumber

float backlightX = 340; //backlight for window cling x coordinate
float backlightY = 530; //backlight for window cling y coordinate
float backlightXSize = 347; //backlight for window cling X size default 347x182
float backlightYSize = 182; //backlight for window cling Y size default 347x182
boolean backlightSetupEnable = false; // toggle backlight setup image


boolean helpScreen = false; //display help screen
float osdX = 360; //help menu box X locations
float osdY = 136; //help menu box X locations

boolean debug = false; //debugging mode (shows depth map and target data)
boolean attract = false; //displays random target icon when no targt is obtained
boolean coords = false; //display coordinates
boolean backlightLogo = false; //backlight window cling logo


////set to full screen
boolean sketchFullScreen() {
    return true;
}

// position and user ID of target
PVector target;
int targetId;
//------------

int maxEyes = 5; //number of eyes

ArrayList theEyes;
float x;
float y;
float easing = 0.05; //amount of easing higher =faster lower = slower 0.05 default
PImage backlight, eye, shadow, reflection, dot;

PImage[] myImageArray = new PImage[8];
PFont f;

void setup() {

 

    f = createFont("Arial Bold", 16, true); // Create Font

    frameRate(60);

    blinkTimer0 = millis();

    // gather eye_00?.png files and place them in an array
    for (int i = 0; i < myImageArray.length; i++) {
        myImageArray[i] = loadImage("data/eyes_00" + i + ".png");
    }

    shadow = loadImage("data/EyesShadow.png"); //eyeshadows and mask layer
    reflection = loadImage("data/Reflection.png"); //reflection dots
    dot = loadImage("data/logo.png"); //tracking logo
    backlight = loadImage("data/logobacklight.png"); //tracking logo
    smooth();

    size(displayWidth, displayHeight); //project size = display res

    //---Grab data from Kinect---
    kinect = new SimpleOpenNI(this);
    kinect.enableDepth();
    kinect.enableUser();
    kinect.setMirror(true); // mirror the data
    //-----------------------------

    theEyes = new ArrayList();
    while (theEyes.size() < maxEyes) {
        //Define eyes here (tx=X axis, ty=y axis, tr=radius, fn=eye file number(for alternate eye colors)   
        //0=blue, 1=grey, 2=green, 3=orange, 4=purple, 5=pink, 6=turquoise, 7=yellow
        for (int j = 0; j < (maxEyes); j++) {

            if (j >= 5) {
                fn = (0);
                tx = random(displayWidth);
                ty = random(displayHeight);
                tr = random(20, 25);
            }

            // example of the first 6 eyes listed below if more are needed simply copy and paste and increment a new instance     
            if (j == 5) {
                fn = (1); //eye selection
                tx = (302); //x-position
                ty = (500); //y-position
                tr = (40); //radius

            }
            if (j == 4) {
                fn = (2); //eye selection
                tx = (55); //x-position
                ty = (710); //y-position
                tr = (50); //radius

            }
            if (j == 3) {
                fn = (3); //eye selection
                tx = (960); //x-position
                ty = (55); //y-position
                tr = (50); //radius

            }
            if (j == 2) {
                fn = (4); //eye selection
                tx = (55); //x-position
                ty = (55); //y-position
                tr = (50); //radius

            }
            if (j == 1) {
                fn = (5); //eye selection
                tx = (960); //x-position
                ty = (710); //y-position
                tr = (50); //radius

            }
            if (j == 0) {
                fn = (7); //eye selection
                tx = (500); //x-position
                ty = (340); //y-position
                tr = (100); //radius

            }


            PVector tc = new PVector(tx, ty); //place eyes in locations listed above

            //-=-=-=-

            for (int i = 0; i < theEyes.size(); i++) {
                eyeBall eye = (eyeBall) theEyes.get(i);
            }
            theEyes.add(new eyeBall(tc, tr, j));
        }

    }

}



void draw() {



        //set outside border on fullscreen to black
        setPresentBG(0, 0, 0);

       if (targetEyeEnable || helpScreen){
         blinkTrigger=0;
       }else{
        if (frameCount % 320 == 0)
            blinkTrigger = 1;
        cycle = 0;
        if (millis() > blinkTimer0 + 2500) {
            blinkTimer0 = millis();
            blinkTrigger = 0;
            //println(blinkTimer0);
        }
       }


        background(0);

        // tell the kinect to grab a new image
        kinect.update();

        //fill rx,ry with random coordinates every 5 seconds. Used to radomize the eyes gaze for when target is lost.  
        if (millis() - timer >= 5000) {
            rx = random(displayWidth);
            ry = random(displayHeight);
            timer = millis();
        }


        // enumerate all available targets
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
            for (int i = 0; i < userList.size(); i++) {
                int userId = userList.get(i);

                PVector center = centerFor(userId);

                if (center != null) {
                    target = center;
                    targetId = userId;
                    println("Got target: " + userId);
                }
            }
        }

        if (target != null) //if we'ev got a target
            if (debug) { //and if we are in debugging mode
                PImage depth = kinect.depthImage(); // show the depth image
                image(depth, kinectX, kinectY);
                littleEye(kinectX + target.x, kinectY + target.y); //and put little eyes on it showing the center of the target selected
            } else {
                //---------create transitional easing between x,y locations-----------------------
                float targetX = rx;
                float dx = targetX - x;
                x += dx * easing;

                float targetY = ry;
                float dy = targetY - y;
                y += dy * easing;
                //----end easing---------------
                background(0);


                //---- draw eyes--------------------------------
                for (int i = 0; i < theEyes.size(); i++) {
                    eyeBall eye = (eyeBall) theEyes.get(i);
                    eye.display(new PVector(x, y)); //folow with easing
                }
            }

        if (target == null) {
            //---------create transitional easing between x,y locations-----------------------
            float targetX = rx;
            float dx = targetX - x;
            x += dx * easing;

            float targetY = ry;
            float dy = targetY - y;
            y += dy * easing;
            //----end easing---------------
            background(0);

            for (int i = 0; i < theEyes.size(); i++) {
                eyeBall eye = (eyeBall) theEyes.get(i);

                eye.display(new PVector(x, y));


            }
        }






    } //end draw eyes---------------------------------- 



class eyeBall { //build the eyes and get them up onto the stage

    color ic;
    float r;
    PVector wc;
    float id;
    eyeBall(PVector myCentre, float myRadius, float myIdentity) {

        ic = (fn); //eye color = file number
        wc = myCentre;
        r = myRadius;
        id = myIdentity;
    }

    void display(PVector direction) {
        noStroke();

        PVector d = direction;
        pushMatrix();
        if (d.dist(wc) < (r / 2.5)) { //changed from r/2 to fix over tracking out of shadow bounds
            translate(d.x, d.y);
        } else {
            translate((r / 2.5) * ((d.x - wc.x) / d.dist(wc)) + wc.x, (r / 2.5) * ((d.y - wc.y) / d.dist(wc)) + wc.y); ////changed from r/2 to fix over tracking out of shadow bounds
        }

        image(myImageArray[ic], -r * 1.25, -r * 1.25, r * 2.55, r * 2.55); //selects ic (eye color) and places the eye in the stage
        //blink();
        popMatrix();

        image(shadow, wc.x - r * 1.75, wc.y - r * 1.75, r * 3.5, r * 3.5);
        image(reflection, wc.x - r * 2.0, wc.y - r * 2.0, r * 3.5, r * 3.5);




        //----------eyelid---------
        if (blinkTrigger == 1) {
            pushMatrix();

            stroke(0); //stroke color 0=black 255=white
            strokeWeight(r * 3.5);
            noFill();
            blink();
            ellipse(wc.x, wc.y, r * 1.75 - 20, -r * 1.25 - 20 / cycle / 2); //cycle is the SIN value that closes and opens the ellipse
            noStroke();
            popMatrix();
        }
        //-----end eyelid----------


        //display current coordinates of players in scene 
        //useful to assist in tuning positions on wall or window in reference to physical obstructions
        if (coords) {
            pushMatrix();
            //fill(204,102,0);//orange
            fill(255);
            textFont(f, 16);
            text("X " + wc.x + " : " + "Y" + wc.y, wc.x, wc.y);
            text("Radius:" + r, wc.x, wc.y + 15);
            text("ID: "+id, wc.x, wc.y + 30);
            text("blinkTimer "+blinkTimer0,100,480);
            text("blinkTrigger "+blinkTrigger,100,497);
            text("cycle "+cycle,100,512);
            text("debug "+debug,100,528); 
            text("targetEyeEnable "+targetEyeEnable,100,544);             
            noFill();
            popMatrix();



        }
        
       
    

       
        //------------------------------------

        if (attract) { //place dot or logo on the screen to show the random point the eyes are looking at
            pushMatrix();

            //---------create transitional easing between x,y locations-----------------------
            float targetX = rx;
            float dx = targetX - x;
            x += dx * easing;

            float targetY = ry;
            float dy = targetY - y;
            y += dy * easing;
            //----end easing---------------
            image(dot, x, y, 200, 104);

            if (coords) { //show coords above dot/logo
                textFont(f, 12);
                textAlign(LEFT);
                fill(204, 102, 0);
                rect(x - 5, y + 2, 195, -15);
                fill(255);
                text("X " + rx + " : " + "Y" + ry, x, y);
                textAlign(CENTER);
                noFill();
            }
            //println(rx, ry);
            
            popMatrix();
        }
    if (backlightLogo){
      image(backlight,backlightX,backlightY,backlightXSize,backlightYSize);
      
       if (backlightSetupEnable){
     textAlign(CENTER);
    fill(255); 
    text("X: "+backlightX +" Y: "+backlightY+ " W: "+backlightXSize+" H: "+backlightYSize, backlightX, backlightY); 
    noFill();
   }
      
   
   }
  if (targetEyeEnable){
     stroke(255);
     ellipse (targetEyeX,targetEyeY,targetEyeR*1.75,targetEyeR*1.75);
     fill(255);
     textFont(f, 12);
     textAlign(CENTER);
     text("X: "+targetEyeX+" Y: "+targetEyeY+"\n"+"R: "+targetEyeR,targetEyeX,targetEyeY);   
     fill(204,102,0,95);
     noStroke(); 
    
    stroke(255);
    strokeWeight(4);
     line(1, 1, displayWidth, 1);
     line(1, 1, 1, displayHeight);
     line(1, displayHeight -1,displayWidth ,displayHeight-1);
     line(displayWidth-1, 1, displayWidth-1, displayHeight-1);
   noStroke();
     
}
        if (helpScreen){
          blinkTrigger = 0;
          stroke(255);
          fill(0); 
          //rect(95, 200, 360, 136);
          rect(osdX, osdY, 360,136);
          
          noStroke();    
    fill(255);
          textFont(f, 12);
          textAlign(LEFT);
          text("HELP MENU\nA - Attract Mode  (show logo at random coordinates)\nB - Backlight (enable window cling backlight)\nC - Coords (show current coordinates and radius)\nD - Debug Kinect (display depth map when target is detected\nS - Setup Backlight (8,2,4,6=X/Y size) Arrows for positioning\nT - Target Enable (+/- = change radius) Arrows for positioning",osdX+5,osdY + 16);
          textAlign(CENTER);
   noFill();

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

        // don't wait for the Kinect to decide the user isn't coming back - if someone goes off frame, they're out.
        if (!(converted.x > 0 && converted.x < width))
            return null;

        return converted;
    }
    // draws a little eye over the target on the debug window
void littleEye(float x, float y) {
    fill(180, 0, 0);
    ellipse(x, y, 15, 15);
    println(x, y);
}


//debugger mode
void keyPressed() {
    if (key == 'd' || key == 'D')
        debug = !debug;
    if (key == 'a' || key == 'A')
        attract = !attract;
    if (key == 'c' || key == 'C')
        coords = !coords;
     if (key == 'b' || key =='B')
        backlightLogo = !backlightLogo;   
     if (key == 't'|| key == 'T')
        targetEyeEnable = !targetEyeEnable;   
     if (key == 's'|| key== 'S')
        backlightSetupEnable = !backlightSetupEnable; 
    if (keyCode == 112)
        helpScreen = !helpScreen;

//targetEye adjustment section
if (targetEyeEnable){
    if (key == '+'|| key == '=')
      targetEyeR = targetEyeR + 1;
    if (key == '-')
      targetEyeR = targetEyeR -1; 
    if (keyCode == LEFT)
      targetEyeX = targetEyeX -1;
    if (keyCode == RIGHT)
      targetEyeX = targetEyeX +1; 
    if (keyCode == UP)
      targetEyeY = targetEyeY -1;
    if (keyCode == DOWN)
      targetEyeY = targetEyeY +1;  
}else{
if (backlightSetupEnable){
     if (key == '2')
      backlightYSize = backlightYSize + 1;
     if (key == '8')
      backlightYSize = backlightYSize - 1;  
      if (key == '6')
      backlightXSize = backlightXSize + 1;
     if (key == '4')
      backlightXSize = backlightXSize - 1;   
        
    if (keyCode == LEFT)
      backlightX = backlightX -1;
   
    if (keyCode == RIGHT)
      backlightX = backlightX +1; 
   
    if (keyCode == UP)
      backlightY = backlightY -1;
    if (keyCode == DOWN)
     backlightY = backlightY +1; 
 }
 }
}

void blink() {
    //for (int i=0; i < (blinkValue); i++){


    float value = (sin(millis() / wavelength) + 1) / 2;
    cycle = value;


}

void setPresentBG(int r, int g, int b) {
    ((JFrame) frame).getContentPane().setBackground(new Color(r, g, b));
}

float x;
float y;
float easing = 0.05; //amount of easing higher =faster lower = slower 0.05 default
PImage mask, eye, shadow, reflection, dot;

PImage[] myImageArray = new PImage[8];
PFont f;

void setup() {



    f = createFont("Arial", 16, true); // Create Font

    frameRate(60);

    blinkTimer0 = millis();

    // gather eye_00?.png files and place them in an array
    for (int i = 0; i < myImageArray.length; i++) {
        myImageArray[i] = loadImage("data/eyes_00" + i + ".png");
    }

    shadow = loadImage("data/EyesShadow.png"); //eyeshadows and mask layer
    reflection = loadImage("data/Reflection.png"); //reflection dots
    dot = loadImage("data/logo.png"); //tracking logo

    smooth();

    size(displayWidth, displayHeight); //project size = display res

    //---Grab data from Kinect---
    kinect = new SimpleOpenNI(this);
    kinect.enableDepth();
    kinect.enableUser();
    kinect.setMirror(true); // mirror the data
    //-----------------------------

    theEyes = new ArrayList();
    while (theEyes.size() < maxEyes) {
        //Define eyes here (tx=X axis, ty=y axis, tr=radius, fn=eye file number(for alternate eye colors)   
        //0=blue, 1=grey, 2=green, 3=orange, 4=purple, 5=pink, 6=turquoise, 7=yellow
        for (int j = 0; j < (maxEyes); j++) {

            if (j >= 5) {
                fn = (0);
                tx = random(displayWidth);
                ty = random(displayHeight);
                tr = random(20, 25);
            }

            // example of the first 6 eyes listed below if more are needed simply copy and paste and increment a new instance     
            if (j == 5) {
                fn = (1); //eye selection
                tx = (302); //x-position
                ty = (500); //y-position
                tr = (40); //radius

            }
            if (j == 4) {
                fn = (2); //eye selection
                tx = (320); //x-position
                ty = (80); //y-position
                tr = (50); //radius

            }
            if (j == 3) {
                fn = (3); //eye selection
                tx = (100); //x-position
                ty = (100); //y-position
                tr = (60); //radius

            }
            if (j == 2) {
                fn = (4); //eye selection
                tx = (850); //x-position
                ty = (70); //y-position
                tr = (70); //radius

            }
            if (j == 1) {
                fn = (5); //eye selection
                tx = (800); //x-position
                ty = (340); //y-position
                tr = (80); //radius

            }
            if (j == 0) {
                fn = (7); //eye selection
                tx = (500); //x-position
                ty = (340); //y-position
                tr = (100); //radius

            }


            PVector tc = new PVector(tx, ty); //place eyes in locations listed above

            //-=-=-=-

            for (int i = 0; i < theEyes.size(); i++) {
                eyeBall eye = (eyeBall) theEyes.get(i);
            }
            theEyes.add(new eyeBall(tc, tr, j));
        }

    }

}



void draw() {



        //set outside border on fullscreen to black
        setPresentBG(0, 0, 0);

        if (frameCount % 320 == 0)
            blinkTrigger = 1;
        cycle = 0;
        if (millis() > blinkTimer0 + 2500) {
            blinkTimer0 = millis();
            blinkTrigger = 0;
            //println(blinkTimer0);
        }



        background(0);

        // tell the kinect to grab a new image
        kinect.update();

        //fill rx,ry with random coordinates every 5 seconds. Used to radomize the eyes gaze for when target is lost.  
        if (millis() - timer >= 5000) {
            rx = random(displayWidth);
            ry = random(displayHeight);
            timer = millis();
        }


        // enumerate all available targets
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
            for (int i = 0; i < userList.size(); i++) {
                int userId = userList.get(i);

                PVector center = centerFor(userId);

                if (center != null) {
                    target = center;
                    targetId = userId;
                    println("Got target: " + userId);
                }
            }
        }

        if (target != null) //if we'ev got a target
            if (debug) { //and if we are in debugging mode
                PImage depth = kinect.depthImage(); // show the depth image
                image(depth, kinectX, kinectY);
                littleEye(kinectX + target.x, kinectY + target.y); //and put little eyes on it showing the center of the target selected
            } else {
                //---------create transitional easing between x,y locations-----------------------
                float targetX = rx;
                float dx = targetX - x;
                x += dx * easing;

                float targetY = ry;
                float dy = targetY - y;
                y += dy * easing;
                //----end easing---------------
                background(0);


                //---- draw eyes--------------------------------
                for (int i = 0; i < theEyes.size(); i++) {
                    eyeBall eye = (eyeBall) theEyes.get(i);
                    eye.display(new PVector(x, y)); //folow with easing
                }
            }

        if (target == null) {
            //---------create transitional easing between x,y locations-----------------------
            float targetX = rx;
            float dx = targetX - x;
            x += dx * easing;

            float targetY = ry;
            float dy = targetY - y;
            y += dy * easing;
            //----end easing---------------
            background(0);

            for (int i = 0; i < theEyes.size(); i++) {
                eyeBall eye = (eyeBall) theEyes.get(i);

                eye.display(new PVector(x, y));


            }
        }

    } //end draw eyes---------------------------------- 




class eyeBall { //build the eyes and get them up onto the stage

    color ic;
    float r;
    PVector wc;
    float id;
    eyeBall(PVector myCentre, float myRadius, float myIdentity) {

        ic = (fn); //eye color = file number
        wc = myCentre;
        r = myRadius;
        id = myIdentity;
    }

    void display(PVector direction) {
        noStroke();

        PVector d = direction;
        pushMatrix();
        if (d.dist(wc) < (r / 2.5)) { //changed from r/2 to fix over tracking out of shadow bounds
            translate(d.x, d.y);
        } else {
            translate((r / 2.5) * ((d.x - wc.x) / d.dist(wc)) + wc.x, (r / 2.5) * ((d.y - wc.y) / d.dist(wc)) + wc.y); ////changed from r/2 to fix over tracking out of shadow bounds
        }

        image(myImageArray[ic], -r * 1.25, -r * 1.25, r * 2.55, r * 2.55); //selects ic (eye color) and places the eye in the stage
        blink();
        popMatrix();

        image(shadow, wc.x - r * 1.75, wc.y - r * 1.75, r * 3.5, r * 3.5);
        image(reflection, wc.x - r * 2.0, wc.y - r * 2.0, r * 3.5, r * 3.5);




        //----------eyelid---------
        if (blinkTrigger == 1) {
            pushMatrix();

            stroke(0); //stroke color 0=black 255=white
            strokeWeight(r * 3.5);
            noFill();
            blink();
            ellipse(wc.x, wc.y, r * 1.75 - 20, -r * 1.25 - 20 / cycle / 2); //cycle is the SIN value that closes and opens the ellipse
            noStroke();
            popMatrix();
        }
        //-----end eyelid----------


        //display current coordinates of players in scene 
        //useful to assist in tuning positions on wall or window in reference to physical obstructions
        if (coords) {
            pushMatrix();
            textFont(f, 16);
            fill(204, 102, 0);
            rect(wc.x - 5, wc.y + 2, 130, -15);
            fill(255);
            text("X " + wc.x + " : " + "Y" + wc.y, wc.x, wc.y);
            fill(204, 102, 0);
            rect(wc.x - 5, wc.y + 18, 130, -16);
            fill(255);
            text("Radius:" + r, wc.x, wc.y + 15);
            fill(204, 102, 0);
            rect(wc.x - 5, wc.y + 32, 130, -16);
            fill(255);
            text("ID: "+id, wc.x, wc.y + 30);
            noFill();
            popMatrix();



        }
        //------------------------------------

        if (attract) { //place dot or logo on the screen to show the random point the eyes are looking at
            pushMatrix();

            //---------create transitional easing between x,y locations-----------------------
            float targetX = rx;
            float dx = targetX - x;
            x += dx * easing;

            float targetY = ry;
            float dy = targetY - y;
            y += dy * easing;
            //----end easing---------------
            image(dot, x, y, 200, 104);

            if (coords) { //show coords above dot/logo
                textFont(f, 16);
                fill(204, 102, 0);
                rect(x - 5, y + 2, 195, -15);
                fill(255);
                text("X " + rx + " : " + "Y" + ry, x, y);
                noFill();
            }
            //println(rx, ry);
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

        // don't wait for the Kinect to decide the user isn't coming back - if someone goes off frame, they're out.
        if (!(converted.x > 0 && converted.x < width))
            return null;

        return converted;
    }
    // draws a little eye over the target on the debug window
void littleEye(float x, float y) {
    fill(180, 0, 0);
    ellipse(x, y, 15, 15);
    println(x, y);
}


//debugger mode
void keyPressed() {
    if (keyCode == UP)
        debug = !debug;
    if (keyCode == DOWN)
        attract = !attract;
    if (keyCode == LEFT)
        coords = !coords;
}

void blink() {
    //for (int i=0; i < (blinkValue); i++){


    float value = (sin(millis() / wavelength) + 1) / 2;
    cycle = value;


}

void setPresentBG(int r, int g, int b) {
    ((JFrame) frame).getContentPane().setBackground(new Color(r, g, b));
}
float x;
float y;
float easing = 0.05; //amount of easing higher =faster lower = slower 0.05 default
PImage mask, eye, shadow, reflection, dot;

PImage[] myImageArray = new PImage[8];
PFont f;

void setup() {



    f = createFont("Arial", 16, true); // Create Font

    frameRate(60);

    blinkTimer0 = millis();

    // gather eye_00?.png files and place them in an array
    for (int i = 0; i < myImageArray.length; i++) {
        myImageArray[i] = loadImage("data/eyes_00" + i + ".png");
    }

    shadow = loadImage("data/EyesShadow.png"); //eyeshadows and mask layer
    reflection = loadImage("data/Reflection.png"); //reflection dots
    dot = loadImage("data/dot.png"); //tracking logo

    smooth();

    size(displayWidth, displayHeight); //project size = display res

    //---Grab data from Kinect---
    kinect = new SimpleOpenNI(this);
    kinect.enableDepth();
    kinect.enableUser();
    kinect.setMirror(true); // mirror the data
    //-----------------------------

    theEyes = new ArrayList();
    while (theEyes.size() < maxEyes) {
        //Define eyes here (tx=X axis, ty=y axis, tr=radius, fn=eye file number(for alternate eye colors)   
        //0=blue, 1=grey, 2=green, 3=orange, 4=purple, 5=pink, 6=turquoise, 7=yellow
        for (int j = 0; j < (maxEyes); j++) {

            if (j >= 5) {
                fn = (0);
                tx = random(displayWidth);
                ty = random(displayHeight);
                tr = random(20, 25);
            }

            // example of the first 6 eyes listed below if more are needed simply copy and paste and increment a new instance     
            if (j == 5) {
                fn = (1); //eye selection
                tx = (302); //x-position
                ty = (500); //y-position
                tr = (40); //radius

            }
            if (j == 4) {
                fn = (2); //eye selection
                tx = (320); //x-position
                ty = (80); //y-position
                tr = (50); //radius

            }
            if (j == 3) {
                fn = (3); //eye selection
                tx = (100); //x-position
                ty = (100); //y-position
                tr = (60); //radius

            }
            if (j == 2) {
                fn = (4); //eye selection
                tx = (850); //x-position
                ty = (70); //y-position
                tr = (70); //radius

            }
            if (j == 1) {
                fn = (5); //eye selection
                tx = (800); //x-position
                ty = (340); //y-position
                tr = (80); //radius

            }
            if (j == 0) {
                fn = (7); //eye selection
                tx = (500); //x-position
                ty = (340); //y-position
                tr = (90); //radius

            }


            PVector tc = new PVector(tx, ty); //place eyes in locations listed above

            //-=-=-=-

            for (int i = 0; i < theEyes.size(); i++) {
                eyeBall eye = (eyeBall) theEyes.get(i);
            }
            theEyes.add(new eyeBall(tc, tr));
        }

    }

}



void draw() {



        //set outside border on fullscreen to black
        setPresentBG(0, 0, 0);

        if (frameCount % 320 == 0)
            blinkTrigger = 1;
        cycle = 0;
        if (millis() > blinkTimer0 + 2500) {
            blinkTimer0 = millis();
            blinkTrigger = 0;
            //println(blinkTimer0);
        }



        background(0);

        // tell the kinect to grab a new image
        kinect.update();

        //fill rx,ry with random coordinates every 5 seconds. Used to radomize the eyes gaze for when target is lost.  
        if (millis() - timer >= 5000) {
            rx = random(displayWidth);
            ry = random(displayHeight);
            timer = millis();
        }


        // enumerate all available targets
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
            for (int i = 0; i < userList.size(); i++) {
                int userId = userList.get(i);

                PVector center = centerFor(userId);

                if (center != null) {
                    target = center;
                    targetId = userId;
                    println("Got target: " + userId);
                }
            }
        }

        if (target != null) //if we'ev got a target
            if (debug) { //and if we are in debugging mode
                PImage depth = kinect.depthImage(); // show the depth image
                image(depth, kinectX, kinectY);
                littleEye(kinectX + target.x, kinectY + target.y); //and put little eyes on it showing the center of the target selected
            } else {
                //---------create transitional easing between x,y locations-----------------------
                float targetX = rx;
                float dx = targetX - x;
                x += dx * easing;

                float targetY = ry;
                float dy = targetY - y;
                y += dy * easing;
                //----end easing---------------
                background(0);


                //---- draw eyes--------------------------------
                for (int i = 0; i < theEyes.size(); i++) {
                    eyeBall eye = (eyeBall) theEyes.get(i);
                    eye.display(new PVector(x, y)); //folow with easing
                }
            }

        if (target == null) {
            //---------create transitional easing between x,y locations-----------------------
            float targetX = rx;
            float dx = targetX - x;
            x += dx * easing;

            float targetY = ry;
            float dy = targetY - y;
            y += dy * easing;
            //----end easing---------------
            background(0);

            for (int i = 0; i < theEyes.size(); i++) {
                eyeBall eye = (eyeBall) theEyes.get(i);

                eye.display(new PVector(x, y));


            }
        }

    } //end draw eyes---------------------------------- 




class eyeBall { //build the eyes and get them up onto the stage

    color ic;
    float r;
    PVector wc;

    eyeBall(PVector myCentre, float myRadius) {

        ic = (fn); //eye color = file number
        wc = myCentre;
        r = myRadius;
    }

    void display(PVector direction) {
        noStroke();

        PVector d = direction;
        pushMatrix();
        if (d.dist(wc) < (r / 2.5)) { //changed from r/2 to fix over tracking out of shadow bounds
            translate(d.x, d.y);
        } else {
            translate((r / 2.5) * ((d.x - wc.x) / d.dist(wc)) + wc.x, (r / 2.5) * ((d.y - wc.y) / d.dist(wc)) + wc.y); ////changed from r/2 to fix over tracking out of shadow bounds
        }

        image(myImageArray[ic], -r * 1.25, -r * 1.25, r * 2.55, r * 2.55); //selects ic (eye color) and places the eye in the stage
        blink();
        popMatrix();

        image(shadow, wc.x - r * 1.75, wc.y - r * 1.75, r * 3.5, r * 3.5);
        image(reflection, wc.x - r * 2.0, wc.y - r * 2.0, r * 3.5, r * 3.5);




        //----------eyelid---------
        if (blinkTrigger == 1) {
            pushMatrix();

            stroke(0); //stroke color 0=black 255=white
            strokeWeight(r * 3.5);
            noFill();
            blink();
            ellipse(wc.x, wc.y, r * 1.75 - 20, -r * 1.25 - 20 / cycle / 2); //cycle is the SIN value that closes and opens the ellipse
            noStroke();
            popMatrix();
        }
        //-----end eyelid----------


        //display current coordinates of players in scene 
        //useful to assist in tuning positions on wall or window in reference to physical obstructions
        if (coords) {
            pushMatrix();
            textFont(f, 16);
            fill(204, 102, 0);
            rect(wc.x - 5, wc.y + 2, 130, -15);
            fill(255);
            text("X " + wc.x + " : " + "Y" + wc.y, wc.x, wc.y);
            fill(204, 102, 0);
            rect(wc.x - 5, wc.y + 18, 130, -16);
            fill(255);
            text("Radius : " + r, wc.x, wc.y + 16);
            noFill();
            popMatrix();



        }
        //------------------------------------

        if (attract) { //place dot or logo on the screen to show the random point the eyes are looking at
            pushMatrix();

            //---------create transitional easing between x,y locations-----------------------
            float targetX = rx;
            float dx = targetX - x;
            x += dx * easing;

            float targetY = ry;
            float dy = targetY - y;
            y += dy * easing;
            //----end easing---------------
            image(dot, x, y, 200, 104);

            if (coords) { //show coords above dot/logo
                textFont(f, 16);
                fill(204, 102, 0);
                rect(x - 5, y + 2, 195, -15);
                fill(255);
                text("X " + rx + " : " + "Y" + ry, x, y);
                noFill();
            }
            //println(rx, ry);
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
    println(x, y);
}


//debugger mode
void keyPressed() {
    if (keyCode == UP)
        debug = !debug;
    if (keyCode == DOWN)
        attract = !attract;
    if (keyCode == LEFT)
        coords = !coords;
}

void blink() {
    //for (int i=0; i < (blinkValue); i++){


    float value = (sin(millis() / wavelength) + 1) / 2;
    cycle = value;


}

void setPresentBG(int r, int g, int b) {
    ((JFrame) frame).getContentPane().setBackground(new Color(r, g, b));
}
float x;
float y;
float easing = 0.05; //amount of easing higher =faster lower = slower 0.05 default
PImage mask, eye, shadow, reflection, dot;

PImage[] myImageArray = new PImage[8];


void setup() {

    frameRate(60);

    blinkTimer0 = millis();

    // gather eye_00?.png files and place them in an array
    for (int i = 0; i < myImageArray.length; i++) {
        myImageArray[i] = loadImage("data/eyes_00" + i + ".png");
    }

    shadow = loadImage("data/EyesShadow.png"); //eyeshadows and mask layer
    reflection = loadImage("data/Reflection.png"); //reflection dots
    dot = loadImage("data/logo.png"); //tracking dot
    smooth();

    size(displayWidth, displayHeight); //project size = display res

    //---Grab data from Kinect---
    kinect = new SimpleOpenNI(this);
    kinect.enableDepth();
    kinect.enableUser();
    kinect.setMirror(true); // mirror the data
    //-----------------------------

    theEyes = new ArrayList();
    while (theEyes.size() < maxEyes) {
        //Define eyes here (tx=X axis, ty=y axis, tr=radius, fn=eye file number(for alternate eye colors)   
        //0=blue, 1=grey, 2=green, 3=orange, 4=purple, 5=pink, 6=turquoise, 7=yellow
        for (int j = 0; j < (maxEyes); j++) {

            // example of the first 6 eyes listed below if more are needed simply copy and paste and increment a new instance     
            if (j == 5) {
                fn = (1); //eye selection
                tx = (302); //x-position
                ty = (500); //y-position
                tr = (40); //radius

            }
            if (j == 4) {
                fn = (2); //eye selection
                tx = (320); //x-position
                ty = (80); //y-position
                tr = (30); //radius

            }
            if (j == 3) {
                fn = (3); //eye selection
                tx = (620); //x-position
                ty = (340); //y-position
                tr = (40); //radius

            }
            if (j == 2) {
                fn = (4); //eye selection
                tx = (50); //x-position
                ty = (70); //y-position
                tr = (50); //radius

            }
            if (j == 1) {
                fn = (5); //eye selection
                tx = (120); //x-position
                ty = (340); //y-position
                tr = (60); //radius

            }
            if (j == 0) {
                fn = (7); //eye selection
                tx = (430); //x-position
                ty = (356); //y-position
                tr = (90); //radius

            }


            PVector tc = new PVector(tx, ty); //place eyes in locations listed above

            //-=-=-=-

            for (int i = 0; i < theEyes.size(); i++) {
                eyeBall eye = (eyeBall) theEyes.get(i);
            }
            theEyes.add(new eyeBall(tc, tr));
        }

    }

}



void draw() {

        //set outside border on fullscreen to black
        setPresentBG(0, 0, 0);

        if (frameCount % 320 == 0)
            blinkTrigger = 1;
        cycle = 0;
        if (millis() > blinkTimer0 + 2500) {
            blinkTimer0 = millis();
            blinkTrigger = 0;
            //println(blinkTimer0);
        }



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
            for (int i = 0; i < userList.size(); i++) {
                int userId = userList.get(i);

                PVector center = centerFor(userId);

                if (center != null) {
                    target = center;
                    targetId = userId;
                    println("Got target: " + userId);
                }
            }
        }

        if (target != null) //if we'ev got a target
            if (debug) { //and if we are in debugging mode
                PImage depth = kinect.depthImage(); // show the depth image
                image(depth, kinectX, kinectY);
                littleEye(kinectX + target.x, kinectY + target.y); //and put little eyes on i
            } else {
                //---------create transitional easing between x,y locations-----------------------
                float targetX = rx;
                float dx = targetX - x;
                x += dx * easing;

                float targetY = ry;
                float dy = targetY - y;
                y += dy * easing;
                //----end easing---------------
                background(0, 0, 1);


                //---- draw eyes--------------------------------

                for (int i = 0; i < theEyes.size(); i++) {
                    eyeBall eye = (eyeBall) theEyes.get(i);
                    eye.display(new PVector(x, y)); //folow with easing
                }
            }

        if (target == null) {
            //---------create transitional easing between x,y locations-----------------------
            float targetX = rx;
            float dx = targetX - x;
            x += dx * easing;

            float targetY = ry;
            float dy = targetY - y;
            y += dy * easing;
            //----end easing---------------
            background(0, 0, 0);

            for (int i = 0; i < theEyes.size(); i++) {
                eyeBall eye = (eyeBall) theEyes.get(i);

                eye.display(new PVector(x, y));


            }
        }

    } //end draw eyes---------------------------------- 




class eyeBall { //build the eyes and get them up onto the stage

    color ic;
    float r;
    PVector wc;

    eyeBall(PVector myCentre, float myRadius) {

        ic = (fn); //eye color = file number
        wc = myCentre;
        r = myRadius;
    }

    void display(PVector direction) {
        noStroke();

        PVector d = direction;
        pushMatrix();
        if (d.dist(wc) < (r / 2.5)) { //changed from r/2 to fix over tracking out of shadow bounds
            translate(d.x, d.y);
        } else {
            translate((r / 2.5) * ((d.x - wc.x) / d.dist(wc)) + wc.x, (r / 2.5) * ((d.y - wc.y) / d.dist(wc)) + wc.y); ////changed from r/2 to fix over tracking out of shadow bounds
        }

        image(myImageArray[ic], -r * 1.25, -r * 1.25, r * 2.55, r * 2.55); //selects ic (eye color) and places the eye in the stage
        blink();
        popMatrix();

        image(shadow, wc.x - r * 1.75, wc.y - r * 1.75, r * 3.5, r * 3.5);
        image(reflection, wc.x - r * 2.0, wc.y - r * 2.0, r * 3.5, r * 3.5);


        //----------eyelid---------
        if (blinkTrigger == 1) {
            pushMatrix();

            stroke(0); //stroke color 0=black 255=white
            strokeWeight(r * 3.5);
            noFill();
            blink();
            ellipse(wc.x, wc.y, r * 2 - 20, -r * 1.25 - 20 / cycle / 2); //cycle is the SIN value that closes and opens the ellipse
            noStroke();
            popMatrix();
        }
        //-----end eyelid----------

        if (attract) { //place dot or logo on the screen to show the random point the eyes are looking at
            pushMatrix();

            //---------create transitional easing between x,y locations-----------------------
            float targetX = rx;
            float dx = targetX - x;
            x += dx * easing;

            float targetY = ry;
            float dy = targetY - y;
            y += dy * easing;
            //----end easing---------------
            image(dot, x, y, 100, 52);
            println(rx, ry);
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
    println(x, y);
}


//debugger mode
void keyPressed() {
    if (keyCode == UP)
        debug = !debug;
    if (keyCode == DOWN)
        attract = !attract;
}

void blink() {
    //for (int i=0; i < (blinkValue); i++){


    float value = (sin(millis() / wavelength) + 1) / 2;
    cycle = value;
    //cycle = blinkValue;


}

void setPresentBG(int r, int g, int b) {
    ((JFrame) frame).getContentPane().setBackground(new Color(r, g, b));
}
  
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
