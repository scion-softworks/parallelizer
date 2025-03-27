A list of supported serializable data types

- ### u8
Occupies 1 byte, short for unsigned 8 bit integer (uint8)

- ### u16
Occupies 2 bytes, short for unsigned 16 bit integer (uint16)

- ### u32
Occupies 4 bytes, short for unsigned 32 bit integer (uint32)

- ### i8
Occupies 1 byte, short for signed 8 bit integer (int8)

- ### i16
Occupies 2 bytes, short for signed 16 bit integer (int16)

- ### i32
Occupies 4 bytes, short for signed 32 bit integer (int32)

- ### f32
Occupies 4 bytes, short for 32 bit floating point number

- ### f64
Occupies 8 bytes, short for 64 bit floating point number

- ### bool
Occupies 1 byte, serializes as a `u8` (1 or 0)

- ### str(len)
Occupies `len+4` bytes, 4 extra bytes for storing the length (u32) 

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

- ### cframef32 <span class="badge badge--experimental">EXPERIMENTAL</span>
Occupies 24 bytes, 16 bytes for XYZ positional components, another 16 bytes for XYZ rotational components

- ### cframe18 <span class="badge badge--experimental">EXPERIMENTAL</span>
Occupies 18 bytes, 12 bytes for XYZ positional components, 6 bytes for XYZ rotational components (`4.8 * 10^-5` radians or `2.75 * 10^-3` degrees of precision loss at most)

- ### color3
Occupies 3 bytes, 1 byte for each channel

- ### color3b16
Occupies 2 bytes. 5 bits for red, 6 bits for green, 5 bits for blue. Short for color3bit16. This takes a bit longer to serialize than Color3

- ### buffer(len)
Occupies `len+2` bytes. 2 extra bytes to store the buffer length (u16). This takes a bit longer to serialize
