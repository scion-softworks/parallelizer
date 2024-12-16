A list of supported serializable data types

- ### u8
Occupies 1 byte, short for unsigned integer 8 bit (uint8)

- ### u16
Occupies 2 bytes, short for unsigned integer 16 bit (uint16)

- ### u32
Occupies 4 bytes, short for unsigned integer 32 bit (uint32)

- ### i8
Occupies 1 byte, short for signed integer 8 bit (uint8)

- ### i16
Occupies 2 bytes, short for signed integer 16 bit (uint16)

- ### i32
Occupies 4 bytes, short for signed integer 32 bit (uint32)

- ### bool
Occupies 1 byte, serializes as a `u8` (1 or 0)

- ### str(len)
Occupies `len+4` bytes, 4 extra bytes for storing the length as a u32

- ### vector3
Occupies 24 bytes, 8 bytes for each axis (XYZ)

- ### vector3i16
Occupies 6 bytes, 2 bytes for each axis (XYZ). Short for vector3int16

- ### vector2
Occupies 16 bytes, 8 byte for each axis (XY)

- ### vector2i16
Occupies 24 bytes, 2 byte for each axis (XY). Short for vector2int16

- ### cframe
Occupies 48 bytes, 24 bytes for XYZ positional components, another 24 bytes for XYZ rotational components

- ### color3
Occupies 24 bytes, 8 bytes for each channel

- ### color3u8
Occupies 3 bytes, 1 byte for each channel. Short for color3uint8

- ### color3b16
Occupies 2 bytes. 5 bits for red, 6 bits for green, 5 bits for blue. Short for color3bit16