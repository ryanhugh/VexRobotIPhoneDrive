#include "Main.h"
#include "myheader.h"


void onTimer(void){

    int currtime=GetTimer(kHeartBeatTimer);
    if (currtime>=500)
    {
        SetMotor(1,0);
        SetMotor(2,0);
        SetMotor(3,0);
        SetMotor(4,0);
        SetMotor(5,0);
        SetMotor(6,0);
        SetMotor(7,0);
        SetMotor(8,0);
        SetMotor(9,0);
        SetMotor(10,0);
        printf("Emergency stop! %i\n",currtime );
        PresetTimer(kHeartBeatTimer,0);
    }
}


//used for arcade drive
int limitValue(int value){
    if (value>=127)
    {
        return 127;
    }
    else if (value<=-127)
    {
        return -127;
    }
    return value;
}

void actualDriver( void ){

    printf("init\n");

    OpenSerialPort(kPortNumber, 115200);

    //buffer (-1 means empty because 0 is a valid motor value)
    int readList[3];
    readList[0]=-1;
    readList[1]=-1;
    readList[2]=-1;
    unsigned char chr;

    //stop robot if no heartbeat message is recieved every 500 ms
    StartTimer(kHeartBeatTimer);
    PresetTimer(kHeartBeatTimer,0);
    RegisterRepeatingTimer(500,onTimer);

    while (1){
        Wait(1);

        chr=ReadSerialPort(kPortNumber);

        if (chr==0)
        {
            continue;
        }

        //put the chr in the last empty spot
        unsigned char i=0;
        for (i = 0; i < 3; i++)
        {
            if (readList[i]==-1)
            {
                readList[i]=chr;
                break;
            }
        }


        if (readList[0]==90)
        {
            WriteSerialPort(kPortNumber,90);
            printf("wrote 90\n");


            //more on this below
            readList[0]=readList[1];
            readList[1]=readList[2];
            readList[2]=-1;

            //restart timer so emergency stop dosen't stop robot
            PresetTimer(kHeartBeatTimer,0);
            continue;
        }

        //a driver packet
        else if (readList[0]&128)
        {

            //have not recieved everything
            if (readList[2]==-1)
            {
                dlog("Waiting for all values(%i,%i,%i)\n",readList[0],readList[1],readList[2]);
                continue;
            }

            //validate the checksum
            if (readList[0]==((readList[1]&25)|(readList[2]&102)|128)){

                //change from recieved accelerometer values to simulated joystick values
                //sent values range from 0-255,
                //Y is just positive in the other direction as the joystick
                readList[2]=readList[2]-127;
                readList[1]=127-readList[1];

                //"arcade" drive
                int leftSide = limitValue(readList[1] + ((int)readList[2]));
                int rightSide =limitValue(readList[1] - ((int)readList[2]));


#ifdef kShowDebug
                if (isPressed(10))
                {
                    printf("motor values:%i and %i\n",leftSide,rightSide);
                }
#endif


                //small robot
                SetMotor(8,leftSide);
                SetMotor(2,rightSide);

                //big robot
                // SetMotor(2,leftSide);
                // SetMotor(8,leftSide);
                // SetMotor(3,-rightSide);
                // SetMotor(9,-rightSide);


                //reset for next three bytes
                readList[0]=-1;
                readList[1]=-1;
                readList[2]=-1;
                continue;

            }

            else{


                //this is so a bad packet does not frameshift everything
                //eg if a motor value is dropped and "cxcxy" is recieved (c=motor checksum)
                //the next packet can be used
                alog("bad checksum({%i},%i,%i,%i)!\n",chr,readList[0],readList[1],readList[2] );
                readList[0]=readList[1];
                readList[1]=readList[2];
                readList[2]=-1;
                continue;
            }

        }
        else{

            alog("bad checksum({%i},%i,%i,%i)!\n",chr,readList[0],readList[1],readList[2] );
            readList[0]=readList[1];
            readList[1]=readList[2];
            readList[2]=-1;
            continue;
        }

        alog("ERROR: weird error {%i},%i,%i,%i\n",chr, readList[0],readList[1],readList[2]);
        continue;
    }
}

