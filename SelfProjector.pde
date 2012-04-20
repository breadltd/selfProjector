/****************************************************************************

  BREAD ltd. Self Projector
  
  Stefan Dzisiewski-Smith and Sarat Babu
  
  December 2010

*****************************************************************************

  This isn't pretty code, nor is it efficient. It was a quick dash to get
  something on screen to play with. Hopefully, you can do some fun stuff 
  with it however.
  
  It doesn't fully utilise all the resolution of the depth image, if memory
  serves. If you want that, pop it in and request a pull - we'll happily add
  the code. 
  
  The video Sarat made using this can be found at http://vimeo.com/17821576

*****************************************************************************

  Keyboard commands:
  
  1..4     sets mode
  a        increases threshold
  z        decreases threshold
  x        increases stroke weight
  s        decreases stroke weight
  c        increases drawn resolution
  d        decreases drawn resolution
  [space]  saves a .csv snapshot to /data/snapXXXX.csv

****************************************************************************/

// the libraries that do all the heavy lifting
import shiffman.kinect.*;    
import peasy.*;
import org.processing.wiki.triangulate.*;    

// 3d object arrays
ArrayList triangles = new ArrayList();
ArrayList points = new ArrayList();

// depth and visible images
PImage img;
PImage depth;

// size constants for the Kinect's camera
final int captureWidth = 640;
final int captureHeight = 480;

// global operation variables 
int thresh = 20;
int step = 48;
int mode = 1;

// dimensional scales to give a visually pleasing output
float xScale = 2;
float yScale = 1.6;
float zScale = 10;
float strokeWeightScale = 15;

// save-to-csv variables
boolean saveCSV = false;
int CSVctr = 0;

PeasyCam cam;

void setup() {
  
  // setup for 3D
  size(1024,768,P3D);
  
  // init the peasyCam and Kinect
  cam = new PeasyCam(this, 1280);
  NativeKinect.init(); 
  
  // initialise the images for the depth and visible
  img = createImage(captureWidth,captureHeight,RGB);    
  depth = createImage(captureWidth,captureHeight,RGB);

}


void draw() {  
  
  // ask the Kinect for the latest frame
  NativeKinect.update();   
  
  // translate to around the centre for drawing
  translate(-1280 / 2,-480/2); 
  
  
  img.pixels = NativeKinect.getPixels(); // visible light
  img.updatePixels();    // update the image so its data is valid
  
  depth.pixels = NativeKinect.getDepthMap(); // depth
  depth.updatePixels();  // update the image so its data is valid
  
  // CSV output code
  if(saveCSV){
    
    String outFileName;
    File fileObj;
    PrintWriter outFile;
    
    // find a sequential filename that doesn't already exist to write to
    do{
      outFileName = dataPath("snap" + nf(CSVctr++,4) +".csv");
      fileObj = new File(outFileName);
    } while(fileObj.exists());
    
    // when we've found one, create a handle to it
    outFile = createWriter(outFileName);
    
    // iterate through the depth image and write a scaled output triplet
    for(int j=0; j<captureHeight; j++){
      for(int i=0; i<captureWidth; i++){
        outFile.println(str((float)i*xScale) +"," + str((float)j*yScale) + ',' + str(zScale*red(depth.get(i,j))));    
      }  
    }
    
    // flush the changes and close the file
    outFile.flush();
    outFile.close();
    
    // reset the save flag
    saveCSV = false;    
  }
  
  // black background - we're designers
  background(0);

  switch(mode){    
    
    case 1:    // Basic mode simply plots points
    for(int xx=0; xx<captureWidth; xx+=step){
      for(int yy=0; yy<captureHeight; yy+=step){
        float thisDepth = red(depth.get(xx,yy));
        if(thisDepth >= thresh){    // only draw points closer than the threshold level
            stroke(255,255,255);
            strokeWeight(2);
            point(xx*xScale, yy*yScale, thisDepth*zScale);    // additional scale factors required to space out the points from the kinect
        }
      }  
    }
    break;

    case 2:    // Second mode, uses HSB mode to allow colour to signify depth, additionally stroke size is affected by depth
      for(int xx=0; xx<captureWidth; xx+=step){
      for(int yy=0; yy<captureHeight; yy+=step){
        float thisDepth = red(depth.get(xx,yy));
        if(thisDepth >= thresh){
            colorMode(HSB);    //  Hue saturation brightness rather than rgb
            stroke(255-thisDepth,255,100);
            strokeWeight((thisDepth)/strokeWeightScale);
            point(xx*xScale, yy*yScale, thisDepth*zScale);
            colorMode(RGB);    // Resets colourmode
          }
        }  
      }
      break;
      
    case 3: // Third mode, based on triangulation library
      points.clear();
      for(int xx=0; xx<captureWidth; xx+=step){
      for(int yy=0; yy<captureHeight; yy+=step){
        float thisDepth = red(depth.get(xx,yy));
        if(thisDepth >= thresh){
            points.add(new PVector(xx*xScale, yy*yScale, thisDepth*zScale));  //Adds points as pvectors to points array rather than plotting
            }
          }
        }
      for (int i = 0; i < points.size(); i++) {
        PVector p = (PVector)points.get(i);
      }
  

      triangles = Triangulate.triangulate(points);    // get the triangulated mesh
      stroke(250, 250, 250, 40);
      strokeWeight(1);
      noFill();
      
      beginShape(TRIANGLES);          // draw the mesh of triangles
 
        for (int i = 0; i < triangles.size(); i++) {
          Triangle t = (Triangle)triangles.get(i);
          vertex(t.p1.x, t.p1.y, t.p1.z);
          vertex(t.p2.x, t.p2.y, t.p2.z);
          vertex(t.p3.x, t.p3.y, t.p3.z);
        }
  
      endShape();
      break;
      
    default:
    
      // invalid mode selected, but don't whinge about it...
    
      break;
    }  

}

void keyPressed(){    // Key commands for live adaption of the programm
  switch(key){        
  case 'a':    //Increase threshold value (increase depth clipping)
    if(++thresh>255){
      thresh = 255;
    }
    break;
  case 'z':    //Reduce threshold value (reduce depth clipping)
    if(--thresh<0){
      thresh = 0;
    }
    break;
  case 'x':    //Increase stroke weight
    if(++strokeWeightScale>255){
      strokeWeightScale = 255;
    }  
    break;
  case 's':    //Decrease stroke weight
    if(--strokeWeightScale<1){
      strokeWeightScale = 1;
    }  
    break;  
  case 'c':    //Decreases data step interval (increases resolution of data)
    if(--step<2){
      step = 2;
    }  
    break;     
  case 'd':    //Increase data step interval (decreases resolution of data)
    if(++step>120){
      step = 120;
    }  
    break;  
  case ' ':
    saveCSV = true; 
    break;  
  case '0':
  case '1':
  case '2':
  case '3':
  case '4':
  case '5':
  case '6':
  case '7':
  case '8':
  case '9':
    mode = key-'0';  //assigns mode
    break;
  }
}
