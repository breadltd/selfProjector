import shiffman.kinect.*;    // Calls Shiffman's kinect library
import peasy.*;
import org.processing.wiki.triangulate.*;    // Calls the triangulate library

ArrayList triangles = new ArrayList();
ArrayList points = new ArrayList();

PImage img;
PImage depth;
int captureWidth = 640;
int captureHeight = 480;
int thresh = 20;
int step = 48;
int mode = 1;
float lastX = 0;
float lastY = 0;
float lastZ = 0;

float xScale = 2;
float yScale = 1.6;
float zScale = 10;
boolean takeSnap = true;
boolean saveCSV = false;
int CSVctr = 0;

float strokeWeightScale = 15;

PeasyCam cam;

void setup() {
  size(1024,768,P3D);
  cam = new PeasyCam(this, 1280);
  NativeKinect.init();    // initates the Kinect
  img = createImage(captureWidth,captureHeight,RGB);    // create two PImages, captureWidth x captureHeight each in RBG colourspace
  depth = createImage(captureWidth,captureHeight,RGB);

}


void draw() {  
  NativeKinect.update();   // ask the Kinect for the latest frame
  translate(-1280 / 2,-480/2); 
  takeSnap = true;
  if(!takeSnap){
    return;  
  }
  
  
  img.pixels = NativeKinect.getPixels();    // set the PImage called img to the Kinect's output
  img.updatePixels();    // refresh the image so it draws properly
  
  depth.pixels = NativeKinect.getDepthMap();      // set the PImage called depth to the depth map and update it
  depth.updatePixels();
  
  if(saveCSV){
    
    
    String outFileName;
    File fileObj;
    PrintWriter outFile;
    
    do{
      outFileName = dataPath("snap" + str(CSVctr++) +".csv");
      fileObj = new File(outFileName);
    } while(fileObj.exists());
    
    outFile = createWriter(outFileName);
    
    for(int j=0; j<captureHeight; j++){
      for(int i=0; i<captureWidth; i++){
        outFile.println(str(i) +"," + str(j) + ',' + red(depth.get(i,j)));    
      }  
    }
    
    outFile.flush();
    outFile.close();
    
    saveCSV = false;    
  }
  
  background(0);

  switch(mode){    //Setup to call different modes
    
    case 1:    // Basic mode simply plots points
    for(int xx=0; xx<captureWidth; xx+=step){
      for(int yy=0; yy<captureHeight; yy+=step){
        float thisDepth = red(depth.get(xx,yy));
        if(thisDepth >= thresh){    // thresh variable allows you to remove point from the furthest point
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
    }  
  takeSnap = false;
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
