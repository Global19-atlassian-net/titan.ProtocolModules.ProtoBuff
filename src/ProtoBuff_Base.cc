/******************************************************************************
* Copyright (c) 2013, 2015  Ericsson AB
* All rights reserved. This program and the accompanying materials
* are made available under the terms of the Eclipse Public License v1.0
* which accompanies this distribution, and is available at
* http://www.eclipse.org/legal/epl-v10.html
*
* Contributors:
* Gabor Szalai
******************************************************************************/

//
//  File:               ProtoBuff_Base.cc
//  Description:	      Encoder/Decoder of base types for PBPMG
//  Rev:                R3A
//  Prodnr:             CNL 113 795
///////////////////////////////////////////////
#include "ProtoBuff_Base.hh"

size_t encode_varint(TTCN_Buffer& buff,long long int in, bool sint){
  size_t max_len=10;  // maximum size of varint
  unsigned char* ptr=NULL;
  buff.get_end(ptr,max_len); // get the pointer to the buffer, at leat 10 
                             // octets available
  size_t varint_size=0;
  if(in == 0){  // in is zero, simpliest case, only one octet
    *ptr=0;
    varint_size=1;
  } else if (sint){ // sint encoding used, convert and encode
    // zig zag encoding:  (n << 1) ^ (n >> 63)
    // gcc implements the right shift as arithmetic shift as we need.
    unsigned long long int cint=  (unsigned long long int)( (in << 1) ^ (in >> 63) );  

    while(cint != 0){    // while there is more bits to store
      ptr[varint_size]=cint & 0x7F;// the least significant 7 bits
      cint >>=7;         // shift out the already stored bits
      if(cint!=0){
        ptr[varint_size]|= 0x80;   // there is more bits to store, set the continuation bit
      }
      varint_size++;
    }
    
    
  } else if (in < 0){  // negative number, always 10 octets long
    varint_size=10;
    for(int i=0;i<10;i++){
      ptr[i]=in & 0x7F;// the least significant 7 bits
      if(i!=9){        // first 9 octets always has one more octet 
        ptr[i]|= 0x80; // set the continuation bit
      } else {
        ptr[i]&=0x01;  // the last octet, only contains the 64th bit
      }
      in >>=7;         // shift out the already stored bits
    }
  } else { // positive number
    while(in != 0){     // while there is more bits to store
      ptr[varint_size]=in & 0x7F;// the least significant 7 bits
      in >>=7;         // shift out the already stored bits
      if(in!=0){
        ptr[varint_size]|= 0x80; // there is more bits to store, set the continuation bit
      }
      varint_size++;
    }
    
  }

  buff.increase_length(varint_size);  // increase the buffer size by the used up
                                      // octets
  return varint_size;
}
size_t decode_varint(TTCN_Buffer& buff,long long int& out, bool sint){
  const unsigned char *ptr=buff.get_read_data(); // get the pointer to the data;
  size_t varint_size=0;

  if(sint){  // use zig-zag decode
    unsigned long long int cint=0;
    bool cont_flag=false;
    do {
      // take the 7 LSB bit of the actual octet and move it to its space
      // the LSB octet come first (bit 6 - bit 0) , so needs to be shifted 0*7 
      // the 2nd octet conatins the bit 13 - bit 7, so needs to be shifted 1*7
      // and soo on
      cint|= (ptr[varint_size] & 0x7F) << (varint_size*7);
      cont_flag=ptr[varint_size] & 0x80; // The MSB is a continuation flag;
      varint_size++;
    } while (cont_flag);
    
    bool neg_flag=cint & 0x01; // The LSB is the sign flag in zig-zag
    cint>>=1;
    if(neg_flag){ // if negative
      // the result is the bitwise negation of the cint treated as signed value
      out= (long long int) ~cint;
    } else { // if non negative
      // the result is simply the cint current value;
      out=cint;
    }
    
  } else {
    out=0; // initialise the result
    bool cont_flag=false;
    do {
      // take the 7 LSB bit of the actual octet and move it to its space
      // the LSB octet come first (bit 6 - bit 0) , so needs to be shifted 0*7 
      // the 2nd octet conatins the bit 13 - bit 7, so needs to be shifted 1*7
      // and soo on
      out|= (ptr[varint_size] & 0x7F) << (varint_size*7);
      cont_flag=ptr[varint_size] & 0x80; // The MSB is a continuation flag;
      varint_size++;
    } while (cont_flag);
  }

  buff.increase_pos(varint_size); // set the used number of octets
  return varint_size;
}

size_t encode_tag_length(TTCN_Buffer& buff, int tag,char wire_type, 
                         size_t data_length){
  // Each key in the streamed message is a varint with the value 
  // (field_number << 3) | wire_type ,in other words, the last three
  // bits of the number store the wire type.
  long long int key = (tag<<3) | (wire_type & 0x07);
  // encode the key
  size_t encoded_length=encode_varint(buff,key);
  
  if(wire_type==2) { // A wire type of 2 (length-delimited) means 
                     // that the value is a varint encoded length
                     // followed by the specified number of bytes of data. 
                     // So encode the data lentgh
    encoded_length+=encode_varint(buff,data_length);
  }
  return encoded_length;
}

size_t decode_tag_length(TTCN_Buffer& buff, int& tag,char& wire_type, 
                         size_t& data_length){

  long long int key;
  // decode the key value
  size_t decoded_length=decode_varint(buff,key); 
  // Each key in the streamed message is a varint with the value 
  // (field_number << 3) | wire_type ,in other words, the last three
  // bits of the number store the wire type.
  
  wire_type = key & 0x07; // The last three bits;
  tag = key>>3; // The key part, safe to use int because the max key is 2^29 - 1

  if(wire_type==2) { // A wire type of 2 (length-delimited) means 
                     // that the value is a varint encoded length
                     // followed by the specified number of bytes of data. 
                     // So decode the data lentgh
    long long int dl;
    decoded_length+=decode_varint(buff,dl);
    data_length=dl;
  }
  return decoded_length;

}

// Protobuf use little endian wire encoding
// Sparc: big endian, swap required
// X86: little endian, just memcpy

void get_8_octet(TTCN_Buffer& buff, unsigned char *bc){
  const unsigned char* dv=buff.get_read_data();
#if defined __sparc__ || defined __sparc
  for (int i = 0, k = 7; i < 8; i++, k--) bc[i] = dv[k];
#else
  memcpy(bc,dv,8);
#endif
  buff.increase_pos(8);
}
void put_8_octet(TTCN_Buffer& buff, unsigned char *dv){
 unsigned char* bc;
 size_t max_len=8;
 buff.get_end(bc,max_len);   
#if defined __sparc__ || defined __sparc
  for (int i = 0, k = 7; i < 8; i++, k--) bc[i] = dv[k];
#else
  memcpy(bc,dv,8);
#endif
  buff.increase_length(8);
}

void get_4_octet(TTCN_Buffer& buff, unsigned char *bc){
  const unsigned char* dv=buff.get_read_data();
#if defined __sparc__ || defined __sparc
  for (int i = 0, k = 3; i < 4; i++, k--) bc[i] = dv[k];
#else
  memcpy(bc,dv,4);
#endif
  buff.increase_pos(4);
}
void put_4_octet(TTCN_Buffer& buff, unsigned char *dv){
 unsigned char* bc;
 size_t max_len=4;
 buff.get_end(bc,max_len);   
#if defined __sparc__ || defined __sparc
  for (int i = 0, k = 3; i < 4; i++, k--) bc[i] = dv[k];
#else
  memcpy(bc,dv,4);
#endif
  buff.increase_length(4);
}

// encoding of the base protobuff types
size_t encode_float(TTCN_Buffer& buff, const FLOAT&val){
  type_conv_union cv;
  cv.float_val=val;
  put_4_octet(buff,cv.data);
  return 4;
}
size_t encode_double_(TTCN_Buffer& buff, const ProtoBuff__Types::double_&val){
  type_conv_union cv;
  cv.double_val=val;
  put_8_octet(buff,cv.data);
  return 8;
}

// common encoder for var int types
size_t encode_varint(TTCN_Buffer& buff, const INTEGER&val, bool sint){
  long long int iv=val.get_long_long_val();
  return encode_varint(buff,iv,sint);
}

size_t encode_int32(TTCN_Buffer& buff, const INTEGER&val){
  return encode_varint(buff,val,false);
}
size_t encode_int64(TTCN_Buffer& buff, const INTEGER&val){
  return encode_varint(buff,val,false);
}
size_t encode_uint32(TTCN_Buffer& buff, const INTEGER&val){
  return encode_varint(buff,val,false);
}
size_t encode_uint64(TTCN_Buffer& buff, const INTEGER&val){
  return encode_varint(buff,val,false);
}
size_t encode_sint32(TTCN_Buffer& buff, const INTEGER&val){
  return encode_varint(buff,val,true);
}
size_t encode_sint64(TTCN_Buffer& buff, const INTEGER&val){
  return encode_varint(buff,val,true);
}
size_t encode_fixed32(TTCN_Buffer& buff, const INTEGER&val){
  type_conv_union cv;
  cv.uint_val=val.get_long_long_val();
  put_4_octet(buff,cv.data);
  return 4;
}
size_t encode_fixed64(TTCN_Buffer& buff, const INTEGER&val){
  type_conv_union cv;
  cv.int64_val=val.get_long_long_val();
  put_8_octet(buff,cv.data);
  return 8;
}
size_t encode_sfixed32(TTCN_Buffer& buff, const INTEGER&val){
  type_conv_union cv;
  cv.int_val=val;
  put_4_octet(buff,cv.data);
  return 4;
}
size_t encode_sfixed64(TTCN_Buffer& buff, const INTEGER&val){
  type_conv_union cv;
  cv.int64_val=val.get_long_long_val();
  put_8_octet(buff,cv.data);
  return 8;
}
size_t encode_bool_(TTCN_Buffer& buff, const BOOLEAN&val){
  return encode_varint(buff,val?1:0);
}
size_t encode_string(TTCN_Buffer& buff, const UNIVERSAL_CHARSTRING&val){
  size_t begin_size=buff.get_len();
  val.encode_utf8(buff);
  return buff.get_len()-begin_size;
}
size_t encode_bytes(TTCN_Buffer& buff, const OCTETSTRING&val){
  buff.put_string(val);
  return val.lengthof();
}

// decoding of the base protobuff types
size_t decode_float(TTCN_Buffer& buff, FLOAT&val,size_t max_length){
  type_conv_union cv;
  get_4_octet(buff,cv.data);
  val=cv.float_val;
  return 4;
}
size_t decode_double_(TTCN_Buffer& buff, ProtoBuff__Types::double_&val,size_t max_length){
  type_conv_union cv;
  get_8_octet(buff,cv.data);
  val=cv.double_val;
  return 8;
}

// common decoder for varint types
size_t decode_varint(TTCN_Buffer& buff, INTEGER&val, bool sint){
  long long int iv;
  size_t decoded_size=decode_varint(buff,iv,sint);
  val.set_long_long_val(iv);
  return decoded_size;
}


size_t decode_int32(TTCN_Buffer& buff, INTEGER&val,size_t max_length){
  return decode_varint(buff,val,false);
}
size_t decode_int64(TTCN_Buffer& buff, INTEGER&val,size_t max_length){
  return decode_varint(buff,val,false);
}
size_t decode_uint32(TTCN_Buffer& buff, INTEGER&val,size_t max_length){
  return decode_varint(buff,val,false);
}
size_t decode_uint64(TTCN_Buffer& buff, INTEGER&val,size_t max_length){
  return decode_varint(buff,val,false);
}
size_t decode_sint32(TTCN_Buffer& buff, INTEGER&val,size_t max_length){
  return decode_varint(buff,val,true);
}
size_t decode_sint64(TTCN_Buffer& buff, INTEGER&val,size_t max_length){
  return decode_varint(buff,val,true);
}
size_t decode_fixed32(TTCN_Buffer& buff, INTEGER&val,size_t max_length){
  type_conv_union cv;
  get_4_octet(buff,cv.data);
  val.set_long_long_val(cv.uint_val);
  return 4;
}
size_t decode_fixed64(TTCN_Buffer& buff, INTEGER&val,size_t max_length){
  type_conv_union cv;
  get_8_octet(buff,cv.data);
  val.set_long_long_val(cv.int64_val);
  return 8;
}
size_t decode_sfixed32(TTCN_Buffer& buff, INTEGER&val,size_t max_length){
  type_conv_union cv;
  get_4_octet(buff,cv.data);
  val=cv.int_val;
  return 4;
}
size_t decode_sfixed64(TTCN_Buffer& buff, INTEGER&val,size_t max_length){
  type_conv_union cv;
  get_8_octet(buff,cv.data);
  val.set_long_long_val(cv.int64_val);
  return 8;
}
size_t decode_bool_(TTCN_Buffer& buff, BOOLEAN&val,size_t max_length){
  long long int iv;
  size_t decoded_size=decode_varint(buff,iv,false);
  val= (iv!=0);
  return decoded_size;
}
size_t decode_string(TTCN_Buffer& buff, UNIVERSAL_CHARSTRING&val,size_t max_length){
  val.clean_up();
  val.decode_utf8(max_length,buff.get_read_data());
  buff.increase_pos(max_length);
  return max_length;
}
size_t decode_bytes(TTCN_Buffer& buff, OCTETSTRING&val,size_t max_length){
  val=OCTETSTRING(max_length,buff.get_read_data());
  buff.increase_pos(max_length);
  return max_length;
}

// skip unknown tag
size_t decodeunknown(TTCN_Buffer& buff,char wire_type,size_t max_length){
 size_t ret_val=0;
 switch(wire_type){
   case 1:
     ret_val=4;
     buff.increase_pos(ret_val); 
     break;
   case 5:
     ret_val=8;
     buff.increase_pos(ret_val);
     break;
   case 0: {
       long long int iv;
       ret_val=decode_varint(buff,iv,false);
     }
     break;
   default:
     ret_val=max_length;
     buff.increase_pos(ret_val);
       
 }
 return ret_val;
}
