/******************************************************************************
* Copyright (c) 2000-2019 Ericsson Telecom AB
* All rights reserved. This program and the accompanying materials
* are made available under the terms of the Eclipse Public License v2.0
* which accompanies this distribution, and is available at
* https://www.eclipse.org/org/documents/epl-2.0/EPL-2.0.html
*
* Contributors:
* Gabor Szalai
******************************************************************************/

//
//  File:               ProtoBuff_Base.hh
//  Description:	      Encoder/Decoder of base types for PBPMG
//  Rev:                R3A
//  Prodnr:             CNL 113 795
///////////////////////////////////////////////
#include "ProtoBuff_Types.hh"

typedef union {
  float float_val;
  double double_val;
  int    int_val;
  unsigned int uint_val;
  long long int int64_val;
  unsigned long long int uint64_val;
  unsigned char data[8];
} type_conv_union;

size_t encode_varint(TTCN_Buffer& buff,long long int in, bool sint=false);
size_t decode_varint(TTCN_Buffer& buff,long long int& out, bool sint=false);

size_t encode_tag_length(TTCN_Buffer& buff, int tag,char wire_type, 
                         size_t data_length=0);

size_t decode_tag_length(TTCN_Buffer& buff, int& tag,char& wire_type, 
                         size_t& data_length);

size_t encode_float(TTCN_Buffer& buff, const FLOAT&val);
size_t encode_double_(TTCN_Buffer& buff, const ProtoBuff__Types::double_&val);
size_t encode_int32(TTCN_Buffer& buff, const INTEGER&val);
size_t encode_int64(TTCN_Buffer& buff, const INTEGER&val);
size_t encode_uint32(TTCN_Buffer& buff, const INTEGER&val);
size_t encode_uint64(TTCN_Buffer& buff, const INTEGER&val);
size_t encode_sint32(TTCN_Buffer& buff, const INTEGER&val);
size_t encode_sint64(TTCN_Buffer& buff, const INTEGER&val);
size_t encode_fixed32(TTCN_Buffer& buff, const INTEGER&val);
size_t encode_fixed64(TTCN_Buffer& buff, const INTEGER&val);
size_t encode_sfixed32(TTCN_Buffer& buff, const INTEGER&val);
size_t encode_sfixed64(TTCN_Buffer& buff, const INTEGER&val);
size_t encode_bool_(TTCN_Buffer& buff, const BOOLEAN&val);
size_t encode_string(TTCN_Buffer& buff, const UNIVERSAL_CHARSTRING&val);
size_t encode_bytes(TTCN_Buffer& buff, const OCTETSTRING&val);

size_t decode_float(TTCN_Buffer& buff, FLOAT&val,size_t max_length);
size_t decode_double_(TTCN_Buffer& buff, ProtoBuff__Types::double_&val,size_t max_length);
size_t decode_int32(TTCN_Buffer& buff, INTEGER&val,size_t max_length);
size_t decode_int64(TTCN_Buffer& buff, INTEGER&val,size_t max_length);
size_t decode_uint32(TTCN_Buffer& buff, INTEGER&val,size_t max_length);
size_t decode_uint64(TTCN_Buffer& buff, INTEGER&val,size_t max_length);
size_t decode_sint32(TTCN_Buffer& buff, INTEGER&val,size_t max_length);
size_t decode_sint64(TTCN_Buffer& buff, INTEGER&val,size_t max_length);
size_t decode_fixed32(TTCN_Buffer& buff, INTEGER&val,size_t max_length);
size_t decode_fixed64(TTCN_Buffer& buff, INTEGER&val,size_t max_length);
size_t decode_sfixed32(TTCN_Buffer& buff, INTEGER&val,size_t max_length);
size_t decode_sfixed64(TTCN_Buffer& buff, INTEGER&val,size_t max_length);
size_t decode_bool_(TTCN_Buffer& buff, BOOLEAN&val,size_t max_length);
size_t decode_string(TTCN_Buffer& buff, UNIVERSAL_CHARSTRING&val,size_t max_length);
size_t decode_bytes(TTCN_Buffer& buff, OCTETSTRING&val,size_t max_length);

size_t decodeunknown(TTCN_Buffer& buff,char wire_type,size_t max_length);

