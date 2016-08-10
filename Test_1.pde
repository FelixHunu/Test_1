import processing.serial.*;
import interfascia.*;

Serial myPort;
int maxLengthOfData = 65;
int canMatrixSize = 22;

String incommingID;
String[] dataElements = new String[maxLengthOfData];

//Defining the can signal as a class
class CanSignal{
    private String id;
    private int[] bytePos;
    private String sigType;
    private int bitPos;
    private String description;
    private String unit;
    private String varName;
    private int factor;
    private int rangeLow;
    private int rangeHigh;
    private String[] elements;

  public CanSignal(String parsedLine){
    
    println("Class definition started");
    
    
    //Split according to csv separator
    this.elements = parsedLine.split(";");
    
    //printArray(elements);
    //Load Can message ID
    this.id=elements[0];
    
    //Load byte position
    String[] bytesPos = elements[1].split(" - ");
    //printArray(bytesPos);
    //this.bytePos[0] = int(bytesPos[0]); 
    //if (bytesPos[1]!=null)
    //    this.bytePos[1] = int(bytesPos[1]); 
    
    //Load bit position 
    if (elements[2]!="-")
        this.bitPos = int(elements[2]);
   
    //Load Type
    if (elements.length>8)
      this.sigType = elements[8];
    else 
      this.sigType="N/A";
    
    //Load description
    this.description = elements[4];
  
    //Load unit
    this.unit = elements[5];
    
    //Load variable name
    this.varName = elements[3];
    
    //Load factor
    if (elements[6]!="-")
      this.factor = int(elements[6]);
    
    //Load range
    if (elements[7].equals("")){
      rangeLow = 0;
      rangeHigh = 0;

    }
    else {
      String[] rawRange = elements[7].split(" _ ");
      //printArray(rawRange);
      rangeLow = int(rawRange[0]); 
      rangeHigh = int(rawRange[1]); 
      
    }
    
  }


//-------------------- Class methods --------------------\\

//getter

  public String getID(){return id;}
  public String getSigType(){return sigType;}
  public int getBitPos(){return bitPos;}
  public String getDescription(){return description;}
  public String getUnit(){return unit;}
  public int getFactor(){return factor;}
  public String getVarName(){return varName;}
 
  public int[] getRange(){
    int[] rangeOut = {rangeLow,rangeHigh}; 
    return rangeOut;
  }  
  
  public int numberOfBytes(){
    int delta = 1;
    if (bytePos[1]!=0)
      delta = bytePos[1]-bytePos[0]+1;
    return delta;
  }


// ID parser

  public boolean checkID(String inID){
   boolean idRight=false; 
   String[] rawID = id.split("x");
   inID=trim(inID);
   if(inID.equals(rawID[1]))
     idRight=true;
   return idRight;  //<>//
  }
    
    
//Bit Range parser

  public boolean inBitRange(int pos){
    boolean rangeFit = false;
    if(pos<=rangeHigh || pos>=rangeLow)
        rangeFit = true;
    return rangeFit;
  }

//Process value

  public String processValue(String[] elements){
    StringBuilder outputString = null;
    
    for (int i=0;i<elements.length;i++){
      outputString.append(elements[i]);
    }
    
    //text("Current key: " + letter, 50, 70);
    //text("The String is " + words.length() +  " characters long", 50, 90);    
    return outputString.toString();
  
  }

  
}

CanSignal[] mySignals = new CanSignal[canMatrixSize];


///------------------Main Programm-----------------------\\\

void setup(){

 String[] lines = loadStrings("Test.csv");
 //printArray(lines);
 for (int i=0;i<lines.length;i++){
   try {
        mySignals[i] = new CanSignal(lines[i]);
    } catch (NullPointerException e) {
    System.err.println("Exception: " + e.getMessage());
   }

 }
  String portName=Serial.list()[1];
  myPort=new Serial(this,portName,9600);
  println("Init Completed");
}

void draw(){
  String val = "";

  int signalCounter=0;
  int signalLength = 1;
  
  //for (int i=0;i<20;i++){
  //    if(mySignals[i]!=null)
  //        println(i);
  //        println(mySignals[i].getID());
  //}    
    
  if(myPort.available()>0)
     val=myPort.readStringUntil('\n');
  
 
  //println(val);
  if(val!=null)
  {
    String[] valElements;

    //split the number in a table
    valElements=val.split(" ");
    if (valElements[0].equals("CanID:")){
   //read the CanID
      incommingID = valElements[1];
      
  //Search in all signals the first one on this ID  
      while (!mySignals[signalCounter].checkID(incommingID) && signalCounter < canMatrixSize-1){
        signalCounter++;
      }  
      println(signalCounter);
      //signalLength=mySignals[signalCounter].numberOfBytes();
     }
       
//Convert the data in the different packages   
    else if (valElements[0].equals("Message:")){
     println("read data");
      for(int i=1;i<valElements.length;i++){
          dataElements[i-1] = valElements[i];
      }
//Process the data
           
     String signalVeryRaw = mySignals[signalCounter].processValue(dataElements); 
     background(0); // Set background to black

  // Draw the letter to the center of the screen
    textSize(14);
    text(signalVeryRaw, 50, 50);
    signalCounter=0;

    }
    else
      println("Unknown format");
    
  }

}