#/******************************************************************************
#* Copyright (c) 2013, 2015  Ericsson AB
#* All rights reserved. This program and the accompanying materials
#* are made available under the terms of the Eclipse Public License v1.0
#* which accompanies this distribution, and is available at
#* http://www.eclipse.org/legal/epl-v10.html
#*
#* Contributors:
#* Gabor Szalai
#******************************************************************************/


# calculate the ttcn3 module name from proto file name
function get_ttcn3_module_name(fname, ret_val){

#  if(fname SUBSEP "PACKAGE" in AST) {
#    ret_val=AST[fname SUBSEP "PACKAGE"];
#  } else {
    ret_val=fname;
#  }
  gsub(/\./,"_",ret_val);
  return ret_val;
}

# convert id to valid TTCN3 identifier
function conv2ttcn3id(id, ret_val){
  ret_val=id;
  gsub(/@/,"_",ret_val);
  
  if(ret_val in ttcn3_ids){
    ret_val=ttcn3_ids[ret_val]
  }
  
  return ret_val;
}

# convert ttcn3 identifier to cc identifier
function cc_name(id,ret_val){
  ret_val=id;
  gsub(/@/,"_",ret_val);
  gsub(/_/,"__",ret_val);
  if(ret_val in ttcn3_cc_id_map){
    ret_val=ttcn3_cc_id_map[ret_val]
  }
  
  return ret_val;
  
}

# convert id to valid TTCN3 type name
function conv2ttcn3typeid(id, f ,ret_val){
  ret_val=id;
  gsub(/@/,"_",ret_val);
  if(f SUBSEP "PACKAGE" in AST) {
    ret_val=AST[f SUBSEP "PACKAGE"] "_" ret_val;
  } else {
#    ret_val=fname;
  }
  
  if(ret_val in ttcn3_ids){
    ret_val=ttcn3_ids[ret_val]
  }
  
  return ret_val;
}

# convert id to scoped TTCN3 type name
function get_scoped_id(id,scope,f,ret_val,cp_name){
#print "get_scoped_id("id","scope","f ")"
  if(f SUBSEP "PACKAGE" in AST) {
    cp_name=AST[f SUBSEP "PACKAGE"] "@";
  } else {
    cp_name="";
  }
  ret_val=id;
  gsub(/\./,"@",ret_val);

  match(id,/\./);
  if (RSTART > 0){ # reference like ref.ref.messagetype
    if(ret_val SUBSEP "BASE" in SCOPE_DB) { # full scope specified
      return conv2ttcn3id(ret_val);
    } else if ( cp_name ret_val SUBSEP "BASE" in SCOPE_DB){ # found in the same packages
      return conv2ttcn3id(cp_name ret_val);
    }
  }
  
  cp_name=cp_name scope # the full scope
  
  while( cp_name != "" ){
#print "cp_name="cp_name
    if(cp_name "@" ret_val SUBSEP "BASE" in SCOPE_DB ){
      return conv2ttcn3id(cp_name "@" ret_val);
    }
    last_at=rindex(cp_name,"@");
    if(last_at>0){
      cp_name=substr(cp_name,1,last_at-1);
    } else {
      cp_name="";
    }
  }
#print "return " id
  return id; # base type
}
function get_scoped_scope_id(id,scope,f,ret_val,cp_name){
#print "get_scoped_id("id","scope","f ")"
  if(f SUBSEP "PACKAGE" in AST) {
    cp_name=AST[f SUBSEP "PACKAGE"] "@";
  } else {
    cp_name="";
  }
  ret_val=id;
  gsub(/\./,"@",ret_val);

  match(id,/\./);
  if (RSTART > 0){ # reference like ref.ref.messagetype
    if(ret_val SUBSEP "BASE" in SCOPE_DB) { # full scope specified
      return ret_val;
    } else if ( cp_name ret_val SUBSEP "BASE" in SCOPE_DB){ # found in the same packages
      return cp_name ret_val;
    }
  }
  
  cp_name=cp_name scope # the full scope
  
  while( cp_name != "" ){
#print "cp_name="cp_name
    if(cp_name "@" ret_val SUBSEP "BASE" in SCOPE_DB ){
      return cp_name "@" ret_val;
    }
    last_at=rindex(cp_name,"@");
    if(last_at>0){
      cp_name=substr(cp_name,1,last_at-1);
    } else {
      cp_name="";
    }
  }
#print "return " id
  return id; # base type
}

function rindex(str,c)
{
  return match(str,"\\" c "[^" c "]*$")? RSTART : 0
}


# scope handling functions
function addscope(lc){
  if(length(scope)>0){
    scope=scope "@" lc
  } else {
    scope=lc
  }
}
function popscope(lc){
  scope=substr(scope,1,length(scope)-length(lc));
  if(length(scope)>0){
    scope=substr(scope,1,length(scope)-1);
  }
}

function push_scope_stack(new_scope){
  ++scope_stack_level;
  scope_stack[scope_stack_level]=new_scope;
  addscope(new_scope);
#  print "push "  state_stack_level, " " state_stack[state_stack_level]
}
function pop_scope_stack(){
  popscope(scope_stack[scope_stack_level]);
  --scope_stack_level;
#  print "pop "  state_stack_level, " " state_stack[state_stack_level]
}

# basename function
function basename (pathname){
        sub(/^.*\//, "", pathname)
        return pathname
}

# Array handling for older AWKs

# Copy all elements of the "arr" into "ret_val"
# if the index of the element is starts with "ind SUBSEP"
# the "ind SUBSEP" is stripped of from the new index
# The function emulates the subarray functionality
function get_subarray(arr, ind, ret_val,x){
  for(x in arr){
    match(x,"^"ind SUBSEP )
    if(RSTART > 0 ){
      ret_val[substr(x,RLENGTH+1)]=arr[x]
    }
  }
}

# The function enumerates the number of different first level index
# and returns them in "ret_val"
function get_array_length(arr,ret_val,a,x){
  delete ret_val
  for(x in arr){
    split(x,a,SUBSEP);
    ret_val[a[1]]=a[1]
  }
  return length(ret_val)
}


# state handling functions

function push_state(new_state){
  ++state_stack_level;
  state_stack[state_stack_level]=parser_state;
  parser_state=new_state;
#  print "push "  state_stack_level, " " state_stack[state_stack_level]
}
function pop_state(){
  parser_state=state_stack[state_stack_level];
  --state_stack_level;
#  print "pop "  state_stack_level, " " state_stack[state_stack_level]
}
function start_state(){
     parser_state="START";
     state_stack_level=1;
}


# prints the multi dimension like array in pretty printed form
     function walk_array(arr, name,      i,k,l,p)
     {
#print "walk array start " name
        delete p
        for (i in arr) {
#print "process " i
          split(i,k,SUBSEP)
          if(length(k)>1){
#print "subaaray found"
            if(!(k[1] in p)){
#print "subaaray process"
              delete l;
              get_subarray(arr,k[1],l)
              walk_array(l, name "[" k[1] "]")
              p[k[1]]=k[1]
            }
          } else {
            printf("%s[%s] = %s\n", name, i, arr[i])
          }
        }
#print "walk array end " name
     }

# store the field data of the message
function store_field(x){
  x=AST[t_file SUBSEP "MESSAGES" SUBSEP scope SUBSEP "NUM_OF_FIELDS"];
  ++x;
  AST[t_file SUBSEP "MESSAGES" SUBSEP scope SUBSEP "NUM_OF_FIELDS"]=x;
  AST[t_file SUBSEP "MESSAGES" SUBSEP scope SUBSEP x SUBSEP "FIELD_NAME"]=field_name;
  AST[t_file SUBSEP "MESSAGES" SUBSEP scope SUBSEP x SUBSEP "FIELD_SPEC"]=field_spec;
  AST[t_file SUBSEP "MESSAGES" SUBSEP scope SUBSEP x SUBSEP "FIELD_TYPE"]=field_type;
  AST[t_file SUBSEP "MESSAGES" SUBSEP scope SUBSEP x SUBSEP "FIELD_NUM"]=field_num;
  AST[t_file SUBSEP "MESSAGES" SUBSEP scope SUBSEP x SUBSEP "FIELD_PACKED"]=field_packed;

  if(field_spec== "repeated"){
    AST[t_file SUBSEP "REPEATED_FIELDS" SUBSEP scope SUBSEP field_name SUBSEP "TYPE"] = field_type;
    AST[t_file SUBSEP "REPEATED_FIELDS" SUBSEP scope SUBSEP field_name SUBSEP "FIELD_PACKED"] = field_packed;
  } 
}

# initialize the TTCN-3 reserved id map
function fill_ttcn_ids(){
  ttcn3_ids["double"]="double_"
  ttcn3_ids["action"]="action_"
  ttcn3_ids["activate"]="activate_"
  ttcn3_ids["address"]="address_"
  ttcn3_ids["alive"]="alive_"
  ttcn3_ids["all"]="all_"
  ttcn3_ids["alt"]="alt_"
  ttcn3_ids["altstep"]="altstep_"
  ttcn3_ids["and"]="and_"
  ttcn3_ids["and4b"]="and4b_"
  ttcn3_ids["any"]="any_"
  ttcn3_ids["anytype"]="anytype_"
  ttcn3_ids["bitstring"]="bitstring_"
  ttcn3_ids["boolean"]="boolean_"
  ttcn3_ids["break"]="break_"
  ttcn3_ids["case"]="case_"
  ttcn3_ids["call"]="call_"
  ttcn3_ids["catch"]="catch_"
  ttcn3_ids["char"]="char_"
  ttcn3_ids["charstring"]="charstring_"
  ttcn3_ids["check"]="check_"
  ttcn3_ids["clear"]="clear_"
  ttcn3_ids["complement"]="complement_"
  ttcn3_ids["component"]="component_"
  ttcn3_ids["connect"]="connect_"
  ttcn3_ids["const"]="const_"
  ttcn3_ids["continue"]="continue_"
  ttcn3_ids["control"]="control_"
  ttcn3_ids["create"]="create_"
  ttcn3_ids["deactivate"]="deactivate_"
  ttcn3_ids["default"]="default_"
  ttcn3_ids["disconnect"]="disconnect_"
  ttcn3_ids["display"]="display_"
  ttcn3_ids["do"]="do_"
  ttcn3_ids["done"]="done_"
  ttcn3_ids["else"]="else_"
  ttcn3_ids["encode"]="encode_"
  ttcn3_ids["enumerated"]="enumerated_"
  ttcn3_ids["error"]="error_"
  ttcn3_ids["except"]="except_"
  ttcn3_ids["exception"]="exception_"
  ttcn3_ids["execute"]="execute_"
  ttcn3_ids["extends"]="extends_"
  ttcn3_ids["extension"]="extension_"
  ttcn3_ids["external"]="external_"
  ttcn3_ids["fail"]="fail_"
  ttcn3_ids["false"]="false_"
  ttcn3_ids["float"]="float_"
  ttcn3_ids["for"]="for_"
  ttcn3_ids["friend"]="friend_"
  ttcn3_ids["from"]="from_"
  ttcn3_ids["function"]="function_"
  ttcn3_ids["getverdict"]="getverdict_"
  ttcn3_ids["getcall"]="getcall_"
  ttcn3_ids["getreply"]="getreply_"
  ttcn3_ids["goto"]="goto_"
  ttcn3_ids["group"]="group_"
  ttcn3_ids["halt"]="halt_"
  ttcn3_ids["hexstring"]="hexstring_"
  ttcn3_ids["if"]="if_"
  ttcn3_ids["ifpresent"]="ifpresent_"
  ttcn3_ids["import"]="import_"
  ttcn3_ids["in"]="in_"
  ttcn3_ids["inconc"]="inconc_"
  ttcn3_ids["infinity"]="infinity_"
  ttcn3_ids["inout"]="inout_"
  ttcn3_ids["integer"]="integer_"
  ttcn3_ids["interleave"]="interleave_"
  ttcn3_ids["kill"]="kill_"
  ttcn3_ids["killed"]="killed_"
  ttcn3_ids["label"]="label_"
  ttcn3_ids["language"]="language_"
  ttcn3_ids["length"]="length_"
  ttcn3_ids["log"]="log_"
  ttcn3_ids["map"]="map_"
  ttcn3_ids["match"]="match_"
  ttcn3_ids["message"]="message_"
  ttcn3_ids["mixed"]="mixed_"
  ttcn3_ids["mod"]="mod_"
  ttcn3_ids["modifies"]="modifies_"
  ttcn3_ids["module"]="module_"
  ttcn3_ids["modulepar"]="modulepar_"
  ttcn3_ids["mtc"]="mtc_"
  ttcn3_ids["noblock"]="noblock_"
  ttcn3_ids["none"]="none_"
  ttcn3_ids["not"]="not_"
  ttcn3_ids["not4b"]="not4b_"
  ttcn3_ids["nowait"]="nowait_"
  ttcn3_ids["null"]="null_"
  ttcn3_ids["octetstring"]="octetstring_"
  ttcn3_ids["of"]="of_"
  ttcn3_ids["omit"]="omit_"
  ttcn3_ids["on"]="on_"
  ttcn3_ids["optional"]="optional_"
  ttcn3_ids["or"]="or_"
  ttcn3_ids["or4b"]="or4b_"
  ttcn3_ids["out"]="out_"
  ttcn3_ids["override"]="override_"
  ttcn3_ids["param"]="param_"
  ttcn3_ids["pass"]="pass_"
  ttcn3_ids["pattern"]="pattern_"
  ttcn3_ids["permutation"]="permutation_"
  ttcn3_ids["port"]="port_"
  ttcn3_ids["present"]="present_"
  ttcn3_ids["private"]="private_"
  ttcn3_ids["procedure"]="procedure_"
  ttcn3_ids["public"]="public_"
  ttcn3_ids["raise"]="raise_"
  ttcn3_ids["read"]="read_"
  ttcn3_ids["receive"]="receive_"
  ttcn3_ids["record"]="record_"
  ttcn3_ids["recursive"]="recursive_"
  ttcn3_ids["rem"]="rem_"
  ttcn3_ids["repeat"]="repeat_"
  ttcn3_ids["reply"]="reply_"
  ttcn3_ids["return"]="return_"
  ttcn3_ids["running"]="running_"
  ttcn3_ids["runs"]="runs_"
  ttcn3_ids["select"]="select_"
  ttcn3_ids["self"]="self_"
  ttcn3_ids["send"]="send_"
  ttcn3_ids["sender"]="sender_"
  ttcn3_ids["set"]="set_"
  ttcn3_ids["setverdict"]="setverdict_"
  ttcn3_ids["signature"]="signature_"
  ttcn3_ids["start"]="start_"
  ttcn3_ids["stop"]="stop_"
  ttcn3_ids["subset"]="subset_"
  ttcn3_ids["superset"]="superset_"
  ttcn3_ids["system"]="system_"
  ttcn3_ids["template"]="template_"
  ttcn3_ids["testcase"]="testcase_"
  ttcn3_ids["timeout"]="timeout_"
  ttcn3_ids["timer"]="timer_"
  ttcn3_ids["to"]="to_"
  ttcn3_ids["trigger"]="trigger_"
  ttcn3_ids["true"]="true_"
  ttcn3_ids["type"]="type_"
  ttcn3_ids["union"]="union_"
  ttcn3_ids["universal"]="universal_"
  ttcn3_ids["unmap"]="unmap_"
  ttcn3_ids["value"]="value_"
  ttcn3_ids["valueof"]="valueof_"
  ttcn3_ids["var"]="var_"
  ttcn3_ids["variant"]="variant_"
  ttcn3_ids["verdicttype"]="verdicttype_"
  ttcn3_ids["while"]="while_"
  ttcn3_ids["with"]="with_"
  ttcn3_ids["xor"]="xor_"
  ttcn3_ids["xor4b"]="xor4b_"

  ttcn3_cc_id_map["asm"]="asm_"
  ttcn3_cc_id_map["auto"]="auto_"
  ttcn3_cc_id_map["bitand"]="bitand_"
  ttcn3_cc_id_map["bitor"]="bitor_"
  ttcn3_cc_id_map["bool"]="bool_"
  ttcn3_cc_id_map["break"]="break_"
  ttcn3_cc_id_map["case"]="case_"
  ttcn3_cc_id_map["class"]="class_"
  ttcn3_cc_id_map["compl"]="compl_"
  ttcn3_cc_id_map["continue"]="continue_"
  ttcn3_cc_id_map["delete"]="delete_"
  ttcn3_cc_id_map["double"]="double_"
  ttcn3_cc_id_map["enum"]="enum_"
  ttcn3_cc_id_map["explicit"]="explicit_"
  ttcn3_cc_id_map["export"]="export_"
  ttcn3_cc_id_map["friend"]="friend_"
  ttcn3_cc_id_map["inline"]="inline_"
  ttcn3_cc_id_map["int"]="int_"
  ttcn3_cc_id_map["ischosen"]="ischosen_"
  ttcn3_cc_id_map["long"]="long_"
  ttcn3_cc_id_map["main"]="main_"
  ttcn3_cc_id_map["mutable"]="mutable_"
  ttcn3_cc_id_map["namespace"]="namespace_"
  ttcn3_cc_id_map["new"]="new_"
  ttcn3_cc_id_map["operator"]="operator_"
  ttcn3_cc_id_map["private"]="private_"
  ttcn3_cc_id_map["protected"]="protected_"
  ttcn3_cc_id_map["public"]="public_"
  ttcn3_cc_id_map["register"]="register_"
  ttcn3_cc_id_map["short"]="short_"
  ttcn3_cc_id_map["signed"]="signed_"
  ttcn3_cc_id_map["static"]="static_"
  ttcn3_cc_id_map["stderr"]="stderr_"
  ttcn3_cc_id_map["stdin"]="stdin_"
  ttcn3_cc_id_map["stdout"]="stdout_"
  ttcn3_cc_id_map["struct"]="struct_"
  ttcn3_cc_id_map["switch"]="switch_"
  ttcn3_cc_id_map["this"]="this_"
  ttcn3_cc_id_map["throw"]="throw_"
  ttcn3_cc_id_map["try"]="try_"
  ttcn3_cc_id_map["typedef"]="typedef_"
  ttcn3_cc_id_map["typeid"]="typeid_"
  ttcn3_cc_id_map["typename"]="typename_"
  ttcn3_cc_id_map["unsigned"]="unsigned_"
  ttcn3_cc_id_map["using"]="using_"
  ttcn3_cc_id_map["virtual"]="virtual_"
  ttcn3_cc_id_map["void"]="void_"
  ttcn3_cc_id_map["volatile"]="volatile_"
  ttcn3_cc_id_map["ADDRESS"]="ADDRESS_"
  ttcn3_cc_id_map["BITSTRING"]="BITSTRING_"
  ttcn3_cc_id_map["BOOLEAN"]="BOOLEAN_"
  ttcn3_cc_id_map["CHAR"]="CHAR_"
  ttcn3_cc_id_map["CHARSTRING"]="CHARSTRING_"
  ttcn3_cc_id_map["COMPONENT"]="COMPONENT_"
  ttcn3_cc_id_map["DEFAULT"]="DEFAULT_"
  ttcn3_cc_id_map["ERROR"]="ERROR_"
  ttcn3_cc_id_map["FAIL"]="FAIL_"
  ttcn3_cc_id_map["FALSE"]="FALSE_"
  ttcn3_cc_id_map["FLOAT"]="FLOAT_"
  ttcn3_cc_id_map["HEXSTRING"]="HEXSTRING_"
  ttcn3_cc_id_map["INCONC"]="INCONC_"
  ttcn3_cc_id_map["INTEGER"]="INTEGER_"
  ttcn3_cc_id_map["NONE"]="NONE_"
  ttcn3_cc_id_map["OBJID"]="OBJID_"
  ttcn3_cc_id_map["OCTETSTRING"]="OCTETSTRING_"
  ttcn3_cc_id_map["PASS"]="PASS_"
  ttcn3_cc_id_map["PORT"]="PORT_"
  ttcn3_cc_id_map["TIMER"]="TIMER_"
  ttcn3_cc_id_map["TRUE"]="TRUE_"
  ttcn3_cc_id_map["VERDICTTYPE"]="VERDICTTYPE_"

}

BEGIN {
     comment= 0;
     parser_state="START";
#     processed_files[ARGV[1]]=ARGV[1];
     state_stack_level=1;
     state_stack[1]="NONE"
     public_import_flag=0;
     scope="";
     scope_stack_level=0;
     scope_stack[0]=""
     delete ttcn3_ids;
     delete ttcn3_cc_id_map;
     fill_ttcn_ids();
     for(i=1;i<ARGC;i++){
       fname=basename(ARGV[i]);
       match(fname,/\.proto/)
       AST["FILES" SUBSEP substr(fname,1,RSTART-1)]=substr(fname,1,RSTART-1);
       processed_file[ARGV[i]]=ARGV[i]
     }
 }


{
#  print " !!! ", $0
  fname=basename(FILENAME)
  match(fname,/\.proto/)
  t_file=substr(fname,1,RSTART-1)
  while($0)    # Get fields by pattern, not by delimiter
  {
    # should be run with gawk < 4.0.0 so FPAT can not be used
    match($0, "((//)|[#]|([/][\\*])|([\\*]/)|[,]|[=]|(\"[^\"]+\")|('[^']+')|[{]|[}]|[<]|[>]|[[]|]|[:]|[(]|[)]|[;]|([[:alnum:]._+-]+))")    # Find a token
    if(RSTART > 0) { # token found
      token = substr($0, RSTART, RLENGTH) # Get the located token
      if(token ~ /(\"[^\"]+\")|('[^']+')/){ # remove qoutes from qouted strings
        token=substr(token,2,RLENGTH-2)
      }
#               printf("$0 before = <%s>\n",$0)
#               printf("token = <%s>\n",token)
#               print "RSTART = ",RSTART, " RLENGTH = " ,RLENGTH;
      if( token ~ "(//)|[#]" ) { # Skip line comments
       next;
      } else if ( token ~ "[/][*].*" ){ # Skip block comment
       comment = 1;
      }  else if (token ~ ".*[*][/].*" ) {  # end of block comment
       comment = 0;
      } else  if (comment == 0) { # process the token
         if(parser_state== "START"){
           if ( token == "import"){
               public_import_flag=0;
               push_state("IMPORT")
           } else if ( token == "package"){
             push_state("PACKAGE");

           } else if ( token == "message"){
             push_state("MESSAGE_NAME");
           } else if ( token == "oneof"){
             push_state("ONEOF_NAME");
           } else if ( token == "enum"){
             push_state("ENUM_NAME");
           } else if (token == "option") {
             push_state("OPTION");
           } else if (token == "service") {
             push_state("SKIP_STRUCT");
             level=0;

           } else if (token == "extend") {
             push_state("SKIP_STRUCT");
             level=0;
           }          
        } else if (parser_state== "SKIP_STRUCT"){
          if(token == "{"){
            level++;
          } else if (token == "}"){
            level--;
            if(level == 0){
              pop_state();
            }
          }
        } else if (parser_state== "ENUM_NAME"){
          if(token == "{"){
            pop_state()
            push_state("ENUM_BODY")
          } else {
            push_scope_stack(token);
            AST[t_file SUBSEP "ENUMS" SUBSEP scope SUBSEP "NAME"] = token;
            AST[t_file SUBSEP "ENUMS" SUBSEP scope SUBSEP "NUM_OF_ENUMERATED"] = 0;
          }
        } else if (parser_state== "ENUM_BODY"){
          if(token == "}"){
            pop_scope_stack();
            pop_state();
          } else if (token == "option") {
             push_state("OPTION");
          } else if (token == "=") {
             push_state("ENUMERATED_VAL");
          } else {
            enumerated_name=token;
          }
        } else if (parser_state== "ENUMERATED_VAL"){
          if(token == ";"){
            pop_state();
          } else if (token == "[") {
             push_state("FIELD_OPTION");
          } else {
            x=AST[t_file SUBSEP "ENUMS" SUBSEP scope SUBSEP "NUM_OF_ENUMERATED"];
            ++x;
            AST[t_file SUBSEP "ENUMS" SUBSEP scope SUBSEP x SUBSEP "NAME"] = enumerated_name;
            AST[t_file SUBSEP "ENUMS" SUBSEP scope SUBSEP x SUBSEP "VAL"] = token;
            AST[t_file SUBSEP "ENUMS" SUBSEP scope SUBSEP "NUM_OF_ENUMERATED"]=x;
          }
        } else if (parser_state== "ONEOF_NAME"){
          if(token == "{"){
            pop_state()
            push_state("ONEOF_BODY")
          } else {
            field_spec="";
            field_name=token;
            field_type="oneof";
            field_num=0;
            field_packed=0;
            store_field();
            push_scope_stack(token);
            AST[t_file SUBSEP "MESSAGES" SUBSEP scope SUBSEP "NAME"] = token;
            AST[t_file SUBSEP "MESSAGES" SUBSEP scope SUBSEP "NUM_OF_FIELDS"] = 0;
            AST[t_file SUBSEP "MESSAGES" SUBSEP scope SUBSEP "ONEOFS"] = 1;
          }
        } else if (parser_state== "ONEOF_BODY"){
          if(token == "}"){
            pop_scope_stack();
            pop_state();
          } else if (token != ";"){
            field_type=token;
            push_state("FIELD_NAME");
          }
          
        } else if (parser_state== "MESSAGE_BODY"){
          if(token == "}"){
            pop_scope_stack();
            pop_state();
          } else if((token == "optional") || (token == "required") || (token == "repeated")){
            field_spec=token;
            field_name="";
            field_type="";
            field_num=0;
            field_packed=0;
            push_state("FIELD_TYPE");
          } else if (token == "message") {
             push_state("MESSAGE_NAME");
          } else if (token == "option") {
             push_state("OPTION");
          } else if ( token == "enum"){
             push_state("ENUM_NAME");
          } else if ( token == "oneof"){
             push_state("ONEOF_NAME");
          } else if (token == "extend")  {
             push_state("SKIP_STRUCT");
             level=0;
          } else if ((token == "extensions")||(token == "reserved"))  {
             push_state("SKIP_FIELD");
          } else if (token != ";"){
            field_spec="optional";
            field_name="";
            field_type=token;
            field_num=0;
            field_packed=0;
            push_state("FIELD_NAME");
          
          }
        } else if ((parser_state== "OPTION")||(parser_state=="SKIP_FIELD")){
          if(token == ";"){
            pop_state();
          }
        } else if (parser_state== "FIELD_TYPE"){
          field_type=token;
          pop_state();
          push_state("FIELD_NAME");
        } else if (parser_state== "FIELD_NAME"){
          field_name=token;
          pop_state();
          push_state("FIELD_NUM");
        } else if (parser_state== "FIELD_NUM"){
          if(token == "="){
          # ignore
          } else if (token == ";"){
            store_field();
            pop_state();
          } else if (token == "["){
            packed_option=0;
            push_state("FIELD_OPTION");
          } else {
            field_num=token;
          }
        } else if (parser_state== "FIELD_OPTION"){
          if(token == "="){
            push_state("FIELD_OPTION_VALUE")
          } else if (token == "]") {
            pop_state()
          } else if ( token == "packed" ) {
            packed_option=1;
          }
        } else if (parser_state== "FIELD_OPTION_VALUE"){
          if(packed_option==1){
           packed_option=0; 
           if(token == "true"){
             field_packed=1;
           }
          }
          pop_state();
        } else if (parser_state== "MESSAGE_NAME"){
          if(token == "{"){
            pop_state()
            push_state("MESSAGE_BODY")
          } else {
            push_scope_stack(token);
            AST[t_file SUBSEP "MESSAGES" SUBSEP scope SUBSEP "NAME"] = token;
            AST[t_file SUBSEP "MESSAGES" SUBSEP scope SUBSEP "NUM_OF_FIELDS"] = 0;
            AST[t_file SUBSEP "MESSAGES" SUBSEP scope SUBSEP "ONEOFS"] = 0;
          }
        } else if (parser_state== "PACKAGE"){
          package_name=token
          gsub(/\./,"_",package_name);
          
          AST["PACKAGE_MAP" SUBSEP package_name] = t_file;
          AST[t_file SUBSEP "PACKAGE"] = package_name;
          pop_state();
           
        } else if (parser_state== "IMPORT"){
           if ( token == "public"){
             public_import_flag=1;
           } else {
             imported_base=basename(token)
             match(imported_base,/\.proto/)
             imported_base=substr(imported_base,1,RSTART-1)
             if( ! (token in processed_files )){
               ARGV[ARGC]=token;
               ARGC++;
               processed_files[token]=token
             }
             
             if ( public_import_flag==1){
               AST[t_file SUBSEP "PUBLIC_IMPORT" SUBSEP imported_base ] = imported_base;
             }
             AST[t_file SUBSEP "IMPORT" SUBSEP imported_base ] = imported_base;
             AST["FILES" SUBSEP imported_base]=imported_base;
             pop_state();
           }
        }
      } # process the token end
      $0 = substr($0, RSTART+RLENGTH )  # Remove processed text from the raw data
#               printf("$0 after = <%s> state = %s\n",$0,parser_state)
    } else {
      next;
    }  # if(RSTART > 0)
  } # while($0)
}


END {
#walk_array(AST,"AST");

# build scope database

delete SCOPE_DB;

  delete files;
  get_array_length(AST,files)
  for(f in files){
    if(f == "FILES"){
      continue
    }
    if(f == "PACKAGE_MAP"){
      continue
    }
    
    if(f SUBSEP "PACKAGE" in AST){
      base_scope=AST[f SUBSEP "PACKAGE"];
      base_scope_sep="@";
    } else {
      base_scope="";
      base_scope_sep="";
    }
    
    delete messages_data;
    get_subarray(AST,f SUBSEP "MESSAGES",messages_data);
    delete messages_list;
    get_array_length(messages_data,messages_list);
    for(m in messages_list){
      act_scope= base_scope base_scope_sep m
      SCOPE_DB[ act_scope SUBSEP "BASE" ] = base_scope;
      SCOPE_DB[ act_scope SUBSEP "FILE" ] = f;
      SCOPE_DB[ act_scope SUBSEP "KIND" ] = "MESSAGE";
      SCOPE_DB[ act_scope SUBSEP "WIRE_TYPE" ] = 2;
    }
    delete messages_data;
    get_subarray(AST,f SUBSEP "ENUMS",messages_data);
    delete messages_list;
    get_array_length(messages_data,messages_list);
    for(m in messages_list){
      act_scope= base_scope base_scope_sep m
      SCOPE_DB[ act_scope SUBSEP "BASE" ] = base_scope;
      SCOPE_DB[ act_scope SUBSEP "FILE" ] = f;
      SCOPE_DB[ act_scope SUBSEP "KIND" ] = "ENUM";
      SCOPE_DB[ act_scope SUBSEP "WIRE_TYPE" ] = 0;
    }
  }

# add base types to scope DB
      SCOPE_DB[ "double" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "double" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "double" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "double" SUBSEP "WIRE_TYPE" ] = 1;
      SCOPE_DB[ "float" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "float" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "float" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "float" SUBSEP "WIRE_TYPE" ] = 5;
      SCOPE_DB[ "int32" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "int32" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "int32" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "int32" SUBSEP "WIRE_TYPE" ] = 0;
      SCOPE_DB[ "int64" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "int64" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "int64" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "int64" SUBSEP "WIRE_TYPE" ] = 0;
      SCOPE_DB[ "uint32" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "uint32" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "uint32" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "uint32" SUBSEP "WIRE_TYPE" ] = 0;
      SCOPE_DB[ "uint64" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "uint64" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "uint64" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "uint64" SUBSEP "WIRE_TYPE" ] = 0;
      SCOPE_DB[ "sint32" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "sint32" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "sint32" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "sint32" SUBSEP "WIRE_TYPE" ] = 0;
      SCOPE_DB[ "sint32" SUBSEP "ZIGZAG" ] = 0;
      SCOPE_DB[ "sint64" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "sint64" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "sint64" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "sint64" SUBSEP "WIRE_TYPE" ] = 0;
      SCOPE_DB[ "sint64" SUBSEP "ZIGZAG" ] = 0;
      SCOPE_DB[ "fixed32" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "fixed32" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "fixed32" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "fixed32" SUBSEP "WIRE_TYPE" ] = 5;
      SCOPE_DB[ "fixed64" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "fixed64" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "fixed64" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "fixed64" SUBSEP "WIRE_TYPE" ] = 1;
      SCOPE_DB[ "sfixed32" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "sfixed32" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "sfixed32" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "sfixed32" SUBSEP "WIRE_TYPE" ] = 5;
      SCOPE_DB[ "sfixed64" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "sfixed64" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "sfixed64" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "sfixed64" SUBSEP "WIRE_TYPE" ] = 1;
      SCOPE_DB[ "bool" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "bool" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "bool" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "bool" SUBSEP "WIRE_TYPE" ] = 0;
      SCOPE_DB[ "string" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "string" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "string" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "string" SUBSEP "WIRE_TYPE" ] = 2;
      SCOPE_DB[ "bytes" SUBSEP "BASE" ] = "";
      SCOPE_DB[ "bytes" SUBSEP "FILE" ] = "ProtoBuff_Types";
      SCOPE_DB[ "bytes" SUBSEP "KIND" ] = "BASE";
      SCOPE_DB[ "bytes" SUBSEP "WIRE_TYPE" ] = 2;

#walk_array(SCOPE_DB,"SCOPE_DB");
  delete files;
  get_array_length(AST,files)
  for(f in files){
#    delete LIST_DB;
    if(f == "FILES"){
      continue
    }
    if(f == "PACKAGE_MAP"){
      continue
    }

    module_name=get_ttcn3_module_name(f);
    ttcn3_file_name=module_name ".ttcn"

    print "// TTCN-3 module generated from " f ".proto" > ttcn3_file_name;
    print "module " module_name " {" >> ttcn3_file_name;
    print "" >> ttcn3_file_name;

    print "// imports" >> ttcn3_file_name;
    print "  import from ProtoBuff_Types all;" >> ttcn3_file_name;
    delete import_list;
    delete already_imported;
    get_subarray(AST, f SUBSEP "IMPORT",import_list);
    for(i in import_list){
      if(i in already_imported){
        continue;
      }
      print "  import from " get_ttcn3_module_name(i) " all;" >> ttcn3_file_name;
      already_imported[i]=i;
    }
    print "" >> ttcn3_file_name;
    print "// public imports" >> ttcn3_file_name;
    for(i in import_list){
      delete public_imports;
      get_subarray(AST, i SUBSEP "PUBLIC_IMPORT",public_imports);
      
      for(pi in public_imports){
        if(pi in already_imported){
          continue;
        }
        already_imported[pi]=pi;
        print "  import from " get_ttcn3_module_name(pi) " all;  // public import from " i ".proto" >> ttcn3_file_name;
        
      }
    }

    print "" >> ttcn3_file_name;
    print "// encoder/decoder function declaration" >> ttcn3_file_name;
    print "" >> ttcn3_file_name;
    delete messages_data;
    delete messages_list;
    get_subarray(AST,f SUBSEP "MESSAGES",messages_data);
    get_array_length(messages_data,messages_list);
    for(m in messages_list){
      if(messages_data[m SUBSEP "ONEOFS"] != 1){
        ttcn3_message_name=conv2ttcn3typeid(m,f);
        print "  external function f_encode_" ttcn3_message_name "(in "ttcn3_message_name" pdu) return octetstring " >> ttcn3_file_name;
        print "  external function f_decode_" ttcn3_message_name "(in octetstring pdu) return "ttcn3_message_name >> ttcn3_file_name;
        print "" >> ttcn3_file_name;
      }
    }
    
    

    print "" >> ttcn3_file_name;
    print "// definitions for enums" >> ttcn3_file_name;
    print "" >> ttcn3_file_name;

    delete enums_data;
    delete enum_name_list;
    
    get_subarray(AST,f SUBSEP "ENUMS",enums_data);
    get_array_length(enums_data,enum_name_list);
    for(e in enum_name_list){
      ttcn3_enum_name=conv2ttcn3typeid(e, f);
      print "  type enumerated " ttcn3_enum_name "{" >> ttcn3_file_name;
      
      num_of_enum_vals=enums_data[e SUBSEP "NUM_OF_ENUMERATED"];
      for(evn=1;evn<=num_of_enum_vals;evn++){
        if(evn<num_of_enum_vals){
          sep=","
        } else {
          sep=""
        }
  
        print "    " conv2ttcn3id(enums_data[e SUBSEP evn SUBSEP "NAME"]) " (" enums_data[e SUBSEP evn SUBSEP "VAL"]")" sep   >> ttcn3_file_name;
        
      }
      
      print "  }" >> ttcn3_file_name;
    }

    print "" >> ttcn3_file_name;
    print "// definitions for messages" >> ttcn3_file_name;
    print "" >> ttcn3_file_name;
    
    
    for(m in messages_list){
      ttcn3_message_name=conv2ttcn3typeid(m,f);
      if(messages_data[m SUBSEP "ONEOFS"] == 1){
        print "  type union " ttcn3_message_name "{ // " m >> ttcn3_file_name;
      }else {
        print "  type record " ttcn3_message_name "{ // " m >> ttcn3_file_name;
      } 
      num_of_fields= messages_data[m SUBSEP "NUM_OF_FIELDS" ];
      for(fn=1;fn<=num_of_fields;fn++){
        if(fn<num_of_fields){
          sep=","
        } else {
          sep=""
        }
        if(messages_data[m SUBSEP fn SUBSEP "FIELD_SPEC"] == "optional"){
          opt= " optional"
        } else {
          opt=""
        }
        f_type_name=get_scoped_id(messages_data[m SUBSEP fn SUBSEP "FIELD_TYPE"],m,f);
#print "f_type_name "f_type_name
        if(f_type_name == "oneof"){
         f_type_name = ttcn3_message_name "_" conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]);
        }
        if(messages_data[m SUBSEP fn SUBSEP "FIELD_SPEC"] == "repeated"){
          rep= "record of "
#          LIST_DB[f_type_name]=f_type_name;
        } else {
          rep=""
        }
        
        print "    " rep f_type_name  "   " conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]) opt sep >> ttcn3_file_name;
        
      }
      
      print "  }" >> ttcn3_file_name;
      
      
    }

#    print "// type definitions for repeated fields" >> ttcn3_file_name;
    
#    for(t in LIST_DB){
#      print "  type record of " t " " t "_list;" >> ttcn3_file_name;
      
#    }
    print "" >> ttcn3_file_name;
    print "}" >> ttcn3_file_name;

    cc_file_name=module_name "_EncDec.cc"
    hh_file_name=module_name "_EncDec.hh"

    print "// Encode/decoder functions for types in " f".proto" > hh_file_name
    print "// Encode/decoder functions for types in " f".proto" > cc_file_name

    print "" >> hh_file_name
    print "#include \"ProtoBuff_Base.hh\"">> hh_file_name
    print "#include \"" module_name ".hh\"">> hh_file_name
    print "" >> hh_file_name

    print "" >> cc_file_name
    print "#include \""hh_file_name"\"">> cc_file_name
    print "" >> cc_file_name
        
    for(e in enum_name_list){
      ttcn3_enum_name=conv2ttcn3typeid(e, f);
      print "  size_t encode_"  cc_name(ttcn3_enum_name) "(TTCN_Buffer& buff, const " cc_name(module_name)"::"cc_name(ttcn3_enum_name)"&val);" >> hh_file_name
      print "  size_t decode_" cc_name(ttcn3_enum_name) "(TTCN_Buffer& buff, "cc_name(module_name)"::"cc_name(ttcn3_enum_name)"&val,size_t max_length);" >> hh_file_name
      print "" >> hh_file_name

      print "  size_t encode_"  cc_name(ttcn3_enum_name) "(TTCN_Buffer& buff, const " cc_name(module_name)"::"cc_name(ttcn3_enum_name)"&val){" >> cc_file_name
      print "    long long int iv=(int)val;" >> cc_file_name
      print "    return encode_varint(buff,iv,false);" >> cc_file_name
      print "  }" >> cc_file_name
      print "" >> cc_file_name
      
      print "  size_t decode_" cc_name(ttcn3_enum_name) "(TTCN_Buffer& buff, "cc_name(module_name)"::"cc_name(ttcn3_enum_name)"&val,size_t max_length){" >> cc_file_name
      print "    long long int iv;" >> cc_file_name
      print "    size_t decoded_size=decode_varint(buff,iv,false);" >> cc_file_name
      print "    val=iv;" >> cc_file_name
      print "    return decoded_size;" >> cc_file_name
      print "  }" >> cc_file_name
      print "" >> cc_file_name


    } # enum

    for(m in messages_list){
      ttcn3_message_name=conv2ttcn3typeid(m,f);
      num_of_fields= messages_data[m SUBSEP "NUM_OF_FIELDS" ];
      isoneof = messages_data[m SUBSEP "ONEOFS"];
      print "  size_t encode_"  cc_name(ttcn3_message_name) "(TTCN_Buffer& buff, const " cc_name(module_name)"::"cc_name(ttcn3_message_name)"&val);" >> hh_file_name
      if(isoneof==1)
      {
        print "  size_t decode_" cc_name(ttcn3_message_name) "(TTCN_Buffer& buff, "cc_name(module_name)"::"cc_name(ttcn3_message_name)"&val,size_t max_length,int ft);" >> hh_file_name
      }else{
        print "  size_t decode_" cc_name(ttcn3_message_name) "(TTCN_Buffer& buff, "cc_name(module_name)"::"cc_name(ttcn3_message_name)"&val,size_t max_length);" >> hh_file_name
      }
      print "" >> hh_file_name

      if(isoneof != 1)
      {
        print "OCTETSTRING "cc_name(module_name)"::f__encode__"cc_name(ttcn3_message_name)"(const "cc_name(module_name)"::"cc_name(ttcn3_message_name)"& pdu){" >> cc_file_name
        print "  TTCN_Buffer buff;" >> cc_file_name
        print "  encode_"  cc_name(ttcn3_message_name) "(buff,pdu);" >> cc_file_name
        print "  OCTETSTRING ret_val;" >> cc_file_name
        print "  buff.get_string(ret_val);" >> cc_file_name
        print "  return ret_val;" >> cc_file_name
        print "}" >> cc_file_name
        print "" >> cc_file_name

        print cc_name(module_name)"::"cc_name(ttcn3_message_name)" "cc_name(module_name)"::f__decode__"cc_name(ttcn3_message_name)"(const OCTETSTRING& pdu){" >> cc_file_name
        print "  "cc_name(module_name)"::"cc_name(ttcn3_message_name)" ret_val;" >> cc_file_name
        print "  TTCN_Buffer buff(pdu);" >> cc_file_name
        print "  decode_"  cc_name(ttcn3_message_name) "(buff,ret_val,buff.get_len());" >> cc_file_name
        print "  return ret_val;" >> cc_file_name
        print "}" >> cc_file_name
        print "" >> cc_file_name
      }

      print "  size_t encode_"  cc_name(ttcn3_message_name) "(TTCN_Buffer& buff, const " cc_name(module_name)"::"cc_name(ttcn3_message_name)"&val){" >> cc_file_name
      print "    size_t ret_val=0;" >> cc_file_name
      for(fn=1;fn<=num_of_fields;fn++){
        if(messages_data[m SUBSEP fn SUBSEP "FIELD_SPEC"] == "optional"){
          opt= "()"
          print "    if(val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"().is_present()) {" >> cc_file_name
        } else if(isoneof == 1){
          opt=""
          iftype="if";
          if (fn>1){iftype="else if"}
          print "    "iftype"(val.get_selection() == "cc_name(module_name)"::"cc_name(ttcn3_message_name)"::ALT_"cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))") {" >> cc_file_name
       }else {
          opt=""
          print "    {" >> cc_file_name
        }
        f_type_name=get_scoped_id(messages_data[m SUBSEP fn SUBSEP "FIELD_TYPE"],m,f);
        f_scopped_type_name=get_scoped_scope_id(messages_data[m SUBSEP fn SUBSEP "FIELD_TYPE"],m,f);
        wire_type=SCOPE_DB[ f_scopped_type_name SUBSEP "WIRE_TYPE" ];
#print "f_type_name " f_type_name " wire type " wire_type
        
        if(messages_data[m SUBSEP fn SUBSEP "FIELD_SPEC"] == "repeated"){
          if(messages_data[m SUBSEP fn SUBSEP "FIELD_PACKED"] == 1 ){
            print "      TTCN_Buffer buff2;" >> cc_file_name
            print "      size_t field_len=0;" >> cc_file_name
            print "      for(int i=0;i<val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"().size_of();i++){" >> cc_file_name
            print "        field_len+=encode_"cc_name(f_type_name)"(buff,val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"()[i]);" >> cc_file_name
            print "      }" >> cc_file_name
            print "      ret_val+=encode_tag_length(buff,"messages_data[m SUBSEP fn SUBSEP "FIELD_NUM"]",2,field_len);" >> cc_file_name
            print "      buff.put_buf(buff2);" >> cc_file_name
            print "      ret_val+=field_len;" >> cc_file_name
          } else {
            print "      for(int i=0;i<val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"().size_of();i++){" >> cc_file_name
            if(wire_type==2){  # length delimited
              print "        TTCN_Buffer buff2;" >> cc_file_name
              print "        size_t field_len=encode_"cc_name(f_type_name)"(buff2,val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"()[i]);" >> cc_file_name
              print "        ret_val+=encode_tag_length(buff,"messages_data[m SUBSEP fn SUBSEP "FIELD_NUM"]",2,field_len);" >> cc_file_name
              print "        buff.put_buf(buff2);" >> cc_file_name
              print "        ret_val+=field_len;" >> cc_file_name
            } else {
              print "        ret_val+=encode_tag_length(buff,"messages_data[m SUBSEP fn SUBSEP "FIELD_NUM"]","wire_type");" >> cc_file_name
              print "        ret_val+=encode_"cc_name(f_type_name)"(buff,val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"()[i]);" >> cc_file_name

            }
            print "      }" >> cc_file_name
          }
        
        } else if(wire_type==2){  # length delimited
          print "      TTCN_Buffer buff2;" >> cc_file_name
          print "      size_t field_len=encode_"cc_name(f_type_name)"(buff2,val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"()"opt");" >> cc_file_name
          print "      ret_val+=encode_tag_length(buff,"messages_data[m SUBSEP fn SUBSEP "FIELD_NUM"]",2,field_len);" >> cc_file_name
          print "      buff.put_buf(buff2);" >> cc_file_name
          print "      ret_val+=field_len;" >> cc_file_name
        } else if (f_type_name == "oneof"){
          f_type_name = ttcn3_message_name "_" conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]);
          print "      ret_val+=encode_"cc_name(f_type_name)"(buff,val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"()"opt");" >> cc_file_name
        } else {
          print "      ret_val+=encode_tag_length(buff,"messages_data[m SUBSEP fn SUBSEP "FIELD_NUM"]","wire_type");" >> cc_file_name
          print "      ret_val+=encode_"cc_name(f_type_name)"(buff,val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"()"opt");" >> cc_file_name
        
        }
        print "    }" >> cc_file_name
      }
      print "    return ret_val;" >> cc_file_name
      print "  }" >> cc_file_name
      print "" >> cc_file_name
      if(isoneof == 1){
        print "  size_t decode_" cc_name(ttcn3_message_name) "(TTCN_Buffer& buff, "cc_name(module_name)"::"cc_name(ttcn3_message_name)"&val,size_t max_length,int ft){" >> cc_file_name
        print "  size_t fl=max_length;" >> cc_file_name
      }else{
        print "  size_t decode_" cc_name(ttcn3_message_name) "(TTCN_Buffer& buff, "cc_name(module_name)"::"cc_name(ttcn3_message_name)"&val,size_t max_length){" >> cc_file_name
      }
      print "    size_t ret_val=0;" >> cc_file_name
      for(fn=1;fn<=num_of_fields;fn++){
        if(messages_data[m SUBSEP fn SUBSEP "FIELD_SPEC"] == "optional"){  # set optional field omit if unbound
          print "    if(!val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"().is_bound()) val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"()=OMIT_VALUE;" >> cc_file_name
        }
        else if(messages_data[m SUBSEP fn SUBSEP "FIELD_SPEC"] == "repeated"){  # set repeated field {} if unbound
          print "    if(!val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"().is_bound()) val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"()=NULL_VALUE;" >> cc_file_name
        }
      }
      if(isoneof != 1){
        print "    while(ret_val<max_length){" >> cc_file_name
        print "      char wt=0;" >> cc_file_name
        print "      size_t fl=0;" >> cc_file_name
        print "      int ft=0;" >> cc_file_name
        print "      ret_val+=decode_tag_length(buff,ft,wt,fl);" >> cc_file_name
      }
      print "      switch(ft){" >> cc_file_name
      oneofdata = "";
      for(fn=1;fn<=num_of_fields;fn++){
       f_type_name=get_scoped_id(messages_data[m SUBSEP fn SUBSEP "FIELD_TYPE"],m,f);
        if (f_type_name != "oneof"){
          print "        case "messages_data[m SUBSEP fn SUBSEP "FIELD_NUM"]": {" >> cc_file_name
         }
        if(messages_data[m SUBSEP fn SUBSEP "FIELD_SPEC"] == "optional"){
          opt= "()"
        } else {
          opt=""
        }
         f_scopped_type_name=get_scoped_scope_id(messages_data[m SUBSEP fn SUBSEP "FIELD_TYPE"],m,f);
        wire_type=SCOPE_DB[ f_scopped_type_name SUBSEP "WIRE_TYPE" ];
        
        if(messages_data[m SUBSEP fn SUBSEP "FIELD_SPEC"] == "repeated"){
          if(messages_data[m SUBSEP fn SUBSEP "FIELD_PACKED"] == 1 ){
            print "            while(fl){" >> cc_file_name
            print "              size_t sfl=decode_"cc_name(f_type_name)"(buff,val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"()[val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"().size_of()],fl);" >> cc_file_name
            print "              fl-=sfl;" >> cc_file_name
            print "              ret_val+=sfl;" >> cc_file_name
            print "            }" >> cc_file_name
          } else {
            print "            ret_val+=decode_"cc_name(f_type_name)"(buff,val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"()[val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"().size_of()],fl);" >> cc_file_name
          }
        
        }else if (f_type_name == "oneof"){
          f_type_name = ttcn3_message_name "_" conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]);
           oneofdata = oneofdata "\n            ret_val2+=decode_"cc_name(f_type_name)"(buff,val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"()"opt",fl,ft);";
          f_type_name = "oneof";
        } else {
          print "            ret_val+=decode_"cc_name(f_type_name)"(buff,val."cc_name(conv2ttcn3id(messages_data[m SUBSEP fn SUBSEP "FIELD_NAME"]))"()"opt",fl);" >> cc_file_name
        }
        if (f_type_name != "oneof"){
          print "            " >> cc_file_name
          print "          }" >> cc_file_name
          print "          break;" >> cc_file_name
        }
      }
      print "        default:" >> cc_file_name
      if(oneofdata!=""){
        print "            size_t ret_val2=0;" >> cc_file_name
        print oneofdata >> cc_file_name
        print "            ret_val+=ret_val2;" >> cc_file_name
        print "            if(ret_val2==0){" >> cc_file_name
        print "              ret_val+=decodeunknown(buff,wt,fl);" >> cc_file_name
        print "            }" >> cc_file_name
      }
      else if(isoneof != 1){
        print "          ret_val+=decodeunknown(buff,wt,fl);" >> cc_file_name
      }
      print "          break;" >> cc_file_name
      print "      }" >> cc_file_name
      if(isoneof != 1){
        print "    }" >> cc_file_name
      }  
      print "    return ret_val;" >> cc_file_name
      print "  }" >> cc_file_name

      print "" >> cc_file_name

        
        
        
              
    } # message

  }

}

