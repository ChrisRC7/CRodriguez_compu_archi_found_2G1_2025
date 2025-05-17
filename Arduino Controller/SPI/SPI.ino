#include <SPI.h>

const int ssPin = 10; // Slave Select pin
byte velocidad = 0;
const byte ACK_EXPECTED = 0xA5; // El byte de ACK que esperamos de la FPGA

SPISettings spiSettings(1000000, MSBFIRST, SPI_MODE0); // 1MHz, MSB primero, Modo 0

void setup() {
  Serial.begin(9600);
  while (!Serial);

  pinMode(ssPin, OUTPUT);
  digitalWrite(ssPin, HIGH); // Deseleccionar esclavo inicialmente

  SPI.begin();

  Serial.println("Arduino Maestro SPI Inicializado (con Handshake ACK).");
}

void loop() {
  // Preparar el dato de 4 bits de velocidad (en los 4 bits MSB del byte)
  byte dato_a_enviar = (velocidad & 0x0F) << 4;
  byte ack_recibido;

  Serial.print("Enviando Velocidad: ");
  Serial.print(velocidad);
  Serial.print(" (Byte: 0b");
  for (int i = 7; i >= 0; i--) {
    Serial.print(bitRead(dato_a_enviar, i));
  }
  Serial.print(")... ");

  SPI.beginTransaction(spiSettings);
  digitalWrite(ssPin, LOW); // Seleccionar FPGA

  // Enviar el comando Y SIMULTÁNEAMENTE recibir el byte de ACK de la FPGA
  ack_recibido = SPI.transfer(dato_a_enviar);

  digitalWrite(ssPin, HIGH); // Deseleccionar FPGA
  SPI.endTransaction();

  // Verificar el ACK
  if (ack_recibido == ACK_EXPECTED) {
    Serial.print("ACK Recibido: 0x");
    Serial.print(ack_recibido, HEX);
    Serial.println(" - OK!");
  } else {
    Serial.print("ACK Fallido o Incorrecto. Recibido: 0x");
    Serial.print(ack_recibido, HEX);
    Serial.println(" - ERROR!");
    // Aquí podrías implementar lógica para reintentar el envío si es necesario,
    // según la especificación del proyecto [cite: 52]
  }

  velocidad++;
  if (velocidad > 15) {
    velocidad = 0;
  }

  delay(1500); // Un delay un poco más largo para leer la consola
}