/*
 *   Copyright (C) 2019 by Saverio Giallorenzo <saverio.giallorenzo@gmail.com>
 *                                                                            
 *   This program is free software; you can redistribute it and/or modify     
 *   it under the terms of the GNU Library General Public License as          
 *   published by the Free Software Foundation; either version 2 of the       
 *   License, or (at your option) any later version.                          
 *                                                                            
 *   This program is distributed in the hope that it will be useful,          
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of           
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
 *   GNU General Public License for more details.                             
 *                                                                            
 *   You should have received a copy of the GNU Library General Public        
 *   License along with this program; if not, write to the                    
 *   Free Software Foundation, Inc.,                                          
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.                
 *                                                                            
 *   For details about the authors of this software, see the AUTHORS file.    
 */

include "console.iol"
include "string_utils.iol"
include "json_utils.iol"
include "file.iol"
include "runtime.iol"
include "inspector.iol"
include "include/liquid.iol"

inputPort MyPort {
  Location: "socket://localhost:8000"
  Protocol: sodep
  Interfaces: MyInterface
}

define printHelp
{
  println@Console( 
    "\n=================== JOLIE DOC =================\n\n" +
    "Command: jolie joliedoc.ol \"output extension\" \"output template\" input/file.[i]ol [\"output/folder\"]"
    + "\n" +
    "Example usage: jolie joliedoc.ol \".md\" \"markdown_joliedoc.liquid\" input/file.[i]ol [\"output/folder\"]"
    + "\n" + 
    "output/folder is optional, using workingDirectory/joliedoc path when omitted." 
    + "\n" +
    "Option --help prints this message."
    + "\n\n==================================================================\n" )()
  }

  main
  {
    install( default => 
      if( !main.HelpArgument ){
        printHelp;
        valueToPrettyString@StringUtils( main )( t ); 
        println@Console( t )()
      });
    for ( i=0, i<#args, nullProcess ) {
      if( args[i] == "--includeOutputPorts" ){
        includeOutputPorts = true;
        undef( args[i] )
      } else { i++ };
      if( args[i] == "--help" ){
        printHelp; throw( HelpArgument, true )
      }
    };
    format = args[0];
    template = args[1];
    inputFile = args[2];

    getFileSeparator@File()( sep );
    if( is_defined( args[3] ) ){ 
      outputFolder = args[3]
    } else { 
      getServiceDirectory@File()( serviceDirectory );
      outputFolder = serviceDirectory + sep + "joliedoc"
    };
    if( !is_defined( format ) ){ throw( IllegalArgumentFault, "output extension not specified" ) };
    if( !is_defined( template ) ){ throw( IllegalArgumentFault, "template file not specified" ) };
    if( !is_defined( inputFile ) ){ throw( IllegalArgumentFault, "input file not specified" ) };
    toAbsolutePath@File( template )( template );
    println@Console( "- loading template " + template )();
    readFile@File( { .filename = template } )( renderRequest.template );

    getenv@Runtime( "JOLIE_HOME" )( JOLIE_HOME );
    if ( !is_defined( JOLIE_HOME ) ){ throw( IOException, "Could not find Jolie install home, JOLIE_HOME undefined." ) };
    // with( docRequest ){
    //   .includes = JOLIE_HOME + sep + "include";
    //   .libraries[#.libraries] = JOLIE_HOME + sep + "lib";
    //   .libraries[#.libraries] = JOLIE_HOME + sep + "javaServices/*";
    //   .libraries[#.libraries] = JOLIE_HOME + sep + "extensions/*"
    // };
    deleteDir@File( outputFolder )();
    mkdir@File( outputFolder )();
    println@Console( "- created folder '" + outputFolder + "' to store the created documentation" )();
    toAbsolutePath@File( inputFile )( docRequest.file );
    println@Console( "- building the Jolie Documentation for file " + docRequest.file )();
    scope( a ){
      install( default => valueToPrettyString@StringUtils( a )( t ); println@Console( t )() );
      inspectProgram@Inspector( docRequest )( data.result )
    };
    if( #data.result.port > 0 ){
      println@Console( "Found " + #data.result.port + " ports" )();
      if( !includeOutputPorts ){
        for ( i=0, i<#data.result.port, nullProcess ) {
          if( data.result.port[i].isOutput  ){
            println@Console( "Removing port " + data.result.port[i].name )();
            undef( data.result.port[i] )
          } else { i++ }
        }
      };
      if ( dir != docRequest.includes ){ data.result.filename = dir + sep + data.result.filename };
    // valueToPrettyString@StringUtils( data )( s ); println@Console( s )();
      getJsonString@JsonUtils( data )( renderRequest.data );
    // println@Console( renderRequest.data )();
      renderRequest.format = "json";
      scope( a ){
        install( default => valueToPrettyString@StringUtils( a )( t ); println@Console( t )() );
        renderDocument@Liquid( renderRequest )( writeFile.content )
      };
      replaceAll@StringUtils( inputFile { .regex = "\\.i?ol", .replacement = "" } )( filename );
      writeFile.filename = outputFolder + sep + filename + format;
      writeFile@File( writeFile )()
    } else {
      println@Console( "    - skipped rendering of file '" + filename + "' since it has no ports to document" )()
    };
    println@Console( "Done" )()
  }