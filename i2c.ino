#include <Wire.h>

// #define SLAVE_ADDR (0b01001111)
#define SLAVE_ADDR (0b0110000)

#define START_CONV  (0xEE)
#define READ_TEMP   (0xAA)

uint8_t data[2] = {0xFF, 0x00};
 
void setup() {
  // put your setup code here, to run once:

  Wire.begin();
  //Wire.setClock(400000);

  Serial.begin(9600);
  Serial.println("I2C Master Demonsration");

  delay(2000);
}

void loop() {

  
  delay(100);
  Wire.beginTransmission(SLAVE_ADDR);
  Wire.write(data, 2);
  // Wire.write((data >> 0) & 0x00FF);
  
  Wire.endTransmission();
  data[1] += 1;
  data[0] -= 1;



  /*
  
  Wire.requestFrom(SLAVE_ADDR, 16);

  uint8_t data_rem = 1;
  uint16_t temp = 0;
  while(Wire.available())
  {
    temp |= Wire.read() << 8*data_rem;
    if (data_rem == 0)
    {
       data_rem = 1;
       break;
    }

    data_rem--;
  }

  Serial.print("Temperatura: ");
  Serial.println(0.5f*(temp/128.0f));

  */

}
