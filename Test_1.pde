import processing.serial.*;
import controlP5.*;
import java.util.*;

Serial myPort;
int maxLengthOfData = 65;
int canMatrixSize = 22;

CanSignal[] mySignals; 
String incommingID;
int numberOfSignals_ID;
int signalPos;

ControlP5 cp5;
Textarea myTextarea;



//Defining the can signal as a class
class CanSignal{
    private String id;
    private int[] bytePos = new int[2];;
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
    println(elements[1]);

    String[] bytesPos = elements[1].split(" - ");
    print("Input:");
    printArray(bytesPos);
    
    
    this.bytePos[0] = int(bytesPos[0]); 
    println(bytePos[0]);
    
    if (bytesPos.length>=2){
         println("Second byte pos available");

        this.bytePos[1] = int(bytesPos[1]); 
    }
    else 
      this.bytePos[1] = this.bytePos[0];
   
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
   return idRight; 
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
    String outputString = "";
    println("there are :" + elements.length + " values");
    //for (int i=0;i<elements.length;i++){
    //  outputString = outputString + " " + elements[i];
    //}
    String value = "";
    
    for (int i=bytePos[0];i<=bytePos[1];i++)
     {println(i);
     value = value+elements[i];}
     println("The raw value at "+ bytePos[0] + " and " + bytePos[1]+" is: "+value);
     int valueInt = unhex(value);
     
     switch(this.sigType){
       case "bit": 
          outputString = binary(valueInt);
     
       default:
         if(valueInt>rangeLow && valueInt<rangeHigh)
              valueInt=valueInt*factor;
         outputString = varName+": "+str(valueInt)+" "+unit+"\t"+description;
         break;
         
     }
         
    
    //text("Current key: " + letter, 50, 70);
    //text("The String is " + words.length() +  " characters long", 50, 90);    
    return outputString;
  
  }
  
 
  
}




///------------------Main Programm-----------------------\\\



void setup(){
 
 mySignals = new CanSignal[canMatrixSize];
 background(0);
 textFont(createFont("arial",12));
 fill(128);
 String[] lines = loadStrings("Test.csv");
 //printArray(lines);
 for (int i=0;i<lines.length;i++){
   try {
        mySignals[i] = new CanSignal(lines[i]);
    } catch (NullPointerException e) {
    System.err.println("Exception: " + e.getMessage());
   }

 }
  size(400, 400);
  cp5 = new ControlP5(this);
  
  String portName=Serial.list()[1];
  myPort=new Serial(this,portName,9600);
  
  myTextarea = cp5.addTextarea("txt")
                  .setPosition(0,100)
                  .setSize(400,200)
                  .setFont(createFont("arial",12))
                  .setLineHeight(14)
                  .setColor(color(128))
                  .setColorBackground(color(0,0))
                  .setColorForeground(color(255,100));
                  ;
  myTextarea.setText("Waiting for Can Messages....\n");


  
  //List l = Arrays.asList(Serial.list());
  ///* add a ScrollableList, by default it behaves like a DropdownList */
  //cp5.addScrollableList("dropdown")
  //   .setPosition(100, 100)
  //   .setSize(200, 100)
  //   .setBarHeight(20)
  //   .setItemHeight(20)
  //   .addItems(l)
  //   // .setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
  //   ;
  println("Init Completed");
}





void draw(){

  
  //the return string from the serial connection
  String val = "";

   //the counter defines the which signal in the list it is
  int signalCounter=0;
  //the byte lenght of a single signal
  //int signalLength = 1;
 
 
 
//start serial port listening
  if(myPort.available()>0)
     val=myPort.readStringUntil('\n');
  println(val);
  if(val!=null)
  {
    String[] valElements;

    //split the number in a table
    val=trim(val);
    valElements=val.split(" ");
    if (valElements[0].equals("CanID:")){
  
    //read the CanID
      incommingID = valElements[1];
      
    //Searches for the first ococurence of the ID in the signal list
      while (!mySignals[signalCounter].checkID(incommingID) && signalCounter < canMatrixSize-1){
        signalCounter++;
      } 
      signalPos=signalCounter;
      println("First occurenace of a signal with this ID: "+signalCounter);
      
    //Counts the number of signals whcih are available under this ID  
      while (mySignals[signalCounter].checkID(incommingID) && signalCounter < canMatrixSize-1){
        signalCounter++;
      }  
      numberOfSignals_ID = signalCounter-signalPos;
      
     //Print out the ID
      background(0);
      text("CAN ID: "+incommingID,10,10);
      println("This ID has: "+numberOfSignals_ID+" signals");
      //signalLength=mySignals[signalCounter].numberOfBytes();
     }
       
//Convert the data in the different packages   
    else if (valElements[0].equals("Message:")){
     println("read data");
     int messageLength = valElements.length-1;
     String[] dataElements = new String[messageLength];
     
  //Cut of the first element of the recieved string   
     for(int i=0;i<messageLength;i++){
          dataElements[i] = valElements[i+1];
     }

//Loop to analyse the whole message
    for (int i=0;i<numberOfSignals_ID;i++){
        
//Pass the whole message to the signal to process the data
      
      String processedSignal = mySignals[signalPos+i].processValue(dataElements); 
      
// Draw the text

      String text = myTextarea.getText() + processedSignal + "\n"; //<>//
      myTextarea.setText(text);

    }
   
    
    signalCounter=0;
    println("Signal processed");
    
    }
    else
      println("Unknown format");
    
  }
}


//void dropdown(int n) {
//  /* request the selected item based on index n */
//  println(n, cp5.get(ScrollableList.class, "dropdown").getItem(n));
  
//  /* here an item is stored as a Map  with the following key-value pairs:
//   * name, the given name of the item
//   * text, the given text of the item by default the same as name
//   * value, the given value of the item, can be changed by using .getItem(n).put("value", "abc"); a value here is of type Object therefore can be anything
//   * color, the given color of the item, how to change, see below
//   * view, a customizable view, is of type CDrawable 
//   */
  
   
//  String portName = cp5.get(ScrollableList.class, "dropdown").getItem(n).get("text").toString();
//  myPort=new Serial(this,portName,9600);
//  println("New port set");
  
//}